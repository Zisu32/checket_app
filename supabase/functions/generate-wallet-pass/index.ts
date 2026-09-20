import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import * as passkit from "https://esm.sh/passkit-generator@3.1.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { ticketId, groupId, secret, tenant } = await req.json()

    // 1. Initialize Supabase with Service Role (to bypass RLS for this specific task)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { db: { schema: tenant } }
    )

    // 2. Fetch Ticket Info
    let ticketDetails = "";
    let label = "";

    if (groupId) {
      const { data: slots } = await supabaseAdmin
        .from('checket_garderobe')
        .select('id')
        .eq('group_id', groupId)
        .eq('secret', secret)

      if (slots && slots.length > 0) {
        label = `Gruppe: ${slots.map(s => s.id).join(', ')}`
        ticketDetails = `${slots.length} Jacken`
      }
    } else {
      label = `Bügel ${ticketId}`
      ticketDetails = "1 Jacke"
    }

    // 3. Setup Passkit Generator
    // We expect the P12 to be stored as Base64 in Secrets
    const p12Buffer = Uint8Array.from(atob(Deno.env.get('APPLE_PASS_P12_BASE64')!), c => c.charCodeAt(0))

    const pass = await passkit.createPass({
      model: "./model", // We'll need to provide icons/logo in a subfolder or via buffers
      certificates: {
        wwdr: Deno.env.get('APPLE_WWDR_CERT'), // Standard Apple WWDR Certificate
        signerCert: p12Buffer,
        signerKey: p12Buffer,
        signerKeyPassword: Deno.env.get('APPLE_PASS_P12_PASSWORD'),
      },
    })

    // 4. Configure Pass Content (Matching AppTheme)
    pass.setPassTypeIdentifier(Deno.env.get('APPLE_PASS_TYPE_ID')!)
    pass.setTeamIdentifier(Deno.env.get('APPLE_TEAM_ID')!)

    pass.headerFields.add({ key: "ticket", label: "TICKET", value: label })
    pass.primaryFields.add({ key: "status", label: "Checket Status", value: "Aktiv" })
    pass.secondaryFields.add({ key: "info", label: "Anzahl", value: ticketDetails })

    // Design
    pass.backgroundColor = "rgb(35, 47, 57)" // AppTheme.background
    pass.labelColor = "rgb(129, 129, 129)" // AppTheme.free
    pass.foregroundColor = "rgb(223, 223, 223)" // AppTheme.white

    // Barcode (The same link used for the QR Monitor)
    const baseUrl = "https://checket.eu" // Replace with your actual domain
    const qrUrl = groupId
      ? `${baseUrl}/?groupId=${groupId}&secret=${secret}&tenant=${tenant}`
      : `${baseUrl}/?id=${ticketId}&secret=${secret}&tenant=$tenant`

    pass.barcodes.set({
      format: "PKBarcodeFormatQR",
      message: qrUrl,
      messageEncoding: "iso-8859-1"
    })

    const bundle = await pass.generate()

    return new Response(bundle, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/vnd.apple.pkpass',
        'Content-Disposition': `attachment; filename="checket_${ticketId || groupId}.pkpass"`
      },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
