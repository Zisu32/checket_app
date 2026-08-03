import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import * as jose from "https://deno.land/x/jose@v5.2.3/index.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { ticketId, secret, platform } = await req.json()

    if (platform === 'google') {
      const ISSUER_ID = Deno.env.get('GOOGLE_ISSUER_ID')
      const CLIENT_EMAIL = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_EMAIL')
      const PRIVATE_KEY = Deno.env.get('GOOGLE_PRIVATE_KEY')?.replace(/\\n/g, '\n')

      if (!ISSUER_ID || !CLIENT_EMAIL || !PRIVATE_KEY) {
        throw new Error('Google Wallet configuration missing in Supabase secrets.')
      }

      // 1. Define the Ticket Object (Generic Pass)
      const genericObject = {
        id: `${ISSUER_ID}.checket_${ticketId}_${Date.now()}`,
        classId: `${ISSUER_ID}.checket_ticket_v1`,
        genericType: "GENERIC_TYPE_UNSPECIFIED",
        hexBackgroundColor: "#11171C",
        logo: {
          sourceUri: { uri: "https://zisu32.github.io/checket_app/assets/images/full-icon.png" },
        },
        cardTitle: {
          defaultValue: { language: "de", value: "CHECKET Garderobe" },
        },
        subheader: {
          defaultValue: { language: "de", value: "BÜGELNUMMER" },
        },
        header: {
          defaultValue: { language: "de", value: `#${ticketId}` },
        },
        barcode: {
          type: "QR_CODE",
          value: `https://zisu32.github.io/checket_app/#/ticket?id=${ticketId}&secret=${secret}`,
        },
      }

      // 2. Prepare JWT Claims
      const claims = {
        iss: CLIENT_EMAIL,
        aud: "google",
        typ: "savetowallet",
        iat: Math.floor(Date.now() / 1000),
        payload: {
          genericObjects: [genericObject],
        },
      }

      // 3. Sign the JWT using RS256
      const privateKey = await jose.importPKCS8(PRIVATE_KEY, "RS256")
      const jwt = await new jose.SignJWT(claims)
        .setProtectedHeader({ alg: "RS256" })
        .sign(privateKey)

      return new Response(
        JSON.stringify({ url: `https://pay.google.com/gp/p/save/${jwt}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Apple Placeholder (Requires .pkpass binary generation)
    return new Response(
      JSON.stringify({ error: 'Apple Wallet integration requires certificate signing.' }),
      { status: 501, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
