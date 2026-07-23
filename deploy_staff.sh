#!/bin/bash
PROJECT_ID="ppyqacryhhvdjorjdezu"
BUCKET_NAME="checket-staff"
FLUTTER_BIN="/home/zisu32/Android/flutter/bin/flutter"

echo "Starte Build für Checket (Staff)..."
$FLUTTER_BIN build web -t lib/main_staff.dart --release --base-href "/storage/v1/object/public/$BUCKET_NAME/"

if [ $? -eq 0 ]; then
    echo "Upload zu Supabase läuft (mit expliziten MIME-Types)..."

    # Wir gehen alle Dateien im Build-Ordner durch und setzen den Typ manuell
    find build/web -type f | while read -r file; do
        rel_path="${file#build/web/}"
        ext="${file##*.}"

        # Standard-Cache: 1 Stunde. Index.html: kein Cache.
        cache="max-age=3600"

        case "$ext" in
            html) type="text/html"; cache="no-cache, no-store, must-revalidate" ;;
            js)   type="application/javascript" ;;
            css)  type="text/css" ;;
            json) type="application/json" ;;
            png)  type="image/png" ;;
            wasm) type="application/wasm" ;;
            ico)  type="image/x-icon" ;;
            svg)  type="image/svg+xml" ;;
            ttf)  type="font/ttf" ;;
            otf)  type="font/otf" ;;
            woff) type="font/woff" ;;
            woff2) type="font/woff2" ;;
            bin)  type="application/octet-stream" ;;
            *)    type="auto-detect" ;;
        esac

        # Wir löschen die Datei zuerst, um den 409 (Duplicate) Fehler zu vermeiden
        supabase storage rm --experimental --yes "ss:///$BUCKET_NAME/$rel_path" 2>/dev/null

        # Upload mit Typ-Prüfung
        if [ "$type" = "auto-detect" ]; then
            supabase storage cp --experimental --cache-control "$cache" "$file" "ss:///$BUCKET_NAME/$rel_path"
        else
            supabase storage cp --experimental --content-type "$type" --cache-control "$cache" "$file" "ss:///$BUCKET_NAME/$rel_path"
        fi
    done

    echo "Build erfolgreich. Checket ist live unter: https://$PROJECT_ID.supabase.co/storage/v1/object/public/$BUCKET_NAME/index.html"
else
    echo "Build fehlgeschlagen."
fi
