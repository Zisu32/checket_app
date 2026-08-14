# Checket - Smart Wardrobe System

Checket ist ein digitales Garderoben-Management-System, das physische Garderobenmarken durch digitale Tickets ersetzt. Es ist als **Progressive Web App (PWA)** konzipiert und nutzt eine **Local-First-Architektur** mit Drift (SQLite) und Supabase.

## Features

* **Mitarbeiter-App**: Echtzeit-Übersicht über alle Bügel mit modernem Swipe-Interface und Status-Verwaltung (Check-in, Bezahlung, temporärer Ausgang, Check-out).
* **Zwei-Tab-System**: Ein separater Kunden-Tab ("Checket QR"), der live über `BroadcastChannel` aktualisiert wird. Die URL bleibt dabei sauber (`#/qr`) und verbirgt sensible Ticket-Daten.
* **Digitales Kunden-Ticket**: Web-Ansicht für Gäste mit Live-Status (animiert) und optionaler Wallet-Integration (Apple/Google).
* **Intelligentes Fundbüro**: Automatisierte Archivierung von Jacken am Schichtende mit einfacher Aushändigungs-Logik.
* **Local-First Sync**: Volle Offline-Fähigkeit durch lokalen Drift-Cache; automatischer Hintergrund-Abgleich mit Supabase Realtime.
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

*   **`shared/database`** : Definition des Drift-Schemas und generierter SQLite-Code.
*   **`shared/services/`** : Plattformunabhängige Logik
    *   `sync_service.dart`: Cloud-Synchronisation zur DB & Realtime.
    *   `route_service.dart`: Zentrales URL-Parsing & State-Recovery.
    *   `monitor_service.dart`: Kommunikation zwischen Dashboard und Monitor.
    *   `sumup_service.dart`: Brücke zur SumUp Cloud API.
    *   `platform_hints_service.dart`: Geräte-Erkennung (iOS/Android).
*   **`shared/theme/`**: Das visuelle Herzstück. Hier liegen alle Farben, Schriftgrößen und der zentrale Button-Builder.

#### `widgets/` : Globale UI-Widgets, die beide Apps beim Booten teilen.

#### `staff_app/` Workspace für Mitarbeiter
*   **`views/`**: Die Hauptbildschirme.
*   **`views/tabs/`**: Die Tab-Views der Navbar.
*   **`widgets/`**: Spezifische Bedienelemente.

#### `customer_app/` Gäste-Portal
*   **`views/`**: Der Einstiegspunkt für Kunden.
*   **`widgets/`**: Ticket-spezifische UI-Komponenten.

### Wie alles zusammenhängt

Obwohl es zwei getrennte Anwendungen sind, bilden sie ein geschlossenes System:

1.  **Gemeinsame Datenbasis**: Beide Apps sind mit demselben **Supabase-Backend** verbunden. Wenn ein Mitarbeiter im Dashboard einen Bügel als "Bezahlt" markiert, aktualisiert sich das Kundenticket in Echtzeit via Realtime-Subscription.
2.  **Geteilte Logik (`lib/shared/`)**: Beide Apps nutzen den identischen `SyncService`, `SumUpService` und das gleiche Datenbank-Schema (Drift). Dies garantiert eine konsistente Interpretation von Statuswerten und des Bezahlstatus im gesamten System.
3.  **Einheitliches Design**: Durch die zentrale `AppTheme` Klasse und die geteilten `widgets/` (Splash, Error-Screens) fühlen sich beide Anwendungen für den Nutzer wie eine einzige, konsistente Marke an.
4.  **Integriertes Deployment**: GitHub Actions baut beide Apps in einem Durchgang. Die Kunden-App landet im Hauptverzeichnis (`/`), während die Mitarbeiter-App unter `/staff/` abgelegt wird.

---

## SumUp Solo Einrichtung & Cloud API

Um das physische **SumUp Solo** Terminal direkt aus dem Dashboard anzusteuern, folge dieser Anleitung:

### 1. Vorbereitung im SumUp Dashboard
1.  Logge dich auf [me.sumup.com](https://me.sumup.com) ein.
2.  **API-Key**: Gehe zu **Einstellungen > Für Entwickler** und generiere einen **Personal Access Token** (Static API Key).
3.  **Merchant Code**: Notiere dir deine Händlernummer (zu finden unter **Profil > Profil-Details**).
4.  **Affiliate Key**: Gehe zu **Einstellungen > Für Entwickler >** und generiere einen Affiliate Key.

### 2. Terminal koppeln (Cloud-API)
Um das Terminal mit deinem Account zu verknüpfen, ohne manuell API-Befehle zu senden:
1.  Melde dich im [me.sumup.com](https://me.sumup.com) an.
2.  Gehe zu den [Geschäftseinstellungen](https://me.sumup.com/de-de/settings?tab=business).
3.  Klicke unter **"Für Entwickler:innen"** auf den Menüpunkt **"Cloud-API"**.
4.  Wähle **"Kartenterminal hinzufügen"**.
5.  **Am SumUp Solo**: 
    *   Schalte das Gerät ein. 
    *   Melde dich ab, falls du noch mit einem Benutzerkonto eingeloggt bist (Einstellungen > Info > Abmelden).
    *   Baue eine neue WLAN-Verbindung auf.
    *   Wähle im Verbindungsmenü **"Cloud-API"** aus.
    *   Gib den am Terminal angezeigten Code auf der SumUp Webseite ein.

### 3. Supabase Secrets setzen
Hinterlege die Daten sicher in deinen Supabase-Projekten (Dev & Prod):
```bash
supabase secrets set SUMUP_API_KEY
supabase secrets set SUMUP_MERCHANT_CODE
supabase secrets set SUMUP_AFFILIATE_KEY
```

### 4. Preis anpassen

Aus Sicherheitsgründen wird der Zahlbetrag für die Garderobe ausschließlich im **Backend** verwaltet. Dies verhindert, dass Nutzer den Preis im Browser manipulieren können.

Um den Preis zu ändern:
1.  Öffne die Datei: `supabase/functions/sumup-terminal-pay/index.ts`.
2.  Suche die Zeile `amount:`.
3.  Ändere den Wert und speichere die Datei.
4.  Push den Code zu GitHub. Das Deployment erfolgt automatisch (siehe unten).

---

## Entwicklung & Maintenance

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

### Automatisches Deployment (Edge Functions)
Dank der nativen **Supabase-GitHub-Integration** werden die Edge Functions (`sumup-terminal-pay`, `generate-wallet-pass`, `sync-wallet-pass`) bei jedem `git push` auf den `dev` Branch automatisch aktualisiert.

*   **Wichtig**: Damit neue Funktionen vom System erkannt werden, müssen sie zwingend in der Datei **`supabase/config.toml`** unter `[functions.name]` registriert sein.
*   **Trigger**: Das Deployment startet automatisch, sobald Änderungen innerhalb des Ordners **`/supabase/functions`** erkannt werden.

### Datenbank aktiv halten (Keep-Alive)
Supabase pausiert kostenlose Projekte nach 7 Tagen Inaktivität. Checket verfügt über einen automatisierten "Herzschlag" (**`supabase_keep_alive.yml`**), der alle 3 Tage einen Ping an deine Dev- und Prod-Datenbanken sendet, um diese dauerhaft wach zu halten.️

---

## Live Umgebungen (Custom Domain)
* **Produktion (Mitarbeiter-Dashboard):** `https://checket.eu/staff/`
* **Entwicklung (Mitarbeiter-Dashboard):** `https://checket.eu/dev/staff/`

---
