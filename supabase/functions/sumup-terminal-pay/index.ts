import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS Preflight
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { slotId, secret } = await req.json()

    // 1. Get Static Credentials from Supabase Secrets
    const API_KEY = Deno.env.get('SUMUP_API_KEY')
    const MERCHANT_CODE = Deno.env.get('SUMUP_MERCHANT_CODE')
    const AFFILIATE_KEY = Deno.env.get('SUMUP_AFFILIATE_KEY')

    if (!API_KEY || !MERCHANT_CODE || !AFFILIATE_KEY) {
      throw new Error('SumUp configuration (API_KEY, MERCHANT_CODE, or AFFILIATE_KEY) missing in Supabase secrets.')
    }

    // 2. Trigger Reader Checkout (Solo Terminal) using Static API Key
    // This removes the need for the OAuth token dance.
    const checkoutResponse = await fetch(`https://api.sumup.com/v0.1/merchants/${MERCHANT_CODE}/readers/checkouts`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: 1.00, // Wardrobe price (Managed centrally in the cloud)
        currency: 'EUR',
        foreign_tx_id: `hook_${slotId}_${Date.now()}`, // Unique ID for tracking
        affiliate_key: AFFILIATE_KEY,
      }),
    })

    const checkoutData = await checkoutResponse.json()

    if (checkoutResponse.status !== 201) {
      throw new Error(checkoutData.error?.message || 'Failed to trigger SumUp terminal via Cloud API.')
    }

    return new Response(JSON.stringify({ success: true, checkout: checkoutData }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
