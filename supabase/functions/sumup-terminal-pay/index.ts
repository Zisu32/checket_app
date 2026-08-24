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
    // 1. Initialize Admin Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAdmin = createClient(supabaseUrl, getSecretKey())

    // 2. Identify the User and their Schema
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))
    if (authError || !user) throw new Error('Unauthorized')

    const schemaName = user.app_metadata?.schema_name
    if (!schemaName) throw new Error('No tenant schema assigned to this user.')

    // 3. Set Context (Search Path) for this session
    const supabase = createClient(supabaseUrl, getSecretKey(), {
      db: { schema: schemaName }
    })

    // 4. PAYLOAD
    const body = await req.json()
    const { action = 'pay', slotId, readerId, stationName, readerName, checkoutId } = body

    // 5. FETCH TENANT SECRETS FROM VAULT
    const fetchSecret = async (name: string) => {
      const { data, error } = await supabaseAdmin.rpc('get_decrypted_tenant_secret', {
        p_schema: schemaName,
        p_key_name: name
      })
      if (error || !data || data.length === 0) return null
      return data[0].decrypted_value
    }

    const API_KEY = await fetchSecret('SUMUP_API_KEY')
    const MERCHANT_CODE = await fetchSecret('SUMUP_MERCHANT_CODE')
    const AFFILIATE_KEY = await fetchSecret('SUMUP_AFFILIATE_KEY')

    if (!API_KEY || !MERCHANT_CODE || !AFFILIATE_KEY) {
      throw new Error(`SumUp configuration missing for tenant ${schemaName}.`)
    }

    // --- ACTION: LIST STATUS ---
    if (action === 'list-status') {
      const readersRes = await fetch(`https://api.sumup.com/v0.1/merchants/${MERCHANT_CODE}/readers`, {
        headers: { 'Authorization': `Bearer ${API_KEY}` }
      })
      const readersData = await readersRes.json()
      const readers = readersData.items || []

      const { data: assignments } = await supabase
        .from('checket_terminal_assignments')
        .select('*')

      return new Response(JSON.stringify({ readers, assignments: assignments || [] }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // --- ACTION: CHECK PAYMENT STATUS ---
    if (action === 'check-status') {
      if (!checkoutId) throw new Error('checkoutId missing.')
      const statusRes = await fetch(`https://api.sumup.com/v0.1/checkouts/${checkoutId}`, {
        headers: { 'Authorization': `Bearer ${API_KEY}` }
      })
      const statusData = await statusRes.json()
      return new Response(JSON.stringify({ status: statusData.status }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // --- ACTION: ASSIGN ---
    if (action === 'assign') {
      const { error } = await supabase
        .from('checket_terminal_assignments')
        .upsert({ reader_id: readerId, station_name: stationName, reader_name: readerName, updated_at: new Date().toISOString() })
      if (error) throw error
      return new Response(JSON.stringify({ success: true }), { headers: corsHeaders })
    }

    // --- ACTION: REMOVE ---
    if (action === 'remove') {
      const { error } = await supabase.from('checket_terminal_assignments').delete().eq('reader_id', readerId)
      if (error) throw error
      return new Response(JSON.stringify({ success: true }), { headers: corsHeaders })
    }

    // --- ACTION: PAY ---
    if (action === 'pay') {
      const { slotIds = [], slotCount = 1 } = body

      // Fetch global price (from any terminal assignment since they are now global)
      const { data: assignment } = await supabase
        .from('checket_terminal_assignments')
        .select('ticket_price')
        .limit(1)
        .maybeSingle()

      const basePrice = assignment?.ticket_price || 2.50
      const totalAmount = basePrice * slotCount
      const priceInCent = Math.round(totalAmount * 100)

      const checkoutResponse = await fetch(`https://api.sumup.com/v0.1/merchants/${MERCHANT_CODE}/readers/${readerId}/checkout`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          total_amount: { currency: 'EUR', minor_unit: 2, value: priceInCent },
          foreign_tx_id: `hook_group_${Date.now()}`,
          affiliate_key: AFFILIATE_KEY,
        }),
      })

      const checkoutData = await checkoutResponse.json()
      if (checkoutResponse.status !== 201) throw new Error(checkoutData?.detail || 'SumUp Error.')

      return new Response(JSON.stringify({ success: true, checkoutId: checkoutData.id }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    throw new Error('Invalid Action.')

  } catch (error) {
    console.error('Multi-Tenant Error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
