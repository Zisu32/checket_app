import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
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

    // 1. Initialize Supabase with Service Role
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { db: { schema: tenant } }
    )

    // 2. Fetch Ticket Info & Verify Secret (Security)
    let ticketDetails = "";
    let label = "";
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

    if (!found) {
      throw new Error("Ticket nicht gefunden oder Zugriff verweigert.")
    }

    // 3. Setup Pass Certificates
    const p12Buffer = Uint8Array.from(atob(Deno.env.get('APPLE_PASS_P12_BASE64')!), c => c.charCodeAt(0))
    const wwdrBuffer = Uint8Array.from(atob(Deno.env.get('APPLE_WWDR_CERT')!), c => c.charCodeAt(0))

    // 4. Create Pass
    // Note: We use the generic type for wardrobe tickets
    const pass = new PKPass({}, {
      wwdr: wwdrBuffer,
      signerCert: p12Buffer,
      signerKey: p12Buffer,
      signerKeyPassword: Deno.env.get('APPLE_PASS_P12_PASSWORD'),
    });

    // Load template from pass.json in model folder
    // Since we are in Deno, we might need to read the file manually if path-based loading fails
    const passJson = await Deno.readTextFile(new URL("./model/pass.json", import.meta.url));
    const template = JSON.parse(passJson);

    // Merge template into pass
    pass.setPassTypeIdentifier(Deno.env.get('APPLE_PASS_TYPE_ID')!);
    pass.setTeamIdentifier(Deno.env.get('APPLE_TEAM_ID')!);

    // Colors from AppTheme
    pass.backgroundColor = "rgb(39, 39, 44)"; // background
    pass.foregroundColor = "rgb(227, 227, 223)"; // white
    pass.labelColor = "rgb(142, 145, 143)"; // free

    pass.headerFields.add({ key: "ticket", label: "TICKET", value: label });
    pass.primaryFields.add({ key: "status", label: "Checket Status", value: "Aktiv" });
    pass.secondaryFields.add({ key: "info", label: "Anzahl", value: ticketDetails });

    // Barcode
    const baseUrl = "https://checket.eu"
    const qrUrl = groupId
      ? `${baseUrl}/?groupId=${groupId}&secret=${secret}&tenant=${tenant}`
      : `${baseUrl}/?id=${ticketId}&secret=${secret}&tenant=${tenant}`

    pass.barcodes.set({
      format: "PKBarcodeFormatQR",
      message: qrUrl,
      messageEncoding: "iso-8859-1"
    });

    // Add images manually to be safe with Deno's bundle system
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
    console.error("Wallet Error:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
