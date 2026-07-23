# Checket - Smart Wardrobe System

Checket ist ein digitales Garderoben-Management-System, das physische Garderobenmarken durch digitale Tickets ersetzt. Es ist als hochperformante **Progressive Web App (PWA)** konzipiert und nutzt ein serverloses Backend auf Basis von Supabase.

## Features

*   **Mitarbeiter-Dashboard**: Übersicht über alle Bügel, Status-Verwaltung (Check-in, Check-out, Bezahlung).
*   **Digitales Kunden-Ticket**: Web-Ansicht für Kunden mit Status-Updates in Echtzeit.
*   **Stripe Payment**: Kunden können ihre Garderobe direkt online bezahlen.
*   **Wallet Integration**: Kunden können ihr Ticket zu Apple oder Google Wallet hinzufügen.
*   **Push-Benachrichtigung**: Kunden könnem Push-Benachrichtigung aktivieren, falls Sie Ihre Jacke vergessen haben

## Architektur & Konzept

Checket basiert auf einer modernen, entkoppelten Architektur:

*   **Frontend (PWA)**: Entwickelt mit Flutter Web. Durch den PWA-Standard können beide Apps (Mitarbeiter & Kunden) direkt über den Browser auf mobilen Geräten installiert werden, ohne einen App Store zu nutzen. Sie verhalten sich wie native Apps (Vollbild, Homescreen-Icon).
*   **Backend (BaaS)**: Supabase übernimmt die Datenbank-Echtzeit-Synchronisierung, Authentifizierung und das Hosting der Web-Dateien.
*   **Serverless Logic**: Kritische Prozesse wie die Stripe-Zahlungsabwicklung laufen in isolierten Supabase Edge Functions (Deno), um Sicherheit und Skalierbarkeit zu gewährleisten.
    
## Verzeichnisstruktur

### `lib/` (Kern der Anwendung)
Hier liegt der gesamte Flutter-Code.
*   `main_staff.dart` & `main_customer.dart`: Die jeweiligen "Motoren" für die beiden App-Varianten.
*   `shared/models/`: Enthält die Datenstrukturen, die sowohl vom Mitarbeiter als auch vom Kunden genutzt werden.
*   `staff_app/views/`: Das UI für das Mitarbeiter-Dashboard zur Verwaltung der Bügel.
*   `customer_app/views/`: Das UI für die digitale Ticket-Ansicht des Kunden.

### `supabase/` (Backend & Cloud)
Alles, was nicht direkt im Browser läuft.
*   `functions/stripe-checkout/`: Eine TypeScript-Funktion, die sicher mit der Stripe-API kommuniziert, um Bezahlsitzungen zu erstellen.
*   `config.toml`: Die Konfigurationsdatei für deine Supabase-Projektverbindung.

### `web/` (Web-Spezifisches)
Notwendig für die PWA-Funktionalität.
*   `manifest.json`: Definiert, wie die App auf dem Handy aussieht (Icon, Name, Farben), wenn sie installiert wird.
*   `index.html`: Das Grundgerüst, das die Flutter-Engine im Browser startet.

---

## Installation

1.  **Repository klonen:**
    ```bash
    git clone
    cd checket_app
    ```

2.  **Abhängigkeiten installieren:**
    ```bash
    flutter pub get
    ```

3.  **Supabase CLI einrichten:**
    Stelle sicher, dass die [Supabase CLI](https://supabase.com/docs/guides/cli) installiert ist.
    ```bash
    supabase login
    supabase link --project-ref ppyqacryhhvdjorjdezu
    ```

## Lokal Starten

Da das Projekt zwei Apps enthält, musst du beim Starten die entsprechende Datei angeben:

**Mitarbeiter-App:**
```bash
flutter run -d chrome -t lib/main_staff.dart
```

**Kunden-App:**
```bash
flutter run -d chrome -t lib/main_customer.dart
```

## Deployment

### 1. Backend (Edge Functions)
Um die Bezahlfunktion zu aktualisieren:
```bash
supabase functions deploy stripe-checkout --no-verify-jwt
```

### 2. Frontend (Web-Apps)
2 Skripte, die den Build erstellen und direkt in den Supabase Storage hochladen:

**Mitarbeiter-App hochladen:**
```bash
chmod +x deploy_staff.sh
./deploy_staff.sh
```

**Kunden-App hochladen:**
```bash
chmod +x deploy_customer.sh
./deploy_customer.sh
```

---

## 🔗 Live Links

*   **Mitarbeiter-Dashboard:** [https://ppyqacryhhvdjorjdezu.supabase.co/storage/v1/object/public/checket-staff/index.html](https://ppyqacryhhvdjorjdezu.supabase.co/storage/v1/object/public/checket-staff/index.html)
*   **Kunden-Ticket (Beispiel):** [https://ppyqacryhhvdjorjdezu.supabase.co/storage/v1/object/public/checket-customer/index.html?id=1&secret=test](https://ppyqacryhhvdjorjdezu.supabase.co/storage/v1/object/public/checket-customer/index.html?id=1&secret=test)
