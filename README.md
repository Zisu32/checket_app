# Checket - Smart Wardrobe System

Checket ist ein digitales Garderoben-Management-System, das physische Garderobenmarken durch digitale Tickets ersetzt. Es ist als **Progressive Web App (PWA)** konzipiert und nutzt eine **Local-First-Architektur** mit Drift (SQLite) und Supabase.

## Features

*   **Mitarbeiter-Dashboard**: Echtzeit-Übersicht über alle Bügel, Status-Verwaltung (Check-in, Check-out, Bezahlung).
*   **Digitales Kunden-Ticket**: Web-Ansicht für Kunden mit Live-Updates via Supabase Realtime.
*   **Local-First Sync**: Abgleich durch Drift-Cache (SQLite); automatischer Abgleich mit der Cloud-Supabase.
*   **Stripe Payment**: Kunden können ihre Garderobe direkt online bezahlen.
*   **Wallet Integration**: Support für Apple und Google Wallet.
*   **Push-Benachrichtigungen**: Kunden können sich benachrichtigen lassen, falls sie ihre Jacke vergessen haben.

## Architektur & Konzept

Checket nutzt ein modernes Cloud-Native-Setup:

*   **Frontend (PWA)**: Entwickelt mit Flutter Web. Gehostet auf **GitHub Pages**. Installierbar auf Android, Windows und iOS für ein natives App-Gefühl.
*   **Data Layer (Hybrid)**:
    *   **Drift Database**: Dient als Speicher (SQLite via WASM) im Browser und auf nativen Geräten.
    *   **Supabase**: Agiert als "Source of Truth" und bietet Realtime-Events.
*   **CI/CD**: Vollautomatisches Deployment über **GitHub Actions**. Jedes `git push` aktualisiert die Live-Systeme unter Verwendung von WebAssembly (WASM).

---

## Verzeichnisstruktur unter der Lupe

### `.github/workflows/`
Enthält die **CI/CD-Logik**. Die Datei `deploy.yml` steuert den automatischen Build-Prozess, lädt benötigte SQLite-WASM Binaries herunter und verteilt die Apps auf GitHub Pages.

### `lib/` (Kern der Anwendung)
*   **`main_staff.dart` & `main_customer.dart`**: Die Startpunkte für die beiden spezialisierten Apps.
*   **`shared/database/database.dart`**: Definition der Drift-Datenbank und der Tabellen. Die zugehörigen Datenklassen (Modelle) werden automatisch in `database.g.dart` generiert.
*   **`shared/services/sync_service.dart`**: Die Verbindung zwischen der lokalen SQLite-DB (Drift) und Supabase. Kümmert sich um den Datenabgleich und Realtime-Updates.
*   **`staff_app/views/`**: Das UI des Garderoben-Managers.
*   **`customer_app/views/`**: Die Ticket-Ansicht für den Endnutzer.

### `supabase/` (Backend-Infrastruktur)
*   **`functions/`**: Edge Functions für sicherheitskritische Aufgaben wie die Stripe-Zahlungsabwicklung.
*   **`config.toml`**: Verknüpfung des lokalen Projekts mit der Supabase-Cloud.

### `web/` (Web-Plattform Konfiguration)
*   **`manifest.json`**: Die PWA-Konfiguration (Icons, Start-URL, Farben für den Homescreen).
*   **`index.html`**: Das HTML-Grundgerüst, in dem Flutter geladen wird.

---

## Installation & Setup

1.  **Repository klonen:**
    ```bash
    git clone
    cd checket_app
    ```

2.  **Abhängigkeiten installieren:**
    ```bash
    flutter pub get
    ```

3.  **GitHub Secrets einrichten:**
    Hinterlege in deinem Repository unter *Settings > Secrets > Actions*:
    *   `SUPABASE_URL_PROD` & `SUPABASE_ANON_KEY_PROD`
    *   `SUPABASE_URL_DEV` & `SUPABASE_ANON_KEY_DEV`

## Entwicklung & Deployment

### Lokal Testen
Die App nutzt lokal standardmäßig das **Checket-Dev** Projekt. Für Web-Entwicklung wird der WASM-Renderer empfohlen.
```bash
# Mitarbeiter-App
flutter run -d chrome -t lib/main_staff.dart --wasm

# Kunden-App
flutter run -d chrome -t lib/main_customer.dart --wasm
```

### Deployment (Automatisch)
Das Deployment erfolgt über GitHub-Action:

*   **Entwicklung**: Push auf den Branch `dev`.
*   **Produktion**: Pull Request auf den Branch `main`.

---

## 🔗 Live Umgebungen (GitHub Pages)

*   **Produktion (Mitarbeiter):** `https://<dein-nutzer>.github.io/checket_app/staff/`
*   **Produktion (Kunden):** `https://<dein-nutzer>.github.io/checket_app/`
*   **Entwicklung (Mitarbeiter):** `https://<dein-nutzer>.github.io/checket_app/dev/staff/`
*   **Entwicklung (Kunden):** `https://<dein-nutzer>.github.io/checket_app/dev/?id=5&secret=test`
