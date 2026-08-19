# Checket - Smart Wardrobe System

Checket ist ein digitales Garderoben-Management-System, das physische Garderobenmarken durch digitale Tickets ersetzt. Es ist als **Progressive Web App (PWA)** konzipiert und nutzt eine **SaaS-fähige Multi-Tenant-Architektur** mit einer Kombination aus lokaler Speicherung (Drift/SQLite) und einer Mandantentrennung auf Datenbank-Ebene (PostgreSQL Schemas).

## Features

* **Mitarbeiter-App**: Echtzeit-Übersicht über alle Bügel mit modernem Swipe-Interface und Status-Verwaltung (Check-in, Bezahlung, temporärer Ausgang, Check-out).
* **Zwei-Tab-System**: Ein separater Kunden-Tab ("Checket QR"), der live über `BroadcastChannel` aktualisiert wird. Die URL bleibt dabei sauber (`#/qr`) und verbirgt sensible Ticket-Daten.
* **Digitales Kunden-Ticket**: Web-Ansicht für Gäste mit Live-Status (animiert) und optionaler Wallet-Integration (Apple/Google).
* **Intelligentes Fundbüro**: Automatisierte Archivierung von Jacken am Schichtende mit einfacher Aushändigungs-Logik.
* **Local-First Sync**: Volle Offline-Fähigkeit durch lokalen Drift-Cache; automatischer Hintergrund-Abgleich mit Supabase Realtime.
* **Sicherheits-Check**: Integrierte Sperre am Schichtende, falls noch unbezahlte Jacken im System sind.
* **SumUp Cloud Integration**: Direkte Ansteuerung des **SumUp Solo** Terminals über das Dashboard (Cloud API).
* **Mandantenfähige Einstellungen**: Passwortgeschützter Bereich zur Verwaltung von Arbeitsplätzen, SumUp-Keys und individuellen Ticketpreisen pro Terminal.
* **Zur Wallet-Hinzufügen**: Webticket kann zur Wallet hinzugefügt werden, sodass eine Push-Benachrichtigung gesendet werden kann, falls der Kunde die Jacke vergisst.

---

## Architektur & Konzept

Checket nutzt eine **Split-App-Architektur**, bei der zwei spezialisierte Flutter-Anwendungen auf derselben Datenbasis operieren, aber für unterschiedliche Zielgruppen optimiert sind.

### Die zwei Einstiegspunkte (`lib/`)

*   **`main_staff.dart` (Mitarbeiter-App)**: Operative Steuerung der Garderobe.
*   **`main_customer.dart` (Kunden-App)**: Digitaler Beleg für den Gast mit Live-Statusanzeige. Nutzt `localStorage`, um das Ticket auch ohne URL-Parameter beim Neuladen wiederzufinden.

### Multi-Tenant Architektur

Das System ist als Software-as-a-Service (SaaS) aufgebaut. Jeder Kunde (Mandant) erhält ein eigenes, isoliertes Datenbankschema in der PostgreSQL-Instanz.

1.  **Isolierte Schemas**: Jeder Mandant nutzt ein eigenes Schema (z.B. `tenant_club_a`), das die Tabellen `checket_garderobe`, `checket_lost_found` und `checket_terminal_assignments` enthält.
2.  **Zentrale Verwaltung**: Das `public`-Schema enthält die globale Tabelle `tenants` und die Zuweisung von Benutzern zu ihren jeweiligen Schemas.
3.  **Sicherheit**: Der Zugriff wird über Row Level Security (RLS) gesteuert, wobei das System das Schema dynamisch basierend auf dem JWT des angemeldeten Benutzers wechselt.

### Projektstruktur (`lib/`)

*   **`shared/database`** : Definition des Drift-Schemas und generierter SQLite-Code.
*   **`shared/services/`** : Plattformunabhängige Logik
    *   `sync_service.dart`: Cloud-Synchronisation zur DB & Realtime.
    *   `route_service.dart`: Zentrales URL-Parsing & State-Recovery.
    *   `monitor_service.dart`: Kommunikation zwischen Dashboard und Monitor.
    *   `sumup_service.dart`: Brücke zur SumUp Cloud API.
*   **`shared/theme/`**: Das visuelle Herzstück mit Farben und dem zentralen Button-Builder.
*   **`widgets/`** : Globale UI-Widgets (Splash, Error-Screens).
*   **`staff_app/`**: Workspace für die Mitarbeiter-Anwendung.
*   **`customer_app/`**: Workspace für das Gäste-Portal.

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


## Einrichtung & Deployment

Dank der **Supabase-GitHub-Integration** werden die Edge Functions bei jedem `git push` auf den `dev` Branch automatisch aktualisiert. Zudem läuft jede Änderung, die über `git push` auf den `dev` Branch eingespielt wurde, automatisch durch die GitHub-Action Pipline die das Deployment über GH-Pages übernimmt.

### 1. Datenbank-Setup (Supabase)
Um die Infrastruktur für die Mandantenfähigkeit vorzubereiten, muss das SQL-Skript `multi_tenant_setup.sql` im Supabase SQL Editor ausgeführt werden.

> [!IMPORTANT]
> **Manueller Schritt nach Erstellung eines Mandanten:**
> Jedes Mal, wenn ein neues Mandanten-Schema (z.B. `tenant_mein_club`) angelegt wurde, muss dieses manuell in den API-Einstellungen von Supabase freigegeben werden:
> 1. Gehe in der Supabase-Konsole zu **Integration** -> **Data API**.
> 2. Klicke auf **Settings**.
> 3. Scrolle zu **Exposed schemas**.
> 4. Füge den Namen deines neuen Schemas zur Liste hinzu.
> 5. Klicke auf **Save**.

### 2. SumUp Solo Einrichtung
1.  Logge dich auf [me.sumup.com](https://me.sumup.com) ein.
2.  **API-Key**: Gehe zu **Einstellungen > Für Entwickler** und generiere einen **Personal Access Token** (Static API Key).
3.  **Merchant Code**: Notiere dir deine Händlernummer (zu finden unter **Profil > Profil-Details**).
4.  **Affiliate Key**: Gehe zu **Einstellungen > Für Entwickler >** und generiere einen Affiliate Key.

### 3. Admin-Seite hinterlegen

Die erstellten Keys müssen über die Admin-Oberfläche noch eingetragen werden

---

## Live Umgebungen (Custom Domain)
* **Produktion (Mitarbeiter-Dashboard):** `https://checket.eu/staff/`
* **Entwicklung (Mitarbeiter-Dashboard):** `https://checket.eu/dev/staff/`
