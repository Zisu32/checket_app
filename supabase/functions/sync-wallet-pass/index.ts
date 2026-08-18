import { google } from "npm:googleapis"
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
    const payload = await req.json()
    // Supabase Webhooks include 'schema', 'table', 'record', 'old_record'
    const { schema, record, old_record } = payload

    console.log(`--- SYNC WEBHOOK START ---`)
    console.log(`Tenant: ${schema}, Ticket ID: ${record.id}`)

    // Only proceed if status has changed
    if (record.status === old_record?.status) {
      return new Response(JSON.stringify({ message: 'No status change' }), { status: 200 })
    }

    const ISSUER_ID = Deno.env.get('GOOGLE_ISSUER_ID')?.trim()
    const CLIENT_EMAIL = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_EMAIL')?.trim()
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
    // Unique resourceId per tenant: issuerId.checket_tenant_ticketId_secret
    const resourceId = `${ISSUER_ID}.checket_${schema}_${record.id}_${record.secret}`
    console.log(`Patching pass for tenant ${schema}: ${resourceId}`)

    await walletobjects.genericObject.patch({
      resourceId: resourceId,
      requestBody: {
        hexBackgroundColor: currentStatus.color,
        subheader: {
          defaultValue: { language: 'de', value: currentStatus.text },
        },
      },
    })

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Wallet Sync Webhook Error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
