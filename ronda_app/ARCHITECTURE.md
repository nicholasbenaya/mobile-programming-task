# Technical Architecture & FE/BE Contract: RondaDigital (`ronda_app/`)

This document is the binding engineering contract between the **Back End Agent** and **Front End Agent** inside JSM HQ. Both agents build against the exact data models, SQL schema, RPC signatures, repository interfaces, and folder boundaries specified here so parallel PRs integrate cleanly.

---

## 1. High-Level System Architecture

```text
+-------------------------------------------------------------------------+
|                    Flutter Mobile Client (ronda_app/)                   |
|  - Presentation Layer (Material 3 Light/Dark, go_router, Riverpod)      |
|  - Interactive Map (flutter_map + latlong2) & Roster (table_calendar)   |
|  - Capture Pipeline: mobile_scanner -> live camera -> JPEG compress     |
|    -> SHA-256 hash + GPS/isMocked forensic bundle                       |
|  - Offline Persistence: sqflite queue + background/manual SyncWorker    |
|  - Push Receiver: firebase_messaging + flutter_local_notifications      |
+--------------------+----------------------------------+-----------------+
                     | HTTPS / PostgREST / RPC / Storage | Realtime WSS
                     v                                  v
+-------------------------------------------------------------------------+
|                        Supabase Managed Cloud                           |
|  - Supabase Auth (Email + Password)                                     |
|  - PostgreSQL + Row-Level Security (100% multi-tenant via site_id)      |
|  - Security-Definer RPCs:                                               |
|      create_site_with_admin, join_site_by_code,                         |
|      submit_patrol_checkin (Auto Integrity Engine),                     |
|      review_patrol_checkin (Manual Admin Audit Override),               |
|      accept_shift_swap (Atomic Swap + Collision Check)                  |
|  - Private Storage Bucket: patrol-evidence                              |
|  - Edge Functions:                                                      |
|      dispatch-sos-alert  ---> FCM HTTP v1 API ---> Guard/Admin Devices  |
|      escalate-stale-sos  ---> Auto-escalate unacknowledged SOS          |
+-------------------------------------------------------------------------+
```

---

## 2. Folder Structure & Strict FE / BE Ownership

```text
ronda_app/
├── assets/
│   ├── fonts/                        # [FE] Bundled Plus Jakarta Sans (3 weights) + JetBrains Mono (1 weight)
│   └── audio/                        # [FE] Short SOS alarm tone (<= 80 KB .ogg/.mp3)
├── supabase/
│   ├── migrations/                   # [BE] Ordered idempotent SQL migrations (0001..0006)
│   ├── functions/
│   │   ├── dispatch-sos-alert/       # [BE] Deno Edge Function -> FCM HTTP v1 dispatch
│   │   └── escalate-stale-sos/       # [BE] Deno Edge Function -> SLA auto-escalation
│   └── README.md                     # [BE] Setup & deployment instructions (no secrets)
├── lib/
│   ├── main.dart                     # [SHARED - P1 scaffold] Entrypoint, Firebase/Supabase init
│   ├── app.dart                      # [FE] MaterialApp.router, ThemeMode provider, locale id_ID
│   ├── core/
│   │   ├── config/                   # [BE] Env (--dart-define), Supabase & FCM config helpers
│   │   ├── errors/                   # [BE] AppFailure sealed classes & error mappers
│   │   ├── theme/                    # [FE] AppColors, AppTheme (light/dark), ThemeExtension
│   │   ├── router/                   # [FE] go_router routes, auth/site/role guards, SOS deep link
│   │   └── utils/                    # [BE/FE] Date/WIB formatters, CSV builder, QR payload codec
│   ├── domain/                       # [BE] Pure Dart entities, enums, verification engine, repo interfaces
│   │   ├── models/                   #      Site, Membership, Checkpoint, Shift, Checkin, Sos, Report, EmptyHouse
│   │   ├── repositories/             #      Abstract repository interfaces (contract for FE providers!)
│   │   └── services/                 #      Haversine, QrCodec, AutoVerificationRules, ShiftCollisionRules
│   ├── data/                         # [BE] Concrete implementations of domain/repositories
│   │   ├── local/                    #      sqflite database helper, offline queue DAO, photo file store
│   │   ├── remote/                   #      Supabase DTO mappers, Storage upload/signed URL service, FCM token sync
│   │   ├── repositories/             #      Supabase + Offline-aware repository implementations
│   │   └── services/                 #      LocationService (anti-mock), ForensicPhotoService (compress + SHA-256), SyncWorker
│   ├── providers/                    # [FE] Riverpod providers & controllers wired to domain/repositories
│   └── presentation/                 # [FE] Feature-first UI (max ~350 lines per file)
│       ├── shared/                   #      AppShells, StatusBadge, StateViews (Empty/Loading/Error), ForensicStrip
│       ├── auth/                     #      Login, Register, Site Onboarding & Switcher
│       ├── map/                      #      PatrolMapScreen, CheckpointSheet, AdminCheckpointEditor, QrPosterExport
│       ├── checkin/                  #      QrScanScreen, ForensicCameraScreen, CheckinConfirmSheet, AdminAuditList, AdminAuditDetail
│       ├── schedule/                 #      ScheduleCalendarScreen, SwapRequestSheet, HandoverTab (Buku Mutasi)
│       ├── sos/                      #      SosHoldButton, ActiveSosBanner, SosDetailTracker
│       ├── reports/                  #      IncidentListScreen, CreateIncidentScreen, EmptyHouseScreen
│       └── admin/                    #      ComplianceDashboardScreen, ExportReportSheet, SiteMembersSettingsScreen
└── test/
    ├── unit/                         # [BE] Domain rules, Haversine, Auto-Verification, SQLite queue tests
    └── widget/                       # [FE] Critical screen, theme, and state widget tests
```

---

## 3. Approved Dependency Manifest (Anti-Bloat Budget)

Target release APK (`arm64-v8a`, `--split-per-abi --tree-shake-icons`): **<= 25 MB**.

| Package | Purpose | Size Impact | Approved? |
| :--- | :--- | :--- | :---: |
| `supabase_flutter` | Auth, PostgREST, Storage, Realtime | Medium (core backend) | YES |
| `flutter_riverpod` | Manual state management (no codegen/build_runner) | Tiny (pure Dart) | YES |
| `go_router` | Declarative RBAC routing & SOS deep links | Tiny (pure Dart) | YES |
| `flutter_map` + `latlong2` | Interactive OpenStreetMap patrol & audit mini-maps | Tiny (pure Dart) | YES |
| `table_calendar` | Interactive roster & shift swap calendar | Tiny (pure Dart) | YES |
| `mobile_scanner` | Real-time QR code scanning with torch control | Medium (CameraX/MLKit) | YES |
| `qr_flutter` | Rendering & exporting printable checkpoint QR posters | Tiny (pure Dart) | YES |
| `image_picker` | Live camera capture (`ImageSource.camera`) & report photos | Small (OS camera intent) | YES |
| `flutter_image_compress` | Native JPEG compression (<= 1600px, q=78) before hashing | Small (OS codecs) | YES |
| `geolocator` | GPS position, accuracy, and `isMocked` anti-spoofing | Small (OS location API) | YES |
| `sqflite` + `path` + `path_provider` | Persistent offline queue using OS-native SQLite | Tiny (OS SQLite) | YES |
| `connectivity_plus` | Detect online return to trigger `SyncWorker` | Tiny | YES |
| `crypto` + `uuid` | SHA-256 photo hash, HMAC QR check, idempotent UUIDs | Tiny (pure Dart) | YES |
| `intl` | `id_ID` date/time formatting | Tiny (pure Dart) | YES |
| `firebase_core` + `firebase_messaging` | High-priority background SOS alarm delivery | Medium (required for SOS) | YES |
| `flutter_local_notifications` | Android high-importance alarm channel & foreground alert banner | Small | YES |
| `pdf` + `share_plus` | Pure-Dart PDF report/QR poster generation + OS share sheet | Small (~250 KB pure Dart) | YES |

### Explicitly Banned Packages (Without Lead + User Approval)
- `google_maps_flutter`, `mapbox_maps_flutter` (large native SDKs + paid API keys)
- `sqlite3_flutter_libs` (bundles ~4 MB native SQLite binary when `sqflite` already uses OS SQLite)
- `google_fonts` (prefer local bundled `.ttf` for offline reliability and determinism)
- `syncfusion_*`, `getwidget`, `flutter_screenutil` (UI bloat; Material 3 + `DESIGN.md` tokens cover all needs)
- `sensors_plus`, `flutter_compass`, `battery_plus` (not needed unless explicitly requested later)
- `freezed` / `build_runner` / `riverpod_generator` (avoid codegen overhead across parallel multi-agent branches; use clean immutable Dart classes)

---

## 4. Multi-Tenant PostgreSQL Database Schema (Supabase)

All migrations live in `ronda_app/supabase/migrations/` and must be idempotent.

### 4.1 Tables Overview

1. **`profiles`** (1:1 with `auth.users`)
   - `id uuid primary key references auth.users(id) on delete cascade`
   - `full_name text not null`
   - `phone_whatsapp text not null`
   - `created_at timestamptz not null default now()`
2. **`sites`** (Multi-tenant organizations: village, housing estate, RT/RW, facility)
   - `id uuid primary key default gen_random_uuid()`
   - `name text not null`
   - `site_type text not null check (site_type in ('desa','perumahan','rt_rw','klaster','fasilitas','lainnya'))`
   - `address_summary text not null default ''`
   - `invite_code text not null unique` (8-char uppercase alphanumeric, regeneratable by admin)
   - `require_join_approval boolean not null default true`
   - `center_lat double precision not null`
   - `center_lng double precision not null`
   - `default_geofence_m integer not null default 30 check (default_geofence_m between 10 and 200)`
   - `sos_escalation_minutes integer not null default 3 check (sos_escalation_minutes between 1 and 30)`
   - `created_by uuid not null references profiles(id)`
   - `created_at timestamptz not null default now()`
3. **`site_memberships`** (Source of truth for multi-tenant RBAC)
   - `id uuid primary key default gen_random_uuid()`
   - `site_id uuid not null references sites(id) on delete cascade`
   - `user_id uuid not null references profiles(id) on delete cascade`
   - `role text not null check (role in ('admin','officer','resident'))`
   - `status text not null default 'pending' check (status in ('pending','active','suspended'))`
   - `unit_address text not null default ''`
   - `joined_at timestamptz not null default now()`
   - `unique (site_id, user_id)`
4. **`checkpoints`** (Physical patrol points with revocable signed QR)
   - `id uuid primary key default gen_random_uuid()`
   - `site_id uuid not null references sites(id) on delete cascade`
   - `code text not null` (e.g., `POS-01`, unique per `site_id`)
   - `name text not null`
   - `description text not null default ''`
   - `latitude double precision not null`
   - `longitude double precision not null`
   - `radius_m integer not null default 30 check (radius_m between 10 and 200)`
   - `sort_order integer not null default 0`
   - `target_time_local text` (optional `HH:mm`, e.g., `'22:30'`)
   - `qr_token_version integer not null default 1`
   - `qr_secret text not null` (random 32-char hex generated server-side; **hidden from resident queries via view/column security or RPC verification only**)
   - `is_active boolean not null default true`
   - `created_at timestamptz not null default now()`
   - `unique (site_id, code)`
5. **`shift_templates`**
   - `id uuid primary key default gen_random_uuid()`
   - `site_id uuid not null references sites(id) on delete cascade`
   - `name text not null` (e.g., `'Shift Malam'`, `'Shift Sore'`)
   - `start_time time not null`
   - `end_time time not null`
   - `is_overnight boolean not null default false`
   - `is_active boolean not null default true`
6. **`patrol_schedules`**
   - `id uuid primary key default gen_random_uuid()`
   - `site_id uuid not null references sites(id) on delete cascade`
   - `officer_id uuid not null references profiles(id) on delete cascade`
   - `template_id uuid references shift_templates(id) on delete set null`
   - `shift_name text not null`
   - `shift_date date not null`
   - `starts_at timestamptz not null`
   - `ends_at timestamptz not null`
   - `status text not null default 'scheduled' check (status in ('scheduled','completed','absent','swapped'))`
   - `created_at timestamptz not null default now()`
7. **`shift_swaps`**
   - `id uuid primary key default gen_random_uuid()`
   - `site_id uuid not null references sites(id) on delete cascade`
   - `schedule_id uuid not null references patrol_schedules(id) on delete cascade`
   - `requester_id uuid not null references profiles(id)`
   - `target_officer_id uuid not null references profiles(id)`
   - `target_schedule_id uuid references patrol_schedules(id)` (optional reciprocal shift swap)
   - `reason text not null`
   - `status text not null default 'pending' check (status in ('pending','accepted','rejected','expired','admin_overridden'))`
   - `expires_at timestamptz not null` (computed as `schedule.starts_at - interval '3 hours'`)
   - `responded_at timestamptz`
   - `created_at timestamptz not null default now()`
   - Partial unique index: `unique (schedule_id) where status = 'pending'` (enforces single-pending rule!).
8. **`shift_handovers`** (Buku Mutasi / Serah Terima Shift)
   - `id uuid primary key default gen_random_uuid()`
   - `site_id uuid not null references sites(id) on delete cascade`
   - `from_schedule_id uuid references patrol_schedules(id) on delete set null`
   - `author_id uuid not null references profiles(id)`
   - `summary text not null`
   - `asset_status text not null default ''` (e.g., keys, gate locks, flashlight)
   - `photo_path text`
   - `acknowledged_by uuid references profiles(id)`
   - `acknowledged_at timestamptz`
   - `client_event_id uuid unique`
   - `created_at timestamptz not null default now()`
9. **`patrol_checkins`** (Forensic Check-In + Dual Verification)
   - `id uuid primary key default gen_random_uuid()`
   - `client_event_id uuid not null unique` (idempotency key for offline retries)
   - `site_id uuid not null references sites(id) on delete cascade`
   - `checkpoint_id uuid not null references checkpoints(id) on delete cascade`
   - `schedule_id uuid references patrol_schedules(id) on delete set null`
   - `officer_id uuid not null references profiles(id)`
   - `qr_token_version_scanned integer not null`
   - `photo_path text not null` (private storage path in `patrol-evidence`)
   - `photo_sha256 text not null` (64-char hex digest computed at capture time)
   - `captured_at_client timestamptz not null`
   - `synced_at_server timestamptz not null default now()`
   - `latitude double precision not null`
   - `longitude double precision not null`
   - `accuracy_m double precision not null`
   - `distance_m double precision not null` (computed server-side via Haversine)
   - `is_mocked boolean not null default false`
   - `is_offline_submission boolean not null default false`
   - `device_model text`
   - `officer_note text not null default ''`
   - `auto_status text not null check (auto_status in ('auto_verified','flagged_review','auto_rejected'))`
   - `flag_reasons text[] not null default '{}'`
   - `manual_status text check (manual_status in ('manual_approved','manual_rejected'))`
   - `reviewed_by uuid references profiles(id)`
   - `reviewed_at timestamptz`
   - `review_note text`
   - `effective_status text generated always as (coalesce(manual_status, auto_status)) stored`
   - `created_at timestamptz not null default now()`
10. **`checkin_audit_logs`** (Immutable audit trail for automated checks & admin manual overrides)
    - `id uuid primary key default gen_random_uuid()`
    - `checkin_id uuid not null references patrol_checkins(id) on delete cascade`
    - `site_id uuid not null references sites(id) on delete cascade`
    - `actor_id uuid references profiles(id)` (`null` for automated system evaluation)
    - `action text not null check (action in ('auto_evaluated','manual_approved','manual_rejected'))`
    - `previous_status text`
    - `new_status text not null`
    - `note text not null`
    - `created_at timestamptz not null default now()`
11. **`sos_events`**
    - `id uuid primary key default gen_random_uuid()`
    - `site_id uuid not null references sites(id) on delete cascade`
    - `reporter_id uuid not null references profiles(id)`
    - `category text not null default 'darurat' check (category in ('pencurian','kebakaran','medis','orang_mencurigakan','darurat'))`
    - `latitude double precision not null`
    - `longitude double precision not null`
    - `address_note text not null default ''`
    - `note text not null default ''`
    - `status text not null default 'open' check (status in ('open','acknowledged','on_scene','resolved','cancelled_false_alarm'))`
    - `triggered_at timestamptz not null default now()`
    - `escalated_at timestamptz`
    - `responder_id uuid references profiles(id)`
    - `acknowledged_at timestamptz`
    - `on_scene_at timestamptz`
    - `resolved_at timestamptz`
    - `resolution_note text`
    - `resolution_photo_path text`
    - `cancel_reason text`
12. **`incident_reports`** (Non-SOS security & facility reports)
    - `id uuid primary key default gen_random_uuid()`
    - `client_event_id uuid unique`
    - `site_id uuid not null references sites(id) on delete cascade`
    - `reporter_id uuid not null references profiles(id)`
    - `category text not null check (category in ('orang_mencurigakan','kerusakan_fasilitas','lampu_mati','vandalisme','kebersihan','lainnya'))`
    - `title text not null`
    - `description text not null`
    - `photo_path text not null`
    - `latitude double precision not null`
    - `longitude double precision not null`
    - `status text not null default 'open' check (status in ('open','in_progress','resolved','rejected'))`
    - `handled_by uuid references profiles(id)`
    - `resolution_note text`
    - `created_at timestamptz not null default now()`
    - `updated_at timestamptz not null default now()`
13. **`empty_house_watches`** (Lapor Mudik / Rumah Kosong)
    - `id uuid primary key default gen_random_uuid()`
    - `site_id uuid not null references sites(id) on delete cascade`
    - `resident_id uuid not null references profiles(id)`
    - `house_label text not null`
    - `latitude double precision not null`
    - `longitude double precision not null`
    - `start_date date not null`
    - `end_date date not null check (end_date >= start_date)`
    - `emergency_contact text not null`
    - `notes text not null default ''`
    - `status text not null default 'active' check (status in ('active','returned','cancelled'))`
    - `created_at timestamptz not null default now()`
14. **`device_tokens`** (FCM tokens for background SOS alarms)
    - `id uuid primary key default gen_random_uuid()`
    - `user_id uuid not null references profiles(id) on delete cascade`
    - `fcm_token text not null unique`
    - `platform text not null check (platform in ('android','ios'))`
    - `updated_at timestamptz not null default now()`

---

## 5. Multi-Tenant Row-Level Security (RLS) & Privacy Rules

Create `SECURITY DEFINER` helper functions in SQL migration `0002_rls_helpers.sql` (`set search_path = public`):
- `is_active_site_member(p_site_id uuid) returns boolean`
- `current_site_role(p_site_id uuid) returns text`
- `is_site_admin(p_site_id uuid) returns boolean`
- `is_site_staff(p_site_id uuid) returns boolean` (`role in ('admin','officer')`)

### Strict Privacy Guarantees
- Every table has `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.
- **Cross-tenant isolation:** A user can NEVER read or mutate rows for a `site_id` where they are not an `active` member in `site_memberships`.
- **Empty House privacy (`empty_house_watches`):** `SELECT` policy allows ONLY `resident_id = auth.uid()` OR `is_site_staff(site_id)`. Other residents receive 0 rows.
- **QR secret protection:** Residents never read `checkpoints.qr_secret`. Admin QR generation uses a dedicated view/RPC (`get_checkpoint_qr_payload`) restricted to `is_site_admin(site_id)`.
- **Audit immutability:** `checkin_audit_logs` permits `SELECT` for `is_site_staff(site_id)` and blocks direct `UPDATE`/`DELETE` from all authenticated clients; inserts happen strictly inside `submit_patrol_checkin` and `review_patrol_checkin` RPCs.
- **Private Storage (`patrol-evidence`):** Path format `<site_id>/<folder>/<auth.uid()>/<uuid>.jpg` where `<folder>` is `checkins | incidents | sos | handovers`. Storage `SELECT` checks `(storage.foldername(name))[1]::uuid` belongs to the user's active site (with `checkins`/`handovers` restricted to `is_site_staff`).

---

## 6. Authoritative Server RPCs & Edge Functions

### 6.1 Postgres RPCs
1. `create_site_with_admin(p_name, p_site_type, p_address, p_center_lat, p_center_lng, p_radius_m) -> sites`: Creates site with random unique 8-char `invite_code` and inserts caller as `active` `admin` in `site_memberships` atomically.
2. `join_site_by_code(p_invite_code, p_unit_address) -> site_memberships`: Looks up site by code, inserts membership (`status = 'pending'` if `require_join_approval` else `'active'`, `role = 'resident'`).
3. `submit_patrol_checkin(p_payload jsonb) -> patrol_checkins`:
   - Idempotent on `client_event_id` (returns existing row if already synced).
   - Verifies caller is active `officer` (or `admin` with scheduled shift) in `site_id`.
   - Verifies QR HMAC signature against `checkpoints.qr_secret` and `qr_token_version`.
   - Recomputes Haversine distance server-side.
   - Evaluates automated rules (`QR_INVALID_OR_REVOKED`, `MOCK_GPS_DETECTED`, `OUTSIDE_GEOFENCE_EXTREME`, `OUTSIDE_GEOFENCE_BORDERLINE`, `LOW_GPS_ACCURACY`, `OUTSIDE_SHIFT_WINDOW`, `OFFLINE_DELAY_OR_CLOCK_SKEW`, `PHOTO_HASH_MISSING_OR_MISMATCH`).
   - Inserts into `patrol_checkins` + `checkin_audit_logs` (`action = 'auto_evaluated'`).
4. `review_patrol_checkin(p_checkin_id uuid, p_decision text, p_review_note text) -> patrol_checkins`:
   - Requires `is_site_admin(site_id)` and non-empty `p_review_note` (min 5 chars).
   - Updates `manual_status`, `reviewed_by`, `reviewed_at`, `review_note` and appends immutable `checkin_audit_logs` entry.
5. `accept_shift_swap(p_swap_id uuid) -> shift_swaps`:
   - Verifies caller is `target_officer_id`, swap is `pending`, and `now() < expires_at`.
   - Checks officer collision on target date, swaps `patrol_schedules.officer_id` atomically, marks swap `accepted`.

### 6.2 Supabase Edge Functions (FCM SOS Pipeline)
- **`dispatch-sos-alert`:** Triggered after `sos_events` insert (via client call or DB webhook). Queries all active `officer` and `admin` `device_tokens` for `site_id`, sends **FCM HTTP v1** message with:
  - Android: `priority: "high"`, `channel_id: "rondadigital_sos_alarm"`, custom alarm sound, deep-link data `{ "type": "sos", "sos_id": "...", "site_id": "..." }`.
  - iOS: `apns-priority: "10"`, interruption-level `time-sensitive`.
- **`escalate-stale-sos`:** Invoked by scheduled cron (every 1 minute via Supabase pg_cron or Edge cron) to find `sos_events` where `status = 'open' AND escalated_at IS NULL AND now() >= triggered_at + (sites.sos_escalation_minutes || ' minutes')::interval`, sets `escalated_at = now()`, and re-dispatches escalated FCM alarm to all site Admins and Officers.

---

## 7. Offline-First SQLite (`sqflite`) Architecture

Local SQLite file: `rondadigital_offline.db` (managed by Back End in `lib/data/local/`).

### Local Tables
- `offline_checkin_queue`: Stores `client_event_id` (PK), `site_id`, `checkpoint_id`, `schedule_id`, `qr_raw_payload`, `local_photo_path`, `photo_sha256`, `captured_at_client`, `monotonic_ms`, `latitude`, `longitude`, `accuracy_m`, `is_mocked`, `officer_note`, `sync_state` (`pending | uploading_photo | submitting | synced | failed`), `retry_count`, `last_error`.
- `offline_report_queue` and `offline_handover_queue`: Same durable pattern with `client_event_id` PK and `local_photo_path`.

### `SyncWorker` Lifecycle
1. Runs on app launch, whenever `connectivity_plus` reports network restoration, and on manual tap (`Sinkronkan Sekarang`).
2. Processes items FIFO: uploads local compressed JPEG to `patrol-evidence` (idempotent path `<site_id>/checkins/<uid>/<client_event_id>.jpg`), then invokes `submit_patrol_checkin`.
3. Marks row `synced` and deletes temporary local photo copy only after server returns `200`. Exponential backoff on transient errors (`5s, 15s, 45s, max 5m`).

---

## 8. Dart Repository Interfaces (Contract for Front End Providers)

Back End defines these abstract interfaces under `lib/domain/repositories/` in Phase 2 (`P2-T01`) before parallel UI work begins:
- `AuthSiteRepository`: auth state stream, signIn/signUp/signOut, listMySites, createSite, joinSiteByCode, updateSiteSettings, manageMembers.
- `CheckpointRepository`: watchCheckpoints, create/update/deactivateCheckpoint, regenerateQrToken, getAdminQrPayload.
- `CheckinRepository`: captureAndSubmitCheckin (online + offline fallback), watchShiftCheckins, watchPendingOfflineCount, syncNow, fetchAuditQueue (filterable by `auto_status`/`manual_status`), getEvidenceSignedUrl, reviewCheckinManual, fetchCheckinAuditLogs.
- `ScheduleRepository`: watchSchedules, generateAutoSchedule, assignManualShift, requestShiftSwap, respondShiftSwap, watchHandovers, submitHandover, acknowledgeHandover.
- `SosRepository`: triggerSos, watchActiveSos, watchSosHistory, acknowledgeSos, markOnScene, resolveSos, cancelFalseAlarm, registerDeviceFcmToken.
- `ReportRepository`: watchIncidentReports, submitIncidentReport, updateReportStatus, watchEmptyHouseWatches, createEmptyHouseWatch, markResidentReturned.
- `ComplianceRepository`: fetchMonthlySummary, exportCheckinsCsv, exportMonthlySummaryPdf.

---

## 9. Environment & Secret Configuration Contract

Runtime Flutter variables passed via `--dart-define-from-file=.env.local` (never committed):
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Supabase Edge Function secrets (configured in Supabase Dashboard / CLI, never in client app):
- `FIREBASE_PROJECT_ID`
- `FIREBASE_SERVICE_ACCOUNT_JSON` (for FCM HTTP v1 OAuth2 token signing)

Android/iOS local Firebase files (gitignored; setup documented in `ronda_app/supabase/README.md` and requested via JSM HQ `ask_user` when needed):
- `ronda_app/android/app/google-services.json`
- `ronda_app/ios/Runner/GoogleService-Info.plist`
