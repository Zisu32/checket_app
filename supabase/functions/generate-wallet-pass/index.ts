import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { PKPass } from "https://esm.sh/passkit-generator@3.1.0"
import { Buffer } from "https://deno.land/std@0.168.0/node/buffer.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    let ticketId: string | number | null = null
    let groupId: string | null = null
    let secret: string | null = null
    let tenant: string | null = null
    let platform: string | null = null

    if (req.method === 'GET') {
      const url = new URL(req.url)
      ticketId = url.searchParams.get('ticketId')
      groupId = url.searchParams.get('groupId')
      secret = url.searchParams.get('secret')
      tenant = url.searchParams.get('tenant')
      platform = url.searchParams.get('platform')
    } else {
      const body = await req.json()
      ticketId = body.ticketId
      groupId = body.groupId
      secret = body.secret
      tenant = body.tenant
      platform = body.platform
    }

    if (!tenant) tenant = 'public'

    // 1. Initialize Supabase
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { db: { schema: tenant } }
    )

    // 2. Fetch Ticket Info
    let label = "";
    let ticketDetails = "";
    let found = false;

    if (groupId) {
      const { data: slots } = await supabaseAdmin
        .from('checket_garderobe')
        .select('id')
        .eq('group_id', groupId)
        .eq('secret', secret)

      if (slots && slots.length > 0) {
        label = slots.map(s => s.id).join(', ')
        ticketDetails = `${slots.length} Jacken`
        found = true;
      }
    } else if (ticketId) {
      const { data: slot } = await supabaseAdmin
        .from('checket_garderobe')
        .select('id')
        .eq('id', ticketId)
        .eq('secret', secret)
        .single()

      if (slot) {
        label = `${slot.id}`
        ticketDetails = "1 Jacke"
        found = true;
      }
    }

    if (!found) throw new Error("Ticket nicht gefunden.")

    // 3. Prepare Certificates
    const envWwdr = Deno.env.get('APPLE_WWDR_CERT')?.trim()
    const envSignerCert = Deno.env.get('APPLE_SIGNER_CERT')?.trim()
    const envSignerKey = Deno.env.get('APPLE_SIGNER_KEY')?.trim()
    const envSignerKeyPassphrase = Deno.env.get('APPLE_SIGNER_KEY_PASSPHRASE')?.trim()
    const passTypeId = Deno.env.get('APPLE_PASS_TYPE_ID')?.trim()
    const teamId = Deno.env.get('APPLE_TEAM_ID')?.trim()

    if (!envWwdr || !envSignerCert || !envSignerKey || !envSignerKeyPassphrase || !passTypeId || !teamId) {
      throw new Error("Apple Wallet Zertifikate/Secrets fehlen in der Supabase-Konfiguration.")
    }

    const wwdr = Buffer.from(envWwdr, 'base64').toString('utf-8');
    const signerCert = Buffer.from(envSignerCert, 'base64').toString('utf-8');
    const signerKey = Buffer.from(envSignerKey, 'base64').toString('utf-8');
    const signerKeyPassphrase = Buffer.from(envSignerKeyPassphrase, 'base64').toString('utf-8');

    // Model Template (pass.json) laden
    const passJson = await Deno.readFile(new URL("./model/pass.json", import.meta.url));

    // 4. Create Pass
    const pass = new PKPass({
      "pass.json": passJson,
    }, {
      wwdr: wwdr,
      signerCert: signerCert,
      signerKey: signerKey,
      signerKeyPassphrase: signerKeyPassphrase,
    });

    // Set Identifiers
    pass.setPassTypeIdentifier(passTypeId);
    pass.setTeamIdentifier(teamId);

    // Set Colors
    pass.backgroundColor = "rgb(39, 39, 44)";
    pass.foregroundColor = "rgb(227, 227, 223)";
    pass.labelColor = "rgb(142, 145, 143)";

    // Fields
    pass.headerFields.add({ key: "ticket", label: "TICKET", value: label });
    pass.primaryFields.add({ key: "status", label: "Checket Status", value: "Aktiv" });
    pass.secondaryFields.add({ key: "info", label: "Anzahl", value: ticketDetails });

    // QR-Code
    const baseUrl = "https://checket.eu"
    const qrUrl = groupId
      ? `${baseUrl}/?groupId=${groupId}&secret=${secret}&tenant=${tenant}`
      : `${baseUrl}/?id=${ticketId}&secret=${secret}&tenant=${tenant}`

    pass.barcodes.set({
      format: "PKBarcodeFormatQR",
      message: qrUrl,
      messageEncoding: "iso-8859-1"
    });

    // Add Resources (pass.json + images)
    const addResource = async (name: string) => {
      try {
        const data = await Deno.readFile(new URL(`./model/${name}`, import.meta.url));
        pass.addResource(name, data);
      } catch (e) {
        console.warn(`Could not load resource ${name}:`, e.message);
      }
    };

    await addResource("pass.json");
    await addResource("icon.png");
    await addResource("icon@2x.png");
    await addResource("logo.png");
    await addResource("logo@2x.png");

    const bundle = await pass.generate();

    return new Response(bundle, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/vnd.apple.pkpass',
        'Content-Disposition': `inline; filename="checket_${ticketId || groupId}.pkpass"`
      },
      status: 200,
    })

  } catch (error) {
    console.error("Wallet Error Detail:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
