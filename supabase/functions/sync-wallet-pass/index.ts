import { google } from "npm:googleapis"
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

    //PAYLOAD VERARBEITUNG
    const payload = await req.json()
    const { record, old_record } = payload

    console.log(`--- SYNC REQUEST START ---`)
    console.log(`Update on ticket ID: ${record.id}`)

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
      throw new Error('Google Wallet Konfiguration fehlt.')
    }

    const auth = new google.auth.GoogleAuth({
      credentials: { client_email: CLIENT_EMAIL, private_key: PRIVATE_KEY },
      scopes: ['https://www.googleapis.com/auth/wallet_object.issuer'],
    })

    const walletobjects = google.walletobjects({ version: 'v1', auth: auth })

    const statusMap: Record<string, { color: string, text: string }> = {
      'unpaid': { color: '#B71C1C', text: 'Zahlung ausstehend' },
      'active': { color: '#00B58B', text: 'Jacke auf Platz aktiv' },
      'temporary': { color: '#E67B00', text: 'Jacke temporär draußen' },
      'forgotten': { color: '#0081C3', text: 'Jacke im Fundbüro' },
      'free': { color: '#818181', text: 'Bügel ist frei' },
    }
    const currentStatus = statusMap[record.status] || { color: '#232F39', text: 'Status aktualisiert' }

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