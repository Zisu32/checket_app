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

    // PAYLOAD VERARBEITUNG
    const { slotId, secret } = await req.json()
    console.log(`Slot ID: ${slotId}`)

    if (!slotId) {
      return new Response(
        JSON.stringify({ error: 'slotId fehlt in der Anfrage.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // DATENBANK-CHECK
    const sid = Number(slotId)
    let query = supabase
      .from('checket_garderobe')
      .select('id, status, secret')
      .eq('id', sid)

    if (secret) {
      query = query.eq('secret', secret)
    }

    const { data: slot, error: slotError } = await query.single()

    if (slotError || !slot) {
      console.error(`Database Query Error for Slot ${sid}:`, slotError?.message)
      return new Response(
        JSON.stringify({ error: 'Garderoben-Platz ungültig oder nicht gefunden.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (slot.status === 'active') {
      console.log(`Checkout abgebrochen: Slot ${sid} ist bereits 'active'.`)
      return new Response(
        JSON.stringify({ 
          error: 'Dieser Garderoben-Platz ist bereits aktiv und bezahlt.',
          status: slot.status 
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // SUMUP CLOUD API TRIGGER
    const API_KEY = Deno.env.get('SUMUP_API_KEY')
    const MERCHANT_CODE = Deno.env.get('SUMUP_MERCHANT_CODE')
    const AFFILIATE_KEY = Deno.env.get('SUMUP_AFFILIATE_KEY')

    if (!API_KEY || !MERCHANT_CODE || !AFFILIATE_KEY) {
      console.error('SumUp secrets are missing.')
      return new Response(
        JSON.stringify({ error: 'SumUp Konfiguration fehlt in den Supabase Secrets.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    try {
      const checkoutResponse = await fetch(`https://api.sumup.com/v0.1/merchants/${MERCHANT_CODE}/readers/checkouts`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount: 1.00, // Standard wardrobe price
          currency: 'EUR',
          foreign_tx_id: `hook_${slotId}_${Date.now()}`,
          affiliate_key: AFFILIATE_KEY,
        }),
      })

      const rawBody = await checkoutResponse.text()
      console.log(`SumUp Raw Response (Status ${checkoutResponse.status}):`, rawBody)

      let checkoutData;
      try {
        checkoutData = JSON.parse(rawBody)
      } catch (e) {
        console.error('Failed to parse SumUp JSON response:', e)
      }

      if (checkoutResponse.status !== 201) {
        // Extract specific error details from SumUp
        const errorMsg = checkoutData?.detail ||
                         checkoutData?.message ||
                         checkoutData?.error?.message ||
                         checkoutData?.error_code ||
                         'SumUp Terminal konnte nicht aktiviert werden.';

        console.error('SumUp API Error:', errorMsg)

        return new Response(
          JSON.stringify({
            error: errorMsg,
            raw: checkoutData
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({ success: true, checkout: checkoutData }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } catch (fetchError) {
      console.error('Fetch to SumUp failed:', fetchError)
      return new Response(
        JSON.stringify({ error: `Verbindung zu SumUp fehlgeschlagen: ${fetchError.message}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    console.error('Internal Function Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
