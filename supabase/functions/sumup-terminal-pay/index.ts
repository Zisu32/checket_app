import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// SECRET HANDLING
function getSecretKey(): string {
  const envSecretKeys = Deno.env.get('SUPABASE_SECRET_KEYS');
  if (envSecretKeys) {
    try {
      const parsed = JSON.parse(envSecretKeys);
      if (parsed?.default) return parsed.default;
    } catch {
      return envSecretKeys;
    }
  }
  const singleSecretKey = Deno.env.get('SUPABASE_SECRET_KEY');
  if (singleSecretKey) return singleSecretKey;

  throw new Error('Kein gültiger Supabase Secret Key gefunden!');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    // SUPABASE CLIENT
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    if (!supabaseUrl) throw new Error('SUPABASE_URL missing.')
    
    const supabase = createClient(supabaseUrl, getSecretKey(), {
      auth: { autoRefreshToken: false, persistSession: false }
    })

    // PAYLOAD
    const body = await req.json()
    const { action = 'pay', slotId, secret, readerId, stationName, readerName, checkoutId } = body

    // SUMUP CREDENTIALS
    const API_KEY = Deno.env.get('SUMUP_API_KEY')
    const MERCHANT_CODE = Deno.env.get('SUMUP_MERCHANT_CODE')
    const AFFILIATE_KEY = Deno.env.get('SUMUP_AFFILIATE_KEY')

    if (!API_KEY || !MERCHANT_CODE || !AFFILIATE_KEY) {
      throw new Error('SumUp Konfiguration fehlt.')
    }

    // LIST STATUS OF READERS
    if (action === 'list-status') {
      const readersRes = await fetch(`https://api.sumup.com/v0.1/merchants/${MERCHANT_CODE}/readers`, {
        headers: { 'Authorization': `Bearer ${API_KEY}` }
      })
      const readersData = await readersRes.json()
      const readers = readersData.items || readersData.readers || []

      const { data: assignments } = await supabase
        .from('checket_terminal_assignments')
        .select('*')

      return new Response(JSON.stringify({ readers, assignments: assignments || [] }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // CHECK PAYMENT STATUS
    if (action === 'check-status') {
      if (!checkoutId) throw new Error('checkoutId fehlt.')

      const statusRes = await fetch(`https://api.sumup.com/v0.1/checkouts/${checkoutId}`, {
        headers: { 'Authorization': `Bearer ${API_KEY}` }
      })

      const statusData = await statusRes.json()
      console.log(`Checkout Status for ${checkoutId}: ${statusData.status}`)

      return new Response(JSON.stringify({ status: statusData.status }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // ASSIGN READERS
    if (action === 'assign') {
      if (!readerId || !stationName || !readerName) throw new Error('Daten fehlen.')
      console.log(`Assigning reader ${readerId} to station ${stationName}...`)

      const { data, error } = await supabase
        .from('checket_terminal_assignments')
        .upsert({
          reader_id: readerId,
          station_name: stationName,
          reader_name: readerName,
          updated_at: new Date().toISOString()
        })
        .select()

      if (error) {
        console.error('Database assignment error:', error.message)
        throw error
      }

      console.log('Assignment successful:', JSON.stringify(data))
      return new Response(JSON.stringify({ success: true }), { headers: corsHeaders })
    }

    // REMOVE READERS
    if (action === 'remove') {
      if (!readerId) throw new Error('readerId fehlt.')
      const { error } = await supabase
        .from('checket_terminal_assignments')
        .delete()
        .eq('reader_id', readerId)

      if (error) throw error
      return new Response(JSON.stringify({ success: true }), { headers: corsHeaders })
    }

    // PAY
    if (action === 'pay') {
      // Validation
      const sid = Number(slotId)
      const { data: slot } = await supabase.from('checket_garderobe').select('status').eq('id', sid).single()
      if (slot?.status === 'active') throw new Error('Bereits bezahlt.')

      // Target Reader
      let targetReaderId = readerId
      if (!targetReaderId) throw new Error('Kein Terminal gefunden.')

      const checkoutResponse = await fetch(`https://api.sumup.com/v0.1/merchants/${MERCHANT_CODE}/readers/${targetReaderId}/checkout`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          total_amount: {
            currency: 'EUR',
            minor_unit: 2,
            value: 100 // 1.00 EUR
          },
          foreign_tx_id: `hook_${slotId}_${Date.now()}`,
          affiliate_key: AFFILIATE_KEY,
        }),
      })

      const checkoutData = await checkoutResponse.json()
      if (checkoutResponse.status !== 201) {
        throw new Error(checkoutData?.detail || checkoutData?.message || 'Terminal konnte nicht aktiviert werden.')
      }

      return new Response(JSON.stringify({
        success: true,
        checkoutId: checkoutData.id // Return the SumUp Checkout ID for polling
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    throw new Error('Ungültige Action.')

  } catch (error) {
    console.error('SumUp Function Error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
