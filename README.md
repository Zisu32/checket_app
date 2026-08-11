# Checket - Smart Wardrobe System

Checket ist ein digitales Garderoben-Management-System, das physische Garderobenmarken durch digitale Tickets ersetzt. Es ist als **Progressive Web App (PWA)** konzipiert und nutzt eine **Local-First-Architektur** mit Drift (SQLite) und Supabase.

## Features

* **Mitarbeiter-App**: Echtzeit-Übersicht über alle Bügel mit modernem Swipe-Interface und Status-Verwaltung (Check-in, Bezahlung, temporärer Ausgang, Check-out).
* **Zwei-Tab-System**: Ein separater Kunden-Tab ("Checket QR"), der live über `BroadcastChannel` aktualisiert wird. Die URL bleibt dabei sauber (`#/qr`) und verbirgt sensible Ticket-Daten.
* **Digitales Kunden-Ticket**: Web-Ansicht für Gäste mit Live-Status (animiert) und optionaler Wallet-Integration (Apple/Google).
* **Intelligentes Fundbüro**: Automatisierte Archivierung von Jacken am Schichtende mit einfacher Aushändigungs-Logik.
* **Local-First Sync**: Volle Offline-Fähigkeit (Durch lokalen Drift-Cache; automatischer Hintergrund-Abgleich mit Supabase Realtime.
* **Sicherheits-Check**: Integrierte Sperre am Schichtende, falls noch unbezahlte Jacken im System sind.
* **SumUp Cloud Integration**: Direkte Ansteuerung des **SumUp Solo** Terminals über das Dashboard (Cloud API).
* **Zur Wallet-Hinzufügen**: Webticket kann zur Wallet hinzugefügt werden, sodass eine Push-Benachrichtigung gesendet werden kann, falls der Kunde die Jacke vergisst.

---

## Architektur & Konzept

Checket nutzt eine **Split-App-Architektur**, bei der zwei spezialisierte Flutter-Anwendungen auf derselben Datenbasis operieren, aber für unterschiedliche Zielgruppen optimiert sind.

### Die zwei Einstiegspunkte (`lib/`)

*   **`main_staff.dart` (Mitarbeiter-App)**:
    *   **Zweck**: Operative Steuerung der Garderobe.
    *   **Funktionen**: Dashboard-Grid, Fundbüro-Verwaltung, Schicht-Reset.
    *   **Tab-Handling**: Öffnet und steuert den QR-Monitor über einen Browser-internen Nachrichtenkanal (`BroadcastChannel`).
*   **`main_customer.dart` (Kunden-App)**:
    *   **Zweck**: Digitaler Beleg für den Gast.
    *   **Funktionen**: Live-Statusanzeige der eigenen Jacke, Wallet-Integration.
    *   **Persistence**: Nutzt `localStorage`, um das Ticket auch ohne URL-Parameter beim Neuladen (z.B. als PWA) wiederzufinden.

### Wie alles zusammenhängt

Obwohl es zwei getrennte Anwendungen sind, bilden sie ein geschlossenes System:

1.  **Gemeinsame Datenbasis**: Beide Apps sind mit demselben **Supabase-Backend** verbunden. Wenn ein Mitarbeiter im Dashboard einen Bügel als "Bezahlt" markiert, aktualisiert sich das Kundenticket in Echtzeit via Realtime-Subscription.
2.  **Geteilte Logik (`lib/shared/`)**: Beide Apps nutzen den identischen `SyncService` und das gleiche Datenbank-Schema (Drift). Dies garantiert eine konsistente Interpretation von Statuswerten (z.B. "Jacke im Fundbüro") im gesamten System.
3.  **Einheitliches Design**: Durch die zentrale `AppTheme` Klasse und die geteilten `widgets/` (Splash, Error-Screens) fühlen sich beide Anwendungen für den Nutzer wie eine einzige, konsistente Marke an.
4.  **Integriertes Deployment**: GitHub Actions baut beide Apps in einem Durchgang. Die Kunden-App landet im Hauptverzeichnis (`/`), während die Mitarbeiter-App unter `/staff/` abgelegt wird.

### Verzeichnisstruktur (Inside `lib/`)

#### `shared/` (Zentrales Fundament)
*   **`database/`**: Definition des Drift-Schemas (`database.dart`) und generierter SQLite-Code.
*   **`services/`**: Plattformunabhängige Logik (Synchronisation, Routing, Tab-Kommunikation, SumUp API).
*   **`theme/`**: Das visuelle Herzstück (`app_theme.dart`). Hier liegen alle Farben, Schriftgrößen und der zentrale Button-Builder.

#### `widgets/` (Globale UI-Bausteine)
Infrastruktur-Widgets, die beide Apps beim Booten teilen (Splash-Screen, Fehlerbehandlung, Fatal-Error-Debugger).

#### `staff_app/` (Workspace für Mitarbeiter)
*   **`views/`**: Die Hauptbildschirme (`StaffView`, `QrDisplayView`).
*   **`views/tabs/`**: Die Module der Navbar (Dashboard, Fundbüro, Schichtende).
*   **`widgets/`**: Spezifische Bedienelemente wie das Aktionsmenü für Bügel oder die Navigationsleiste.

#### `customer_app/` (Webticket)
*   **`views/`**: Die Ticket-Hauptansicht.
*   **`widgets/`**: Ticket-spezifische UI-Komponenten (Animierte Kachel, Wallet-Integration).

---

## Zwei-Tab-Architektur: Dashboard & QR-Monitor

Die Staff-App nutzt zwei synchronisierte Browser-Tabs für eine professionelle Kassen-Situation:

1. **Dashboard-Tab**: Die Bedienoberfläche für das Personal auf dem Hauptbildschirm.
2. **Monitor-Tab** (`/qr`): Wird dem Kunden zugewandt und zeigt nur Bügelnummer + QR-Code.

### Kommunikation
* **Saubere Adresszeile**: Der Monitor-Tab zeigt in der Adresszeile keine sensiblen Daten (ID/Secret) an.
* **Intelligente Wiederherstellung**: Die Daten fließen sicher über den **BroadcastChannel**. Bei einem Refresh (**F5**) stellt der Monitor den letzten Zustand automatisch aus dem `localStorage` wieder her.
* **Routing-Sicherheit**: Der `RouteService` erkennt die QR-Ansicht zuverlässig anhand des Pfades, unabhängig von URL-Parametern.

---

## Entwicklung & Deployment

### Lokal Testen
Die Keys müssen lokal per `--dart-define` mitgegeben werden:
```bash
# Mitarbeiter-App
flutter run -d chrome -t lib/main_staff.dart \
  --dart-define=SUPABASE_URL=<dev-url> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<dev-key>

# Kunden-App
flutter run -d chrome -t lib/main_customer.dart \
  --dart-define=SUPABASE_URL=<dev-url> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<dev-key>
```

### Deployment (Automatisch)
Das Deployment erfolgt über GitHub Actions (`deploy.yml`) bei jedem Push auf `dev` oder Pull-Request auf `main`. Die App wird automatisch für GitHub Pages optimiert gebaut und unter der passenden Base-HREF veröffentlicht.

---

## Live Umgebungen (GitHub Pages)
* **Produktion:** `https://<github-user>.github.io/checket_app/`
* **Entwicklung:** `https://<github-user>..github.io/checket_app/dev/`
