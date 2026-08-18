import * as jose from "https://deno.land/x/jose@v5.2.3/index.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

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

  try {
    const { ticketId, secret, platform, origin, tenant } = await req.json()
    console.log(`--- WALLET REQUEST START ---`)
    console.log(`Ticket ID: ${ticketId}, Tenant: ${tenant}`)

    // 1. Initialize Supabase Admin
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAdmin = createClient(supabaseUrl, getSecretKey())

    // 2. Validate Ticket using the Public Fetcher RPC
    // Guests are anonymous, so we use the RPC to reach into the isolated schema
    const { data: slots, error: slotError } = await supabaseAdmin.rpc('fetch_guest_ticket', {
      p_schema: tenant || 'public',
      p_id: Number(ticketId),
      p_secret: secret
    })

    if (slotError || !slots || slots.length === 0) {
      console.error(`Validation failed for ticket ${ticketId} in tenant ${tenant}:`, slotError)
      throw new Error('Ticket ungültig oder nicht gefunden.')
    }

    const slot = slots[0]
    const baseDomain = origin ? origin.replace(/\/$/, "") : "https://checket.eu"

    // Helper for Status Coloring & Text
    const statusMap: Record<string, { color: string, text: string }> = {
      'unpaid': { color: '#B71C1C', text: 'Zahlung ausstehend' },
      'active': { color: '#00B58B', text: 'Jacke auf Platz aktiv' },
      'temporary': { color: '#E67B00', text: 'Jacke temporär draußen' },
      'forgotten': { color: '#0081C3', text: 'Jacke im Fundbüro' },
      'free': { color: '#818181', text: 'Bügel ist frei' },
    }
    const currentStatus = statusMap[slot.status] || { color: '#232F39', text: 'Status unbekannt' }

    if (platform === 'google') {
      const ISSUER_ID = Deno.env.get('GOOGLE_ISSUER_ID')?.trim()
      const CLIENT_EMAIL = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_EMAIL')?.trim()
      const PRIVATE_KEY = Deno.env.get('GOOGLE_PRIVATE_KEY')?.replace(/\\n/g, '\n')

      if (!ISSUER_ID || !CLIENT_EMAIL || !PRIVATE_KEY) {
        throw new Error('Google Wallet configuration missing.')
      }

      const genericObject = {
        id: `${ISSUER_ID}.checket_${ticketId}_${secret}`,
        classId: `${ISSUER_ID}.checket_ticket_v1`,
        genericType: "GENERIC_TYPE_UNSPECIFIED",
        hexBackgroundColor: currentStatus.color,
        logo: { sourceUri: { uri: `${baseDomain}/assets/images/logo-icon.png` } },
        cardTitle: { defaultValue: { value: "CHECKET" } },
        subheader: { defaultValue: { value: currentStatus.text } },
        header: { defaultValue: { value: `${ticketId}` } },
        heroImage: { sourceUri: { uri: `${baseDomain}/assets/images/hero-icon.png` } }
      }

      const claims = {
        iss: CLIENT_EMAIL,
        aud: "google",
        typ: "savetowallet",
        iat: Math.floor(Date.now() / 1000),
        payload: { genericObjects: [genericObject] },
      }

      const key = await jose.importPKCS8(PRIVATE_KEY, "RS256")
      const jwt = await new jose.SignJWT(claims)
        .setProtectedHeader({ alg: "RS256" })
        .sign(key)

      return new Response(
        JSON.stringify({ url: `https://pay.google.com/gp/v/save/${jwt}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ error: 'Apple Wallet noch nicht unterstützt.' }),
      { status: 501, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
