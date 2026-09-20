import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { Buffer } from "https://deno.land/std@0.168.0/node/buffer.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { PKPass } from "https://esm.sh/passkit-generator@3.1.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { ticketId, groupId, secret, tenant } = await req.json()

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
    } else {
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

    // 3. Prepare Certificates using Buffer (required by the library)
    const wwdr = Buffer.from(Deno.env.get('APPLE_WWDR_CERT')!, 'base64');
    const p12 = Buffer.from(Deno.env.get('APPLE_PASS_P12_BASE64')!, 'base64');
    const signerKeyPassword = Deno.env.get('APPLE_PASS_P12_PASSWORD')!;

    // 4. Create Pass
    // We pass the p12 to both signerCert and signerKey, the library will attempt
    // to extract what it needs using the password.
    const pass = new PKPass({}, {
      wwdr: wwdr,
      signerCert: p12,
      signerKey: p12,
      signerKeyPassword: signerKeyPassword,
    });

    // Set Identifiers
    pass.setPassTypeIdentifier(Deno.env.get('APPLE_PASS_TYPE_ID')!);
    pass.setTeamIdentifier(Deno.env.get('APPLE_TEAM_ID')!);

    // Set Colors
    pass.backgroundColor = "rgb(39, 39, 44)";
    pass.foregroundColor = "rgb(227, 227, 223)";
    pass.labelColor = "rgb(142, 145, 143)";

    // Fields
    pass.headerFields.add({ key: "ticket", label: "TICKET", value: label });
    pass.primaryFields.add({ key: "status", label: "Checket Status", value: "Aktiv" });
    pass.secondaryFields.add({ key: "info", label: "Anzahl", value: ticketDetails });

    // QR Code
    const baseUrl = "https://checket.eu"
    const qrUrl = groupId
      ? `${baseUrl}/?groupId=${groupId}&secret=${secret}&tenant=${tenant}`
      : `${baseUrl}/?id=${ticketId}&secret=${secret}&tenant=${tenant}`

    pass.barcodes.set({
      format: "PKBarcodeFormatQR",
      message: qrUrl,
      messageEncoding: "iso-8859-1"
    });

    // Add Images
    const addImage = async (name: string) => {
      try {
        const data = await Deno.readFile(new URL(`./model/${name}`, import.meta.url));
        pass.addResource(name, data);
      } catch (e) {
        console.warn(`Could not load image ${name}:`, e.message);
      }
    };

    await addImage("icon.png");
    await addImage("icon@2x.png");
    await addImage("logo.png");
    await addImage("logo@2x.png");

    const bundle = await pass.generate();

    return new Response(bundle, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/vnd.apple.pkpass',
        'Content-Disposition': `attachment; filename="checket_${ticketId || groupId}.pkpass"`
      },
      status: 200,
    })

  } catch (error) {
    console.error("Wallet Error Detail:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
