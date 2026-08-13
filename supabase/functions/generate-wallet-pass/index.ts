import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import * as jose from "https://deno.land/x/jose@v5.2.3/index.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS Preflight
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { ticketId, secret, platform, origin } = await req.json()
    console.log(`--- WALLET REQUEST START ---`)
    console.log(`Ticket ID: ${ticketId} (Type: ${typeof ticketId})`)
    console.log(`Secret: ${secret?.substring(0, 3)}...`)
    console.log(`Platform: ${platform}`)
    console.log(`Origin: ${origin}`)

    // 1. Initialize Supabase Admin
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const secretKey = Deno.env.get('SUPABASE_SECRET_KEYS')

    console.log(`Supabase URL configured: ${supabaseUrl ? 'YES' : 'MISSING'}`)
    console.log(`SecretKey available: ${secretKey ? 'YES (' + secretKey.substring(0, 5) + '...)' : 'MISSING'}`)

    const supabase = createClient(supabaseUrl ?? '', secretKey ?? '')

    // Use passed origin or fallback to production domain
    const baseDomain = origin ? origin.replace(/\/$/, "")

    // 2. Validate Ticket (Check if ID and Secret match in the database)
    const { data: slot, error: slotError } = await supabase
      .from('checket_garderobe')
      .select('id, status')
      .eq('id', Number(ticketId))
      .eq('secret', secret)
      .single()

    if (slotError) {
      console.error(`Database Query Error for ID ${ticketId}:`, slotError.message)
      console.error(`Error Code:`, slotError.code)
      throw new Error(`Ticket-Abfrage fehlgeschlagen: ${slotError.message}`)
    }

    if (!slot) {
      console.error(`No slot found for ID ${ticketId} with provided secret.`)
      throw new Error('Ticket ungültig oder nicht gefunden.')
    }

    console.log(`Validation Success: Slot ${slot.id} is in status ${slot.status}`)

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
      const ISSUER_ID = Deno.env.get('GOOGLE_ISSUER_ID')
      const CLIENT_EMAIL = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_EMAIL')
      const PRIVATE_KEY = Deno.env.get('GOOGLE_PRIVATE_KEY')?.replace(/\\n/g, '\n')

      if (!ISSUER_ID || !CLIENT_EMAIL || !PRIVATE_KEY) {
        throw new Error('Google Wallet Konfiguration fehlt in den Supabase Secrets.')
      }

      // 3. Define the Pass Object
      const genericObject = {
        id: `${ISSUER_ID}.checket_${ticketId}_${secret}`,
        classId: `${ISSUER_ID}.checket_ticket_v1`,
        genericType: "GENERIC_TYPE_UNSPECIFIED",
        hexBackgroundColor: currentStatus.color,
        logo: {
          sourceUri: { uri: `${baseDomain}/assets/images/logo-icon.png` },
        },
        cardTitle: {
          defaultValue: { language: "de", value: "CHECKET" },
        },
        subheader: {
          defaultValue: { language: "de", value: currentStatus.text },
        },
        header: {
          defaultValue: { language: "de", value: `${ticketId}` },
        },
        heroImage: {
          sourceUri: { uri: `${baseDomain}/assets/images/hero-icon.png` }
        }
      }

      // 4. Create JWT Claims
      const claims = {
        iss: CLIENT_EMAIL,
        aud: "google",
        typ: "savetowallet",
        iat: Math.floor(Date.now() / 1000),
        payload: {
          genericObjects: [genericObject],
        },
      }

      // 5. Sign JWT
      const key = await jose.importPKCS8(PRIVATE_KEY, "RS256")
      const jwt = await new jose.SignJWT(claims)
        .setProtectedHeader({ alg: "RS256" })
        .sign(key)

      return new Response(
        JSON.stringify({ url: `https://pay.google.com/gp/p/save/${jwt}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Apple Implementation (Future)
    return new Response(
      JSON.stringify({ error: 'Apple Wallet erfordert Zertifikat-Signierung (PKPass).' }),
      { status: 501, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
