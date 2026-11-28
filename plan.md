# RondaDigital (Multi-Tenant): Engineering Plan (JSM HQ)

> **Important for JSM HQ:** This root `plan.md` is the master planning brief for the PM/Lead agent. **Never** create or manually edit `docs/plan.md` (JSM HQ overwrites `docs/plan.md` automatically when plan export is enabled).
>
> **Required reading before creating boards or starting any task:**
> - `ROLE.md`: Global JSM HQ guardrails, FE/BE ownership, anti-bloat policy, and PR rules
> - `ronda_app/PRD.md`: Product scope, forensic photo check-in + dual verification rules, and acceptance criteria
> - `ronda_app/DESIGN.md`: Civic Operational design tokens (Light & Dark, WCAG AA verified) and screen map
> - `ronda_app/ARCHITECTURE.md`: Multi-tenant PostgreSQL schema, RLS, RPCs, FCM alarm contract, SQLite offline sync, and approved packages

---

## Project Overview & JSM HQ Team Setup

- **Active Directory:** `ronda_app/` (legacy `Tugas-1/` through `Tugas-5/` are read-only and must never be modified)
- **Stack:** Flutter (Android primary, iOS compatible) + Supabase (PostgreSQL, RLS, Auth, Storage, Realtime, Edge Functions) + Firebase Cloud Messaging (FCM) for high-priority SOS alarms + `sqflite` for offline persistence
- **Recommended 3-Agent Team in JSM HQ (Settings -> Team):**
  1. **PM / Lead (`lead`, `isLead: true`):** Product Manager & Lead Architect. Creates boards/tasks from this plan, assigns parallel BE/FE tasks, coordinates contract alignment, and decides PR merge order. Never writes app code.
  2. **Back End (`backend`):** Supabase SQL/RLS/RPCs, Edge Functions (FCM), Flutter `domain/`, `data/` (repositories, `sqflite` offline queue, forensic photo/GPS services), and `test/unit/`.
  3. **Front End (`frontend`):** Flutter `core/theme/`, `core/router/`, `providers/`, `presentation/` (all screens/widgets following `DESIGN.md`), `assets/`, and `test/widget/`.
- **Workflow Rules:**
  - **One task = one branch = one PR** titled `[TASK-ID] Short descriptive title`.
  - Workers may edit **only** the files listed under `Files` for their assigned task.
  - Every Flutter PR must pass `flutter analyze` (0 errors/warnings) and `flutter test` inside `ronda_app/`.

---

## Phase 1: Project Scaffold, Theme Foundation & Database Migrations (`P1`)

> **Goal:** Establish a clean Flutter workspace in `ronda_app/`, complete multi-tenant Supabase SQL migrations, and lock down the Light/Dark Material 3 theme before feature development fans out in parallel.

### `P1-T01` : Scaffold Clean Flutter App & Approved Dependencies
- **Role:** Back End
- **Needs:** none
- **Files:** `ronda_app/pubspec.yaml`, `ronda_app/analysis_options.yaml`, `ronda_app/.gitignore`, `ronda_app/.env.example`, `ronda_app/android/**`, `ronda_app/ios/**`, `ronda_app/lib/main.dart`, `ronda_app/lib/core/config/env.dart`, `ronda_app/lib/core/errors/app_failure.dart`
- **Description:** Initialize a fresh Flutter project inside `ronda_app/` (`flutter create --org id.rondadigital --project-name ronda_app .`). Configure `pubspec.yaml` strictly using the Approved Dependency Manifest in `ronda_app/ARCHITECTURE.md` (zero banned bloat packages). Add `.gitignore` excluding `.env*`, `google-services.json`, `GoogleService-Info.plist`, and keystores. Create `.env.example` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`), `Env` reader using `String.fromEnvironment`, and typed `AppFailure` sealed error classes. Configure Android camera, fine location, and notification permissions.
- **Done when:** `flutter pub get` and `flutter analyze` succeed cleanly inside `ronda_app/` with zero warnings, and zero secrets are committed.

### `P1-T02` : Multi-Tenant Supabase SQL Migrations, RLS, Storage & RPCs
- **Role:** Back End
- **Needs:** `P1-T01`
- **Files:** `ronda_app/supabase/migrations/0001_core_multi_tenant.sql`, `ronda_app/supabase/migrations/0002_rls_helpers.sql`, `ronda_app/supabase/migrations/0003_patrol_checkins_audit.sql`, `ronda_app/supabase/migrations/0004_schedule_swap_handover.sql`, `ronda_app/supabase/migrations/0005_sos_reports_empty_house.sql`, `ronda_app/supabase/migrations/0006_storage_and_realtime.sql`, `ronda_app/supabase/README.md`
- **Description:** Write idempotent PostgreSQL migrations implementing all 14 tables, indexes, constraints, `SECURITY DEFINER` RLS helpers, strict `site_id` isolation (including Empty House privacy hiding resident pins from other residents), private `patrol-evidence` storage bucket RLS, `supabase_realtime` publication, and authoritative RPCs (`create_site_with_admin`, `join_site_by_code`, `get_checkpoint_qr_payload`, `submit_patrol_checkin` with Automated Integrity Engine, `review_patrol_checkin` with immutable `checkin_audit_logs`, and `accept_shift_swap`). Document step-by-step migration apply instructions in `ronda_app/supabase/README.md`. Call `ask_user` via PM/Lead when ready to apply migrations to the user's Supabase project.
- **Done when:** All 6 migration files are syntax-clean, idempotent, cover every table/RPC/RLS rule in `ronda_app/ARCHITECTURE.md`, and `supabase/README.md` documents deployment cleanly.

### `P1-T03` : Civic Operational Theme System, Fonts & Shared UI Primitives
- **Role:** Front End *(can run in parallel with `P1-T02`)*
- **Needs:** `P1-T01`
- **Files:** `ronda_app/pubspec.yaml` *(fonts section only, coordinate if needed)*, `ronda_app/assets/fonts/**`, `ronda_app/lib/app.dart`, `ronda_app/lib/core/theme/app_colors.dart`, `ronda_app/lib/core/theme/app_theme.dart`, `ronda_app/lib/core/theme/civic_tokens.dart`, `ronda_app/lib/presentation/shared/status_badge.dart`, `ronda_app/lib/presentation/shared/state_views.dart`, `ronda_app/lib/presentation/shared/forensic_strip.dart`, `ronda_app/test/widget/theme_and_shared_test.dart`
- **Description:** Bundle offline `Plus Jakarta Sans` (Regular/Medium/Bold) and `JetBrains Mono` (Regular) fonts. Implement exact Light Mode and Dark Mode `ColorScheme` and `CivicTokens` `ThemeExtension` matching every hex token in `ronda_app/DESIGN.md`. Build reusable non-color-only `StatusBadge` (icon + Indonesian label + verified/flagged/rejected/offline tint), actionable `StateViews` (Loading/Empty/Error), and `ForensicStrip` (monospaced coordinate/timestamp/hash display). Add widget tests verifying Light and Dark rendering without overflow.
- **Done when:** All hex tokens match `ronda_app/DESIGN.md`, `flutter analyze` and `flutter test test/widget/theme_and_shared_test.dart` pass with 0 warnings.

---

## Phase 2: Domain Contracts, Multi-Tenant Auth & Site Onboarding (`P2`)

> **Goal:** Lock down pure Dart domain contracts and repositories so Auth, Multi-Tenant Site creation/joining, and role-based shells work end-to-end.

### `P2-T01` : Domain Models, Integrity Rules Engine & Repository Interfaces
- **Role:** Back End
- **Needs:** `P1-T01`
- **Files:** `ronda_app/lib/domain/models/**`, `ronda_app/lib/domain/repositories/**`, `ronda_app/lib/domain/services/haversine_calculator.dart`, `ronda_app/lib/domain/services/qr_codec.dart`, `ronda_app/lib/domain/services/auto_verification_engine.dart`, `ronda_app/lib/domain/services/shift_collision_rules.dart`, `ronda_app/test/unit/domain/**`
- **Description:** Implement immutable domain entities for all 14 tables, `AutoVerificationEngine` (mirroring server rules for offline/pre-submit evaluation: geofence borderline vs extreme, low GPS accuracy, `isMocked`, shift window, clock skew), `QrCodec` (`RD1|<site_id>|<checkpoint_id>|<version>|<hmac>`), `HaversineCalculator`, `ShiftCollisionRules`, and all 7 abstract repository interfaces listed in `ronda_app/ARCHITECTURE.md` Section 8. Write comprehensive unit tests covering every edge case.
- **Done when:** All 7 repository contracts compile cleanly, unit tests pass 100% covering all automated verification rules and edge cases, and `flutter analyze` passes.

### `P2-T02` : Supabase Auth, Multi-Tenant Site & Checkpoint Repositories
- **Role:** Back End
- **Needs:** `P1-T02`, `P2-T01`
- **Files:** `ronda_app/lib/data/remote/supabase_client_provider.dart`, `ronda_app/lib/data/remote/dto_mappers.dart`, `ronda_app/lib/data/repositories/supabase_auth_site_repository.dart`, `ronda_app/lib/data/repositories/supabase_checkpoint_repository.dart`, `ronda_app/test/unit/data/auth_site_repository_test.dart`
- **Description:** Implement `AuthSiteRepository` (Email/Password auth, profile creation, `create_site_with_admin`, `join_site_by_code`, member approval/role management, site switching) and `CheckpointRepository` (Realtime stream, CRUD checkpoints, QR `token_version` regeneration, admin QR payload retrieval). Map all Supabase exceptions cleanly into `AppFailure`.
- **Done when:** Repositories satisfy domain contracts with typed error handling, unit tests pass, and `flutter analyze` exits 0.

### `P2-T03` : Routing, Auth/Onboarding Flows, Role Shells & Site Settings UI
- **Role:** Front End *(starts as soon as `P1-T03` and `P2-T01` merge)*
- **Needs:** `P1-T03`, `P2-T01`
- **Files:** `ronda_app/lib/core/router/app_router.dart`, `ronda_app/lib/providers/auth_site_providers.dart`, `ronda_app/lib/providers/theme_provider.dart`, `ronda_app/lib/presentation/shared/role_shell.dart`, `ronda_app/lib/presentation/auth/**`, `ronda_app/lib/presentation/admin/site_members_settings_screen.dart`, `ronda_app/test/widget/auth_onboarding_test.dart`
- **Description:** Implement `go_router` with auth, active-site, and role guards plus SOS deep-link route placeholder. Build Login/Register screens, Site Selector & Onboarding (`Buat Wilayah Baru` with map center picker, `Gabung Pakai Kode Undangan`), 4-tab role-scoped `NavigationBar` shells (`admin`, `officer`, `resident`) with responsive `NavigationRail` on >= 600 dp, Theme toggle (System/Light/Dark), and Admin Site Settings & Member Approval screen.
- **Done when:** Unauthenticated, no-site, pending-approval, and all 3 active role shells route cleanly with working Light/Dark modes and passing widget tests.

---

## Phase 3: Interactive Patrol Map, Forensic Check-In & Dual Verification Audit (`P3`)

> **Goal:** Deliver the flagship anti-fraud patrol workflow: interactive map, printable QR checkpoints, QR + mandatory live photo + forensic metadata check-in, SQLite offline persistence, and Admin manual audit override for false positives/negatives.

### `P3-T01` : Forensic Capture Services, SQLite Offline Queue & Check-In Repository
- **Role:** Back End
- **Needs:** `P1-T02`, `P2-T01`, `P2-T02`
- **Files:** `ronda_app/lib/data/services/location_service.dart`, `ronda_app/lib/data/services/forensic_photo_service.dart`, `ronda_app/lib/data/local/offline_database.dart`, `ronda_app/lib/data/local/offline_queue_dao.dart`, `ronda_app/lib/data/services/sync_worker.dart`, `ronda_app/lib/data/repositories/offline_checkin_repository.dart`, `ronda_app/test/unit/data/offline_checkin_queue_test.dart`
- **Description:** Build `LocationService` (high-accuracy GPS + `isMocked` detection), `ForensicPhotoService` (compress JPEG <= 1600px/q78 + compute SHA-256 hash + capture forensic metadata), `sqflite` persistent `OfflineDatabase` (`offline_checkin_queue`, `offline_report_queue`, `offline_handover_queue`), `SyncWorker` (connectivity listener + idempotent upload to `patrol-evidence` + `submit_patrol_checkin` RPC + exponential retry), and `CheckinRepository` (including Admin audit filter queries, signed evidence URL caching, `review_patrol_checkin` RPC, and `checkin_audit_logs` fetch).
- **Done when:** Offline queue persistence, idempotent sync, SHA-256 hashing, and manual review RPC calls are verified by unit tests with `flutter analyze` clean.

### `P3-T02` : Interactive Patrol Map, Admin Checkpoint CRUD & Printable QR Poster
- **Role:** Front End
- **Needs:** `P2-T03`, `P2-T02`
- **Files:** `ronda_app/lib/providers/map_checkpoint_providers.dart`, `ronda_app/lib/presentation/map/**`, `ronda_app/test/widget/patrol_map_test.dart`
- **Description:** Build the interactive `flutter_map` screen displaying site checkpoints (icon + status color + geofence circle), live GPS dot + recenter control, Checkpoint Detail bottom sheet with live distance & shift status, Admin tap-on-map Checkpoint Create/Edit sheet, QR token regeneration confirmation, and Printable QR Poster screen (renders site name, checkpoint code, location, and `qr_flutter` QR code, exportable as PNG/PDF via `share_plus`).
- **Done when:** Officers, Admins, and Residents see role-appropriate map views with working checkpoint sheets, Admin can CRUD checkpoints & export QR posters, and tests/analyze pass.

### `P3-T03` : Officer Dual-Step Forensic Check-In Flow & Offline Sync Indicator
- **Role:** Front End
- **Needs:** `P3-T01`, `P3-T02`
- **Files:** `ronda_app/lib/providers/checkin_providers.dart`, `ronda_app/lib/presentation/checkin/qr_scan_screen.dart`, `ronda_app/lib/presentation/checkin/forensic_camera_screen.dart`, `ronda_app/lib/presentation/checkin/checkin_confirm_sheet.dart`, `ronda_app/lib/presentation/checkin/offline_queue_sheet.dart`, `ronda_app/test/widget/forensic_checkin_flow_test.dart`
- **Description:** Implement the 3-step patrol check-in flow: (1) `mobile_scanner` QR viewfinder with torch toggle, (2) mandatory live camera capture (`ImageSource.camera`, no gallery picker) with live GPS accuracy & distance strip, (3) Forensic Confirmation Sheet showing photo thumbnail, monospaced metadata strip, automated pre-check verdict badge, optional note, and submit CTA (automatic online upload or offline SQLite queue). Add persistent pending-sync pill in Officer header opening `OfflineQueueSheet` with manual retry button.
- **Done when:** Officer cannot bypass live photo capture, forensic metadata renders cleanly in Light/Dark mode, offline fallback shows pending count, and widget tests/analyze pass.

### `P3-T04` : Admin Manual Audit Queue & Evidence Inspection Override UI
- **Role:** Front End *(can run in parallel with `P3-T03`)*
- **Needs:** `P3-T01`, `P2-T03`
- **Files:** `ronda_app/lib/providers/audit_providers.dart`, `ronda_app/lib/presentation/checkin/admin_audit_list_screen.dart`, `ronda_app/lib/presentation/checkin/admin_audit_detail_screen.dart`, `ronda_app/lib/presentation/checkin/manual_review_dialog.dart`, `ronda_app/test/widget/admin_audit_test.dart`
- **Description:** Build the Admin **Rekap & Audit Check-In** screen with filter chips (`Perlu Tinjauan`, `Ditolak Otomatis`, `Terverifikasi`, `Semua`) and date/officer filters. Build `AdminAuditDetailScreen` with zoomable evidence photo (`InteractiveViewer` + readable scrim), `flutter_map` mini-map comparing checkpoint radius vs officer GPS accuracy circle, complete forensic metadata table, automated `flag_reasons` list, immutable `checkin_audit_logs` timeline, and sticky **Tolak Manual** / **Setujui Manual (Override)** buttons requiring a mandatory audit note (min 5 chars).
- **Done when:** Admin can inspect full photo + spatial + forensic metadata and override false positives/negatives with audit trail reflection; responsive 2-column layout works on >= 600 dp; tests and `flutter analyze` pass.

---

## Phase 4: Interactive Schedule, Peer Shift Swaps & Buku Mutasi (`P4`)

> **Goal:** Replace manual chat coordination with a `table_calendar` roster, collision-safe auto-scheduler, peer-to-peer shift swaps, and structured shift handover notes.

### `P4-T01` : Schedule, Auto-Scheduler, Shift Swap & Handover Repository
- **Role:** Back End
- **Needs:** `P1-T02`, `P2-T01`, `P3-T01`
- **Files:** `ronda_app/lib/data/repositories/supabase_schedule_repository.dart`, `ronda_app/lib/domain/services/auto_scheduler_service.dart`, `ronda_app/test/unit/data/schedule_repository_test.dart`
- **Description:** Implement `AutoSchedulerService` (configurable active/rest cycle, fair officer rotation, zero same-officer overlap) and `ScheduleRepository` (shift templates CRUD, Realtime roster stream, manual shift assign, peer swap creation + `accept_shift_swap` RPC, 3-hour pre-shift expiration handling, and offline-capable `shift_handovers` / Buku Mutasi CRUD + acknowledge).
- **Done when:** Unit tests verify fair rotation, collision rejection, swap expiration, and handover acknowledgement; `flutter analyze` exits 0.

### `P4-T02` : Interactive Calendar UI, Swap Inbox & Buku Mutasi Tab
- **Role:** Front End
- **Needs:** `P2-T03`, `P4-T01`
- **Files:** `ronda_app/lib/providers/schedule_providers.dart`, `ronda_app/lib/presentation/schedule/**`, `ronda_app/test/widget/schedule_and_handover_test.dart`
- **Description:** Build interactive schedule UI using `table_calendar` (monthly/weekly roster view for all 3 roles), Admin Auto-Scheduler & Manual Assignment sheets, Officer Peer Shift Swap request sheet & Incoming/Outgoing Swap cards, and the **Buku Mutasi (Serah Terima Shift)** view with unread handover banner, photo-capable handover composer, and **Konfirmasi Terima Shift** CTA.
- **Done when:** Calendar uses `table_calendar` (no custom calendar reinvented), swap and handover flows work in Light/Dark mode with Empty/Loading/Error states, and widget tests/analyze pass.

---

## Phase 5: Emergency SOS (FCM Background Alarm), Incident Reports & Lapor Mudik (`P5`)

> **Goal:** Deliver high-reliability background SOS alarms with auto-escalation, non-SOS reporting with status triage, and privacy-protected Empty House watches.

### `P5-T01` : FCM SOS Edge Functions, SOS Repository & Reports/Empty House Repository
- **Role:** Back End
- **Needs:** `P1-T02`, `P2-T01`, `P3-T01`
- **Files:** `ronda_app/supabase/functions/dispatch-sos-alert/index.ts`, `ronda_app/supabase/functions/escalate-stale-sos/index.ts`, `ronda_app/lib/data/repositories/supabase_sos_repository.dart`, `ronda_app/lib/data/repositories/supabase_report_repository.dart`, `ronda_app/test/unit/data/sos_and_report_repository_test.dart`
- **Description:** Author Deno Edge Functions for FCM HTTP v1 high-priority SOS dispatch (`rondadigital_sos_alarm` channel) and SLA auto-escalation. Implement `SosRepository` (trigger with 30s anti-spam debounce, Realtime active SOS stream, acknowledge/on-scene/resolve/cancel-false-alarm mutations, `device_tokens` upsert) and `ReportRepository` (offline-capable non-SOS incident reports + status updates + privacy-scoped `empty_house_watches`). Call `ask_user` via PM/Lead for Firebase project setup (`google-services.json`, `FIREBASE_SERVICE_ACCOUNT_JSON` secret) when deploying Edge Functions.
- **Done when:** Edge Functions pass Deno syntax checks, Dart repositories & unit tests pass, and `flutter analyze` exits 0.

### `P5-T02` : FCM Alarm Setup, 3-Second Hold SOS UI & Live Response Tracker
- **Role:** Front End
- **Needs:** `P2-T03`, `P3-T02`, `P5-T01`
- **Files:** `ronda_app/assets/audio/**`, `ronda_app/lib/data/services/push_notification_service.dart`, `ronda_app/lib/providers/sos_providers.dart`, `ronda_app/lib/presentation/sos/**`, `ronda_app/lib/presentation/map/patrol_map_screen.dart` *(add SOS & Empty House pin layers)*, `ronda_app/test/widget/sos_flow_test.dart`
- **Description:** Configure `firebase_messaging` + `flutter_local_notifications` high-importance Android alarm channel and deep-link navigation to `SosDetailTrackerScreen`. Build the tactile 3-second hold-to-activate SOS button (deterministic ring progress + haptic feedback + quick optional category), Active SOS Banner pinned across Staff/Admin screens, Live Response Tracker (`Menuju Lokasi`, `Di Lokasi`, `Selesai`, `Batal False Alarm`), and wire active SOS markers onto the Patrol Map.
- **Done when:** Short taps (< 3s) never trigger SOS, active SOS states render clearly in Light/Dark mode, FCM deep-link route opens tracker cleanly, and widget tests/analyze pass.

### `P5-T03` : Non-SOS Incident Reporting & Lapor Rumah Kosong (Mudik) UI
- **Role:** Front End *(can run in parallel with `P5-T02`)*
- **Needs:** `P2-T03`, `P5-T01`
- **Files:** `ronda_app/lib/providers/report_providers.dart`, `ronda_app/lib/presentation/reports/**`, `ronda_app/test/widget/reports_and_empty_house_test.dart`
- **Description:** Build Non-SOS Incident & Facility Reporting list (filterable by status/category), Report Creation form (category, description, photo capture/gallery, map pin adjustment, offline fallback), Admin/Officer status triage sheet (`Diproses`, `Selesai`, `Ditolak`), and Resident **Lapor Rumah Kosong / Mudik** screen (create/cancel/mark returned own watches, plus Staff-only view of active watches).
- **Done when:** Residents see only their own Empty House requests while Staff see active site watches; incident reports triage cleanly with Loading/Empty/Error states; tests and `flutter analyze` pass.

---

## Phase 6: Compliance Dashboard, CSV/PDF Export, QA & Release Gate (`P6`)

> **Goal:** Deliver real compliance reporting, monthly CSV/PDF export, full antislop/responsive verification, and APK size check.

### `P6-T01` : Compliance Metrics & Monthly CSV/PDF Export Service
- **Role:** Back End
- **Needs:** `P3-T01`, `P4-T01`, `P5-T01`
- **Files:** `ronda_app/lib/core/utils/csv_exporter.dart`, `ronda_app/lib/data/services/pdf_report_generator.dart`, `ronda_app/lib/data/repositories/supabase_compliance_repository.dart`, `ronda_app/test/unit/data/compliance_export_test.dart`
- **Description:** Implement `ComplianceRepository` aggregating real shift completion rate, on-time vs late vs manual-overridden check-ins, open/resolved reports, and median SOS response time from Supabase. Build pure-Dart CSV generator and lightweight `pdf` monthly summary report generator shareable via `share_plus`.
- **Done when:** Unit tests verify accurate metric calculation (zero hardcoded/fake numbers) and valid CSV/PDF byte generation; `flutter analyze` exits 0.

### `P6-T02` : Admin Compliance Dashboard & Export Sheet UI
- **Role:** Front End
- **Needs:** `P3-T04`, `P6-T01`
- **Files:** `ronda_app/lib/providers/compliance_providers.dart`, `ronda_app/lib/presentation/admin/compliance_dashboard_screen.dart`, `ronda_app/lib/presentation/admin/export_report_sheet.dart`, `ronda_app/test/widget/compliance_dashboard_test.dart`
- **Description:** Wire Admin Monitor/Compliance view strictly to real `ComplianceRepository` data (displaying honest empty states when a new site has no shifts yet), direct jump link to pending Manual Audit queue, and Monthly Export Sheet (month picker + Export CSV / Export PDF via native share sheet).
- **Done when:** Zero fabricated stats, Light/Dark & narrow-phone layouts hold up cleanly, export triggers share sheet, and widget tests/analyze pass.

### `P6-T03` : Full QA Pass, Antislop Delivery Gate, APK Size Check & Handover Docs
- **Role:** Front End & Back End (coordinated by PM/Lead)
- **Needs:** `P5-T02`, `P5-T03`, `P6-T02`
- **Files:** `ronda_app/README.md`, `ronda_app/lib/**` *(scoped only to verified QA fixes)*
- **Description:** Run full `flutter analyze`, `flutter test`, build `flutter build apk --release --split-per-abi --tree-shake-icons` and verify `arm64-v8a` APK size <= 25 MB. Verify Light/Dark contrast, 360 dp + tablet responsiveness, Empty/Loading/Error states, zero em dashes/decorative emojis, and zero dead controls per `ronda_app/DESIGN.md` Section 8. Write concise setup & operational guide in `ronda_app/README.md`.
- **Done when:** All unit & widget tests pass, `flutter analyze` has 0 issues, APK size is documented and <= 25 MB, Antislop Delivery Gate passes cleanly, and `ronda_app/README.md` is complete.

---

## External Human Action Items (Expected via JSM HQ `ask_user`)

The PM/Lead or Back End agent should call `ask_user` (never hardcode secrets!) at these exact milestones:
1. **After `P1-T02`:** Apply `ronda_app/supabase/migrations/0001..0006` to the chosen Supabase project and configure `SUPABASE_URL` & `SUPABASE_ANON_KEY` in local `.env.local` (or JSM HQ App Variables).
2. **During `P5-T01`/`P5-T02`:** Create/select Firebase project, enable FCM HTTP v1, download `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) locally (gitignored), and set `FIREBASE_PROJECT_ID` + `FIREBASE_SERVICE_ACCOUNT_JSON` secrets on Supabase Edge Functions.

---

## Suggested PM / Lead Agent Kickoff Message (Inside JSM HQ)

Once your 3-agent team (**PM/Lead**, **Back End**, **Front End**) is running in JSM HQ, send this prompt to the **PM / Lead** agent:

> Read `ROLE.md`, `ronda_app/PRD.md`, `ronda_app/DESIGN.md`, `ronda_app/ARCHITECTURE.md`, and `plan.md`. Never edit `docs/plan.md` manually and never touch legacy `Tugas-*` folders. Create JSM HQ boards for `P1: Foundation` (active), `P2: Auth & Multi-Tenant` (planned), `P3: Map & Forensic Check-In` (planned), `P4: Schedule & Handover` (planned), `P5: SOS & Reports` (planned), and `P6: Compliance & QA` (planned). Populate the `P1` tasks (`P1-T01`, `P1-T02`, `P1-T03`) and `P2-T01` with their exact `Files`, `Needs`, and `Done when` criteria from `plan.md`. Assign `P1-T01` to the Back End agent first; once `P1-T01` merges on `main`, dispatch `P1-T02` (Back End) and `P1-T03` (Front End) in parallel. Enforce strict file boundaries, approved dependency budget, and `flutter analyze` + `flutter test` on every PR.
