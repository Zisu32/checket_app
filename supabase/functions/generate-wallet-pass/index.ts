import * as jose from "https://deno.land/x/jose@v5.2.3/index.ts"
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
    const { ticketId, secret, platform, origin } = await req.json()
    console.log(`Ticket ID: ${ticketId}, Platform: ${platform}`)

    const baseDomain = origin ? origin.replace(/\/$/, "") : "https://checket.eu"
    const tid = Number(ticketId)

    const { data: slot, error: slotError } = await supabase
      .from('checket_garderobe')
      .select('id, status, secret')
      .eq('id', tid)
      .eq('secret', secret)
      .single()

    if (slotError) {
      console.error(`Database Query Error for ID ${tid}:`, slotError.message)
      throw new Error(`Ticket-Abfrage fehlgeschlagen: ${slotError.message}`)
    }

    if (!slot) {
      console.error(`No slot found for ID ${tid} with provided secret.`)
      throw new Error('Ticket ungültig oder nicht gefunden.')
    }

    console.log(`Validation Success: Slot ${slot.id} is in status ${slot.status}`)

    const statusMap: Record<string, { color: string, text: string }> = {
      'unpaid': { color: '#B71C1C', text: 'Zahlung ausstehend' },
      'active': { color: '#00B58B', text: 'Jacke auf Platz aktiv' },
      'temporary': { color: '#E67B00', text: 'Jacke temporär draußen' },
      'forgotten': { color: '#0081C3', text: 'Jacke im Fundbüro' },
      'free': { color: '#818181', text: 'Bügel ist frei' },
    }
    const currentStatus = statusMap[slot.status] || { color: '#232F39', text: 'Status unbekannt' }

    if (platform === 'google') {
      const ISSUER_ID = Deno.env.get('GOOGLE_ISSUER_ID')
      const CLIENT_EMAIL = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_EMAIL')
      const PRIVATE_KEY = Deno.env.get('GOOGLE_PRIVATE_KEY')?.replace(/\\n/g, '\n')

      if (!ISSUER_ID || !CLIENT_EMAIL || !PRIVATE_KEY) {
        throw new Error('Google Wallet Konfiguration fehlt in den Supabase Secrets.')
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
      JSON.stringify({ error: 'Apple Wallet erfordert Zertifikat-Signierung (PKPass).' }),
      { status: 501, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error(`Wallet Error:`, error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})