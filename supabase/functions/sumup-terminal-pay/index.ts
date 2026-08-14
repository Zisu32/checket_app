const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS Preflight
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { slotId, secret } = await req.json()

    // 1. Get Static Credentials from Supabase Secrets
    const API_KEY = Deno.env.get('SUMUP_API_KEY')
    const MERCHANT_CODE = Deno.env.get('SUMUP_MERCHANT_CODE')
    const AFFILIATE_KEY = Deno.env.get('SUMUP_AFFILIATE_KEY')

    if (!API_KEY || !MERCHANT_CODE || !AFFILIATE_KEY) {
      return new Response(
        JSON.stringify({ error: 'SumUp Konfiguration fehlt in den Supabase Secrets.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Trigger Solo Terminal Checkout using Static API Key
    try {
      const checkoutResponse = await fetch(`https://api.sumup.com/v0.1/merchants/${MERCHANT_CODE}/readers/checkouts`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount: 1.00, // Wardrobe price
          currency: 'EUR',
          foreign_tx_id: `hook_${slotId}_${Date.now()}`,
          affiliate_key: AFFILIATE_KEY,
        }),
      })

      const checkoutData = await checkoutResponse.json()

      if (checkoutResponse.status !== 201) {
        return new Response(
          JSON.stringify({ error: checkoutData.error?.message || 'SumUp Terminal konnte nicht aktiviert werden.' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({ success: true, checkout: checkoutData }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } catch (fetchError) {
      return new Response(
        JSON.stringify({ error: `Verbindung zu SumUp fehlgeschlagen: ${fetchError.message}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
