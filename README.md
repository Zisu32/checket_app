# Checket - Smart Wardrobe System

Checket ist ein digitales Garderoben-Management-System, das physische Garderobenmarken durch digitale Tickets ersetzt. Es ist als **Progressive Web App (PWA)** konzipiert und nutzt eine **Local-First-Architektur** mit Drift (SQLite) und Supabase.

## Features

* **Mitarbeiter-Dashboard**: Echtzeit-Übersicht über alle Bügel als Grid (paginiert, 100 Plätze/Seite), Status-Verwaltung (Check-in, Bezahlung, temporärer Ausgang, Check-out).
* **Zwei-Tab-Arbeitsplatz**: Das Dashboard steuert einen zweiten, dauerhaft offenen Browser-Tab ("Checket Monitor"), der dem Kunden QR-Code und Bügelnummer zeigt. Beide Tabs kommunizieren live über `BroadcastChannel` (siehe [Zwei-Tab-Architektur](#zwei-tab-architektur-dashboard--qr-monitor)).
* **Digitales Kunden-Ticket**: Web-Ansicht für Kunden mit Live-Updates via lokalem Drift-Cache + Supabase-Realtime-Abgleich im Hintergrund.
* **Fundbüro (Lost & Found)**: Beim Schichtende werden offene, bezahlte Jacken automatisch archiviert; Mitarbeiter können sie später einzeln aushändigen und als abgeholt markieren.
* **Local-First Sync**: Abgleich durch Drift-Cache (SQLite); automatischer Abgleich mit der Cloud-Supabase inkl. Realtime-Subscriptions auf Garderobe und Fundbüro.
* **Stripe Payment**: Edge Function zur Zahlungsabwicklung (`supabase/functions/stripe-checkout`); im UI zusätzlich Bar- und Kontaktlos-Zahlung.
* **Push-Benachrichtigungen**: Kunden-Ansicht fragt Browser-Notification-Berechtigung an, um an die Jacke zu erinnern.

## Architektur & Konzept

Checket nutzt ein modernes Cloud-Native-Setup:

* **Frontend (PWA)**: Entwickelt mit Flutter Web, zwei getrennte Einstiegspunkte (`main_staff.dart`, `main_customer.dart`). Gehostet auf **GitHub Pages**. Installierbar auf Android, Windows und iOS für ein natives App-Gefühl.
* **Data Layer (Hybrid)**:
    * **Drift Database**: Speicher (SQLite via WASM) im Browser, getrennte Datenbanken pro App (`checket_staff_db`, `checket_customer_db`).
    * **Supabase**: Agiert als "Source of Truth" (`checket_garderobe`, `checket_lost_found`) und liefert Realtime-Events, auf die `SyncService` reagiert und den lokalen Cache neu befüllt.
* **Tab-zu-Tab-Kommunikation**: Innerhalb der Staff-App kommunizieren Dashboard-Tab und QR-Monitor-Tab über `BroadcastChannel`, unabhängig vom Supabase-Sync.
* **CI/CD**: Vollautomatisches Deployment über **GitHub Actions**. Jeder Push auf `main` oder `dev` baut Kunden- und Staff-App getrennt und deployt sie nach GitHub Pages.

---

## Verzeichnisstruktur unter der Lupe

### `.github/workflows/`
Enthält die **CI/CD-Logik**. `deploy.yml` baut bei jedem Push auf `main` oder `dev`:
1. lädt die für Drift auf Web benötigten Binaries (`sqlite3.wasm`, `drift_worker.js`) direkt in `web/`,
2. setzt je nach Branch die passenden Supabase-Secrets und den `--base-href` (Produktion: `/`, Entwicklung: `/dev/`),
3. baut Kunden-App (`main_customer.dart`) und Staff-App (`main_staff.dart`, unter `.../staff/`) getrennt,
4. deployt beide nebeneinander in den `gh-pages`-Branch, ohne bestehende Umgebungen zu überschreiben (`clean: false`).

### `lib/` (Kern der Anwendung)
* **`main_staff.dart`**: Einstiegspunkt der Mitarbeiter-App. Initialisiert Supabase + `SyncService`, zeigt Splash/Fehlerbildschirm während der Initialisierung, und routet per `onGenerateRoute` zwischen Dashboard (`/`) und QR-Monitor (`/qr`, hashbasiert).
* **`main_customer.dart`**: Einstiegspunkt der Kunden-App. Initialisiert Supabase + eigenen `SyncService`-Cache, liest Ticket-`id`/`secret` aus Query-Parametern oder Hash-Fragment und fällt bei fehlenden Parametern auf `localStorage` zurück (Wiedererkennung auf demselben Gerät).
* **`shared/database/database.dart`**: Definition der Drift-Datenbank und Tabellen (`WardrobeSlots`, `LostItems`). Die zugehörigen Datenklassen werden automatisch in `database.g.dart` generiert (`build_runner`).
* **`shared/services/sync_service.dart`**: Singleton, verbindet lokale Drift-DB mit Supabase. Zieht bei Init und bei Realtime-Events Garderobe (`checket_garderobe`) und Fundbüro (`checket_lost_found`), schreibt lokal per Batch-Insert, hält `slotsNotifier`/`errorNotifier`/`statusNotifier` (online/syncing/offline) aktuell und stellt `watchSlots()`, `watchLostItems()` sowie `watchTicket(id, secret)` (Ticket-Lebenszyklus für die Kunden-Ansicht) als Streams bereit.
* **`shared/services/monitor_service.dart`**: Singleton-Wrapper um einen `BroadcastChannel('checket_monitor_sync')`. Erlaubt dem Dashboard-Tab, dem QR-Monitor-Tab live `{id, secret}` zu senden (`updateMonitor`), und dem Monitor-Tab, diese Nachrichten als Stream zu empfangen (`onUpdate`). Details zum Zusammenspiel siehe unten.
* **`shared/theme/brand_colors.dart`**: Zentrale Farbdefinitionen für alle Status (aktiv, unbezahlt, temporär, vergessen, frei) sowie Hintergrund-/Oberflächenfarben, damit Dashboard, QR-Monitor und Kunden-Ticket konsistent aussehen.
* **`staff_app/views/dashboard_view.dart`**: Das Grid-UI des Garderoben-Managers. Öffnet pro Bügel ein Action-Sheet (einchecken, bezahlen, temporärer Ausgang, auschecken, Ticket wiederherstellen), verwaltet Fundbüro-Ansicht und Schichtende-Dialog (inkl. Sperre bei offenen unbezahlten Jacken) und steuert über `_syncMonitor()` den QR-Monitor-Tab.
* **`staff_app/views/qr_display_view.dart`**: Die zweite Ansicht der Staff-App, läuft im separaten "Checket Monitor"-Tab. Zeigt Bügelnummer + QR-Code für den aktuell aktiven Vorgang oder einen generischen "Ticket wiederherstellen"-Code, und aktualisiert sich per `MonitorService.onUpdate`.
* **`customer_app/views/webticket_view.dart`**: Die Ticket-Ansicht für den Kunden. Abonniert `SyncService.watchTicket(id, secret)`, zeigt animierten Status (aktiv, unbezahlt, temporär draußen, im Fundbüro, abgeholt, Bügel frei), fragt optional Push-Berechtigung an und persistiert `id`/`secret` in `localStorage`, damit der Kunde die Seite ohne Query-Parameter erneut öffnen kann.

### `supabase/` (Backend-Infrastruktur)
* **`functions/stripe-checkout/`**: Edge Function für die serverseitige Stripe-Zahlungsabwicklung.
* **`config.toml`**: Verknüpfung des lokalen Projekts mit der Supabase-Cloud.

### `web/` (Web-Plattform Konfiguration)
* **`manifest.json`**: Die PWA-Konfiguration (Icons, Start-URL, Farben für den Homescreen).
* **`index.html`**: HTML-Grundgerüst mit `$FLUTTER_BASE_HREF`-Platzhalter, der beim Build durch `--base-href` ersetzt wird; lädt `flutter_bootstrap.js`.
* **`sqlite3.wasm`, `drift_worker.js`**: Werden nicht eingecheckt, sondern bei jedem CI-Build frisch heruntergeladen (siehe `deploy.yml`).

### `assets/images/`
Enthält `full-icon.png`, das App-Logo, das in Dashboard, QR-Monitor und Kunden-Ticket als Header verwendet wird (mit Text-Fallback, falls das Bild nicht lädt).

---

## Zwei-Tab-Architektur: Dashboard & QR-Monitor

Die Staff-App läuft bewusst in zwei getrennten Browser-Tabs:

1. **Dashboard-Tab** (Titel *"Checket Staff"*) – die eigentliche Bedienoberfläche für das Personal.
2. **Monitor-Tab** (Titel *"Checket Monitor"*, Named Window `checket_monitor`, Route `#/qr`) – wird dem Kunden zugewandt aufgestellt und zeigt nur Bügelnummer + QR-Code.

Ist der Tab bereits offen, wird er nur fokussiert/aktualisiert statt neu geladen – dadurch bleibt der bereits registrierte `BroadcastChannel`-Listener aktiv und empfängt die Nachricht direkt.
* Bei "Ticket wiederherstellen" läuft derselbe Mechanismus, nur mit der Sonder-Payload `{id: -1, secret: 'recovery'}`. `QrDisplayView` erkennt diesen Fall (`isRecovery`) und zeigt einen QR-Code auf die reine Basis-URL ohne `id`/`secret` – die Kunden-App fällt dann auf ihren eigenen `localStorage` zurück und zeigt das zuletzt bekannte Ticket auf demselben Gerät wieder an.

## Status-Modell eines Garderobenplatzes

Ein `WardrobeSlot` durchläuft je nach Aktion folgende Status:

| Status | Bedeutung | Ausgelöst durch |
|---|---|---|
| `free` | Bügel ist frei | Auschecken, Schichtende-Reset |
| `unpaid` | Zahlung ausstehend | "Jacke einchecken" |
| `active` | Bezahlt, Jacke hängt | Bar/Kontaktlos-Zahlung |
| `temporary` | Kunde vorübergehend draußen | "Temporärer Ausgang" |
| `forgotten` | Jacke im Fundbüro | Schichtende-Archivierung |
| `picked_up` | Jacke bereits abgeholt | Nach Fundbüro-Aushändigung / neuem Zyklus auf demselben Bügel |
| `wrong_secret` | Secret passt nicht mehr zum aktuellen Vorgang | Erkannt von `watchTicket()` in der Kunden-Ansicht |

---

## Installation & Setup

1. **Repository klonen:**
```bash
    git clone
    cd checket_app
```

2. **Abhängigkeiten installieren:**
```bash
    flutter pub get
```

3. **Drift-Codegenerierung ausführen** (nötig nach Änderungen an `database.dart`):
```bash
    dart run build_runner build --delete-conflicting-outputs
```

4. **GitHub Secrets einrichten:**
   Hinterlege in deinem Repository unter *Settings > Secrets > Actions*:
    * `SUPABASE_URL_PROD` & `SUPABASE_ANON_KEY_PROD`
    * `SUPABASE_URL_DEV` & `SUPABASE_ANON_KEY_DEV`

## Entwicklung & Deployment

### Lokal Testen
Die App nutzt lokal standardmäßig das **Checket-Dev** Projekt. Für Web-Entwicklung wird der WASM-Renderer empfohlen. Supabase-URL/Key müssen lokal per `--dart-define` mitgegeben werden, sonst bricht die Initialisierung mit *"Konfiguration fehlt"* ab:
```bash
# Mitarbeiter-App
flutter run -d chrome -t lib/main_staff.dart --wasm \
  --dart-define=SUPABASE_URL=<dev-url> \
  --dart-define=SUPABASE_ANON_KEY=<dev-anon-key>

# Kunden-App
flutter run -d chrome -t lib/main_customer.dart --wasm \
  --dart-define=SUPABASE_URL=<dev-url> \
  --dart-define=SUPABASE_ANON_KEY=<dev-anon-key>
```

### Deployment (Automatisch)
Das Deployment erfolgt über GitHub Actions (`deploy.yml`):

* **Entwicklung**: Push auf den Branch `dev` → Deployment unter `/dev/`.
* **Produktion**: PullRequest von `dev` nach Prüfung.

Pro Branch werden Kunden- und Staff-App als zwei separate Flutter-Web-Builds erzeugt und in `deploy_out/` zusammengeführt, bevor sie gemeinsam nach `gh-pages` gepusht werden. Ein `DB_VERSION`-Timestamp wird bei jedem Build mitgegeben (Cache-Busting für den lokalen Drift-Speicher).

---

## 🔗 Live Umgebungen (GitHub Pages)

* **Produktion (Kunden):** `https://<dein-nutzer>.github.io/checket_app/`
* **Produktion (Mitarbeiter, Dashboard):** `https://<dein-nutzer>.github.io/checket_app/staff/`
* **Entwicklung (Kunden):** `https://<dein-nutzer>.github.io/checket_app/dev/?id=5&secret=test`
* **Entwicklung (Mitarbeiter, Dashboard):** `https://<dein-nutzer>.github.io/checket_app/dev/staff/`