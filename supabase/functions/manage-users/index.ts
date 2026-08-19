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

    // 1. Authenticate the requester (must be an admin)
    const { data: { user: requester }, error: authError } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))
    if (authError || !requester || requester.app_metadata?.role !== 'admin') {
      throw new Error('Unauthorized: Admin access required')
    }

    const body = await req.json()
    const { action, email, password, role, schemaName, userId } = body

    if (action === 'list') {
      // List users by joining auth.users with public.users_tenants_mapping
      // Note: We need a clever way to do this since we can't easily join across schemas in a single JS call
      // Best way is to fetch all from mapping and then fetch specific users from auth
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

      const { data: { users }, error: listError } = await supabaseAdmin.auth.admin.listUsers()
      if (listError) throw listError

      const enrichedUsers = mappings.map(m => {
        const authUser = users.find(u => u.id === m.user_id)
        return {
          id: m.user_id,
          email: authUser?.email,
          role: m.role,
          tenantName: m.tenant.name,
          tenantSchema: m.tenant.schema_name
        }
      })

      return new Response(JSON.stringify(enrichedUsers), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    if (action === 'create') {
      if (!email || !password || !role || !schemaName) throw new Error('Missing parameters')

      // 1. Create user in Auth
      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        app_metadata: { role, schema_name: schemaName }
      })
      if (createError) throw createError

      // 2. Add to mapping table
      const { data: tenant } = await supabaseAdmin
        .from('tenants')
        .select('id')
        .eq('schema_name', schemaName)
        .single()

      if (!tenant) throw new Error('Tenant not found')

      const { error: linkError } = await supabaseAdmin
        .from('users_tenants_mapping')
        .insert({
          user_id: newUser.user.id,
          tenant_id: tenant.id,
          role: role
        })

      if (linkError) throw linkError

      return new Response(JSON.stringify({ success: true, user: newUser.user }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    if (action === 'delete') {
      if (!userId) throw new Error('Missing userId')

      // Delete from auth (will cascade or we handle manually)
      const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)
      if (deleteError) throw deleteError

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    throw new Error('Invalid Action')

  } catch (error) {
    console.error('User Management Error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
