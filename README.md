# Checket - Smart Wardrobe System

Checket ist ein digitales Garderoben-Management-System, das physische Garderobenmarken durch digitale Tickets ersetzt. Es ist als **Progressive Web App (PWA)** konzipiert und nutzt eine **SaaS-fähige Multi-Tenant-Architektur** mit einer Kombination aus lokaler Speicherung (Drift/SQLite) und einer Mandantentrennung auf Datenbank-Ebene (PostgreSQL Schemas).

## Features

* **Mitarbeiter-App**: Echtzeit-Übersicht über alle Bügel mit modernem Swipe-Interface und Status-Verwaltung (Check-in, Bezahlung, temporärer Ausgang, Check-out).
* **Zwei-Tab-System**: Ein separater Kunden-Tab ("Checket QR"), der live über `BroadcastChannel` aktualisiert wird. Die URL bleibt dabei sauber (`#/qr`) und verbirgt sensible Ticket-Daten.
* **Digitales Kunden-Ticket**: Web-Ansicht für Gäste mit Live-Status (animiert) und optionaler Wallet-Integration (Apple/Google).
* **Intelligentes Fundbüro**: Automatisierte Archivierung von Jacken am Schichtende mit einfacher Aushändigungs-Logik.
* **Platform-Administration**: Zentrale Verwaltung von Tenants, deren SumUp-Konfigurationen und der Benutzerverwaltung.
* **Local-First Sync**: Volle Offline-Fähigkeit durch lokalen Drift-Cache; automatischer Hintergrund-Abgleich mit Supabase Realtime.
* **Sicherheits-Check**: Integrierte Sperre am Schichtende, falls noch unbezahlte Jacken im System sind.
* **SumUp Cloud Integration**: Direkte Ansteuerung des **SumUp Solo** Terminals über das Dashboard (Cloud API).
* **Setting-Bereich**: Passwortgeschützter Bereich zur Verwaltung von Benutzerdaten sowie Arbeitsplätzen und individuellen Ticketpreisen pro Terminal.
* **Zur Wallet-Hinzufügen**: Webticket kann zur Wallet hinzugefügt werden, sodass eine Push-Benachrichtigung gesendet werden kann, falls der Kunde die Jacke vergisst.

---

## Architektur & Konzept

Checket nutzt eine **Split-App-Architektur**, bei der spezialisierte Flutter-Einstiegspunkte auf derselben Datenbasis operieren, aber für unterschiedliche Zielgruppen optimiert sind.

### Einstiegspunkte (`lib/`)

*   **`main_staff.dart`**: Der zentrale Hub für Personal und Admins.
    *   **Staff-Bereich** (`/staff`): Operative Steuerung der Garderobe.
    *   **Admin-Bereich** (`/#/admin`): Plattformverwaltung für System-Admins.
*   **`main_customer.dart`**: Das Gäste-Portal für digitale Belege.

### Multi-Tenant Architektur

Das System ist als Software-as-a-Service (SaaS) aufgebaut. Jeder Kunde (Mandant) erhält ein eigenes, isoliertes Datenbankschema in der PostgreSQL-Instanz.

1.  **Isolierte Schemas**: Jeder Tenant nutzt ein eigenes Schema (z.B. `tenant_club_a`), das die benötigten Tabellen enthält.
2.  **Zentrale Verwaltung**: Das `public`-Schema enthält die globale Tabelle `tenants` und die Zuweisung von Benutzern zu ihren jeweiligen Schemas.
3.  **Sicherheit**: Der Zugriff wird über Row Level Security (RLS) gesteuert. Der Einstellungsbereich und die Admin-App sind zusätzlich durch Re-Authentifizierung geschützt.

### Projektstruktur (`lib/`)

*   **`shared/`**: Gemeinsam genutzte Ressourcen für alle App-Teile.
    *   `database/`: Definition des Drift-Schemas und generierter SQLite-Code.
    *   `services/`: Plattformunabhängige Logik (Sync, Routing, SumUp).
    *   `views/`: Geteilte Views.
    *   `widgets/`: Wiederverwendbare UI-Komponenten.
*   **`admin_app/`**: Workspace für die Plattform-Verwaltung.
    *   `views/tabs/`: Verwaltung von Tenants und Usern.
    *   `widgets/`: Spezifische Bedienelemente.
*   **`staff_app/`**: Workspace für die operative Mitarbeiter-Anwendung.
    *   `views/`: Die Hauptansichten.
    *   `views/tabs/`: Dashboard, Fundbüro, Schichtende und Setting-Bereich.
    *   `widgets/`: Spezifische Bedienelemente.

*   **`customer_app/`**: Workspace für das Gäste-Portal.
    *   `views/`: Die Hauptansicht.
    *   `widgets/`: Spezifische Bedienelemente.

### Wie alles zusammenhängt

Obwohl es getrennte Bereiche sind, bilden sie ein geschlossenes System:

1.  **Gemeinsame Datenbasis**: Alle Apps sind mit demselben **Supabase-Backend** verbunden. Der `SyncService` erkennt automatisch das zugewiesene Schema des angemeldeten Benutzers.
2.  **Einheitliches Design**: Durch die zentrale `AppTheme`-Klasse und die geteilten `shared/widgets` fühlen sich alle Anwendungen konsistent an.

---

## Einrichtung & Deployment

Dank der **Supabase-GitHub-Integration** werden die Edge Functions bei jedem `git push` auf den `dev` Branch automatisch aktualisiert. Zudem läuft jede Änderung, die über `git push` auf den `dev` Branch eingespielt wurde, automatisch durch die GitHub-Action Pipline die das Deployment über GH-Pages übernimmt.

### 1. Datenbank-Setup (Supabase)
Um die Infrastruktur vorzubereiten, muss das SQL-Skript `multi_tenant_setup.sql` im Supabase SQL Editor ausgeführt werden.

> [!IMPORTANT]
> **Manueller Schritt nach Erstellung eines Mandanten:**
> Jedes Mal, wenn ein neues Mandanten-Schema (z.B. `tenant_mein_club`) angelegt wurde, muss dieses manuell in den API-Einstellungen von Supabase freigegeben werden:
> 1. Gehe in der Supabase-Konsole zu **Integration** -> **Data API**.
> 2. Klicke auf **Settings**.
> 3. Scrolle zu **Exposed schemas**.
> 4. Füge den Namen des neuen Schemas zur Liste hinzu.
> 5. Klicke auf **Save**.

### 2. SumUp Solo Einrichtung
1.  Logge dich auf [me.sumup.com](https://me.sumup.com) ein.
2.  **API-Key**: Gehe zu **Geschäftseinstellungen > Für Entwickler** und generiere einen API-Key.
3.  **Merchant Code**: Notiere dir deine Händlernummer (zu finden unter **Profil > Profil-Details**).
4.  **Affiliate Key**: Gehe zu **Geschäftseinstellungen > Für Entwickler >** und generiere einen Affiliate-Key.
5.  **Terminal kopplen mit SumUp**: Gehe zu **Geschäftseinstellungen > Cloud-API** und registiere dein Terminal
6.  **Kopple via Cloud-API**: Hinterlege die Keys im **Admin-Bereich** der App des jeweiligen Tenants.

### 3. Edge Functions
Stelle sicher, dass die Edge Functions korrekt deployt sind (normalerweise automatisch über GH-Actions)

---

## Live Umgebungen (Custom Domain)
* **Produktion (Mitarbeiter-Dashboard):** `https://checket.eu/staff/`
* **Entwicklung (Mitarbeiter-Dashboard):** `https://checket.eu/dev/staff/`