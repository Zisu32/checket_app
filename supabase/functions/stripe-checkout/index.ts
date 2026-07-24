import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from "https://esm.sh/stripe@12.18.0"

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2022-11-15' });
const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apiKey, content-type' };

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const { buegelId, secret } = await req.json();
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card', 'giropay'],
      line_items: [{ price_data: { currency: 'eur', product_data: { name: `Garderobe Bügel ${buegelId}` }, unit_amount: 250 }, quantity: 1 }],
      mode: 'payment',
      metadata: { buegel_id: buegelId, secret: secret },
      success_url: `https://web.app/${buegelId}&secret=${secret}&paid=true`,
      cancel_url: `https://web.app/${buegelId}&secret=${secret}`,
    });
    return new Response(JSON.stringify({ url: session.url }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
  }
})
