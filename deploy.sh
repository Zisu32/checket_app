#!/bin/bash
PROJECT_ID="ppyqacryhhvdjorjdezu"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBweXFhY3J5aGh2ZGpvcmpkZXp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1NTc0NjIsImV4cCI6MjEwMDEzMzQ2Mn0.7PMKwK1C2PXYsZKLQOGGLhrTqzrU4c6hYxRLlzdl9_I"
BUCKET_NAME="checket-staff"

echo "🚀 Starte Build für Checket..."
flutter build web -t lib/main_staff.dart --release

if [ $? -eq 0 ]; then
    echo "✅ Build erfolgreich. Upload zu Supabase läuft..."
    cd build/web || exit
    find . -type f | while read -r file; do
        clean_path="${file#./}"
        curl -X DELETE -H "Authorization: Bearer $ANON_KEY" -H "apikey: $ANON_KEY" "https://$PROJECT_ID.supabase.co/storage/v1/object/$BUCKET_NAME/$clean_path" &>/dev/null
        curl -X POST -H "Authorization: Bearer $ANON_KEY" -H "apikey: $ANON_KEY" --form "file=@$clean_path" "https://$PROJECT_ID.supabase.co/storage/v1/object/$BUCKET_NAME/$clean_path" &>/dev/null
    done
    echo "🎉 Checket ist live unter: https://$PROJECT_ID.supabase.co/storage/v1/object/public/$BUCKET_NAME/index.html"
else
    echo "❌ Build fehlgeschlagen."
fiDEINE_SUPABASE_PROJEKT_ID