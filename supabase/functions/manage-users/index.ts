import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// STANDARD KEY HELPERS (Strict Multi-Tenant Standard)
function getSecretKey(): string {
  const envKeys = Deno.env.get('SUPABASE_SECRET_KEYS');
  if (envKeys) {
    try {
      return JSON.parse(envKeys)?.default || envKeys;
    } catch {
      return envKeys;
    }
  }
  return Deno.env.get('SUPABASE_SECRET_KEY') ?? '';
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return new Response(JSON.stringify({ error: 'Missing Auth Header' }), { status: 401 })

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAdmin = createClient(supabaseUrl, getSecretKey())

    // 1. Authenticate the requester
    const { data: { user: requester }, error: authError } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))
    if (authError || !requester) throw new Error('Unauthorized')

    // 2. Check if admin (either via app_metadata or mapping table)
    const isGlobalAdmin = requester.app_metadata?.role === 'admin'

    const { data: mapping } = await supabaseAdmin
      .from('users_tenants_mapping')
      .select('role')
      .eq('user_id', requester.id)
      .eq('role', 'admin')
      .maybeSingle()

    if (!isGlobalAdmin && !mapping) {
      throw new Error('Unauthorized: Admin access required')
    }

    const body = await req.json()
    const { action, email, password, role, schemaName, userId } = body

    if (action === 'list') {
      const { data: { users }, error: listError } = await supabaseAdmin.auth.admin.listUsers()
      if (listError) throw listError

      const { data: mappings, error: mapError } = await supabaseAdmin
        .from('users_tenants_mapping')
        .select(`
          user_id,
          role,
          tenant:tenant_id (
            name,
            schema_name
          )
        `)

      if (mapError) throw mapError

      const enrichedUsers = users.map(authUser => {
        const mapping = mappings.find(m => m.user_id === authUser.id)
        return {
          id: authUser.id,
          email: authUser.email,
          role: mapping?.role || authUser.app_metadata?.role || 'staff',
          tenantName: mapping?.tenant?.name || 'Keine Zuweisung',
          tenantSchema: mapping?.tenant?.schema_name || authUser.app_metadata?.schema_name
        }
      })

      return new Response(JSON.stringify(enrichedUsers), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    if (action === 'create') {
      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        app_metadata: { role, schema_name: schemaName }
      })
      if (createError) throw createError

      const { data: tenant } = await supabaseAdmin.from('tenants').select('id').eq('schema_name', schemaName).single()
      if (!tenant) throw new Error('Tenant not found')

      await supabaseAdmin.from('users_tenants_mapping').insert({
        user_id: newUser.user.id,
        tenant_id: tenant.id,
        role: role
      })

      return new Response(JSON.stringify({ success: true }), { headers: corsHeaders })
    }

    if (action === 'delete') {
      await supabaseAdmin.auth.admin.deleteUser(userId)
      return new Response(JSON.stringify({ success: true }), { headers: corsHeaders })
    }

    throw new Error('Invalid Action')

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
