import { google } from "npm:googleapis"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function getSecretKey(): string {
  const envSecretKeys = Deno.env.get('SUPABASE_SECRET_KEYS');

  // 1. Wahl: JSON aus SUPABASE_SECRET_KEYS parsen
  if (envSecretKeys) {
    try {
      const parsed = JSON.parse(envSecretKeys);
      if (parsed?.default) {
        return parsed.default;
      }
    } catch {
      // Falls es kein validiertes JSON ist, sondern aus Versehen doch ein Direct-String:
      return envSecretKeys;
    }
  }

  // 2. Wahl: Einzelne Variable SUPABASE_SECRET_KEY
  const singleSecretKey = Deno.env.get('SUPABASE_SECRET_KEY');
  if (singleSecretKey) {
    return singleSecretKey;
  }

  throw new Error('Kein gültiger Supabase Secret Key gefunden!');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const payload = await req.json()
    const { record, old_record } = payload

    console.log(`--- SYNC REQUEST START ---`)
    console.log(`Update on ticket ID: ${record.id}`)

    // Only proceed if status has changed
    if (record.status === old_record?.status) {
      console.log('No status change, skipping update.')
      return new Response(JSON.stringify({ message: 'No status change' }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const ISSUER_ID = Deno.env.get('GOOGLE_ISSUER_ID')
    const CLIENT_EMAIL = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_EMAIL')
    const PRIVATE_KEY = Deno.env.get('GOOGLE_PRIVATE_KEY')?.replace(/\\n/g, '\n')

    if (!ISSUER_ID || !CLIENT_EMAIL || !PRIVATE_KEY) {
      throw new Error('Google Wallet configuration missing in secrets.')
    }

    // 1. Authenticate with Google
    const auth = new google.auth.GoogleAuth({
      credentials: {
        client_email: CLIENT_EMAIL,
        private_key: PRIVATE_KEY,
      },
      scopes: ['https://www.googleapis.com/auth/wallet_object.issuer'],
    })

    const walletobjects = google.walletobjects({
      version: 'v1',
      auth: auth,
    })

    // 2. Map Status to Pass UI
    const statusMap: Record<string, { color: string, text: string }> = {
      'unpaid': { color: '#B71C1C', text: 'Zahlung ausstehend' },
      'active': { color: '#00B58B', text: 'Jacke auf Platz aktiv' },
      'temporary': { color: '#E67B00', text: 'Jacke temporär draußen' },
      'forgotten': { color: '#0081C3', text: 'Jacke im Fundbüro' },
      'free': { color: '#818181', text: 'Bügel ist frei' },
    }
    const currentStatus = statusMap[record.status] || { color: '#232F39', text: 'Status aktualisiert' }

    // 3. Update the Object in Google Wallet
    // The ID matches the one generated in generate-wallet-pass: issuerId.checket_ticketId_secret
    const resourceId = `${ISSUER_ID}.checket_${record.id}_${record.secret}`
    console.log(`Patching pass: ${resourceId} with color ${currentStatus.color}`)

    await walletobjects.genericObject.patch({
      resourceId: resourceId,
      requestBody: {
        hexBackgroundColor: currentStatus.color,
        subheader: {
          defaultValue: { language: 'de', value: currentStatus.text },
        },
      },
    })

    console.log(`Successfully updated pass for ticket ${record.id}`)

    return new Response(JSON.stringify({ success: true, updatedId: resourceId }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Wallet Sync Error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
