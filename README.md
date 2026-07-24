# Checket - Smart Wardrobe System

Checket ist ein digitales Garderoben-Management-System, das physische Garderobenmarken durch digitale Tickets ersetzt. Es ist als **Progressive Web App (PWA)** konzipiert und nutzt eine **Local-First-Architektur** mit Isar und Supabase.

## Features

*   **Mitarbeiter-Dashboard**: Echtzeit-Übersicht über alle Bügel, Status-Verwaltung (Check-in, Check-out, Bezahlung).
*   **Digitales Kunden-Ticket**: Web-Ansicht für Kunden mit Live-Updates via Supabase Realtime.
*   **Local-First Sync**: Ultraschneller Abgleich durch Isar-Cache; automatischer Abgleich mit der Cloud.
*   **Stripe Payment**: Kunden können ihre Garderobe direkt online bezahlen.
*   **Wallet Integration**: Support für Apple und Google Wallet.
*   **Push-Benachrichtigungen**: Kunden können sich benachrichtigen lassen, falls sie ihre Jacke vergessen haben.

## Architektur & Konzept

Checket nutzt ein modernes Cloud-Native-Setup:

*   **Frontend (PWA)**: Entwickelt mit Flutter Web. Gehostet auf **GitHub Pages**. Installierbar auf Android, Windows und iOS für ein natives App-Gefühl.
*   **Data Layer (Hybrid)**:
    *   **Isar Database**: Dient als lokaler Hochgeschwindigkeitsspeicher im Browser.
    *   **Supabase**: Agiert als "Source of Truth" (Zentrale Datenbank) und bietet Realtime-Events.
*   **CI/CD**: Vollautomatisches Deployment über **GitHub Actions**. Jedes `git push` aktualisiert die Live-Systeme.

---

## Verzeichnisstruktur unter der Lupe

### `.github/workflows/`
Enthält die **CI/CD-Logik**. Die Datei `deploy.yml` steuert den automatischen Build-Prozess und verteilt die Apps je nach Branch auf die Produktions- oder Entwicklungsumgebung von GitHub Pages.

### `lib/` (Kern der Anwendung)
*   **`main_staff.dart` & `main_customer.dart`**: Die Startpunkte für die beiden spezialisierten Apps.
*   **`shared/services/sync_service.dart`**: Die Verbindung zwischen Isar und Supabase. Kümmert sich um den Datenabgleich und Realtime-Updates.
*   **`shared/models/`**: Definition des DataModels, die in der DB und im UI genutzt werden.
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
    Hinterlege in deinem Repository unter *Settings > Secrets > Actions*

## Entwicklung & Deployment

### Lokal Testen
Die App nutzt lokal standardmäßig das **Checket-Dev** Projekt.
```bash
# Mitarbeiter-App
flutter run -d chrome -t lib/main_staff.dart

# Kunden-App
flutter run -d chrome -t lib/main_customer.dart
```

### Deployment (Automatisch)
Das Deployment erfolgt über GitHub-Action:

*   **Entwicklung**: Push auf den Branch `dev`. Die App ist unter `.../checket_app/dev/` erreichbar.
*   **Produktion**: Push auf den Branch `main`. Die App ist unter der Haupt-URL erreichbar.

---

## 🔗 Live Umgebungen (GitHub Pages)

*   **Produktion (Mitarbeiter):** `https://<dein-nutzer>.github.io/checket_app/staff/`
*   **Produktion (Kunden):** `https://<dein-nutzer>.github.io/checket_app/`
*   **Entwicklung (Mitarbeiter):** `https://<dein-nutzer>.github.io/checket_app/dev/staff/`
*   **Entwicklung (Kunden):** `https://<dein-nutzer>.github.io/checket_app/dev/`
