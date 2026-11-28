# Product Requirements Document (PRD): RondaDigital (Multi-Tenant)

| Field | Value |
| :--- | :--- |
| **Product Name** | RondaDigital (subtitle: Sistem Patroli & Keamanan Lingkungan Multi-Wilayah) |
| **Active Directory** | `ronda_app/` (clean rebuild; legacy `Tugas-5/` remains untouched) |
| **Target Platform** | Flutter Mobile (Android primary, iOS compatible) |
| **Backend & Push Stack** | Supabase (PostgreSQL + RLS + Auth + Storage + Realtime + Edge Functions) + Firebase Cloud Messaging (FCM) for high-priority SOS alarms |
| **Document Owner** | PM / Lead Agent (JSM HQ) |
| **Status** | Approved Scope Baseline (v1.0) |

---

## 1. Product Vision & Problem Statement

### 1.1 Real-World Problems
Neighborhoods, villages (desa/RT/RW), housing estates (perumahan/klaster), and local facilities face four recurring security management gaps:
1. **Unverified patrols:** Security guards or neighborhood watch members can skip patrol points or falsify attendance when proof relies only on manual sign-in sheets or informal chat photos.
2. **Static QR vulnerability:** Plain printed QR stickers alone can be photographed once and scanned remotely from a guard post or home.
3. **Fragmented schedules & handovers:** Shift rotations, peer swaps, and shift-change notes (buku mutasi) live across scattered chat messages, causing unmanned shifts and lost context.
4. **Slow emergency and issue response:** Residents lack a fast panic channel that wakes on-duty guards when phones are locked, and non-emergency reports (broken streetlights, suspicious activity, empty houses during travel) lack structured tracking.

### 1.2 Product Goal
Build a professional, **multi-tenant** mobile patrol and community security platform in Flutter that any village, housing complex, RT/RW, or facility can adopt independently without code changes. Every site manages its own boundaries, checkpoints, printable QR stickers, officers, shift schedules, SOS alerts, and verifiable patrol evidence.

---

## 2. Multi-Tenant Model & Roles (RBAC)

A single registered user account can belong to one or more sites (`sites`), with a specific role per site via `site_memberships`.

### 2.1 Roles
| Role | Code | Core Responsibilities |
| :--- | :--- | :--- |
| **Admin Wilayah** (Ketua RT, Kepala Desa, Komandan Regu, Manajer Keamanan) | `admin` | Create/configure site, manage map checkpoints & printable QR codes, approve join requests, manage shift schedules, audit flagged patrol check-ins manually (override false positives/negatives), triage reports, view compliance dashboard & export monthly reports, escalate/verify SOS. |
| **Petugas Patroli** (Satpam / Petugas Ronda) | `officer` | View assigned shifts & active patrol map, scan checkpoint QR + capture live photo evidence with forensic metadata, submit offline check-ins in blank spots, request/accept peer-to-peer shift swaps, write/read shift handover notes (buku mutasi), receive high-priority SOS alarms & update response status, file patrol reports, view prioritized empty-house pins. |
| **Warga / Penghuni** (Resident) | `resident` | Join site via invite code, trigger SOS panic alert (sent to all on-duty officers), track real-time SOS response status, submit non-SOS security/facility reports with photo & GPS, submit temporary Empty House / Lapor Mudik watch requests, view patrol transparency status & active duty roster (without exposing other residents' private data). |

### 2.2 Permission Matrix
| Capability | Admin | Officer | Resident |
| :--- | :---: | :---: | :---: |
| Create new site & configure patrol area | Yes | No (can create own new site) | No (can create own new site) |
| Manage checkpoints (CRUD on map) & regenerate/print QR | Yes | View only | View status summary only |
| Approve/revoke site members & assign roles | Yes | No | No |
| Create/edit shift schedules & auto-schedule | Yes | View | View active duty roster |
| Request & accept peer-to-peer shift swaps | Audit log + override | Yes | No |
| Perform QR + Photo check-in with forensic metadata | Only if also scheduled | Yes (own active shift) | No |
| View automated check-in flags & perform manual audit override | Yes | View own check-in status | No |
| Write & read Shift Handover (Buku Mutasi) | Yes | Yes | No |
| Trigger SOS alert & cancel own false alarm | Yes | Yes | Yes |
| Receive high-priority SOS alarm & respond/resolve | Yes (escalation + audit) | Yes (primary responders) | Own SOS tracking |
| Create Non-SOS incident/facility report | Yes + update status | Yes + update status | Yes + track status |
| Submit Empty House / Lapor Mudik watch pin | View all + approve | View active pins on patrol map | Create/edit/cancel own only |
| View compliance analytics & export CSV/PDF | Yes | Own summary only | No |

---

## 3. Core Strategic Solution: Tamper-Resistant Check-In & Dual Verification

To eliminate patrol fraud while keeping hardware cost near zero for any village or housing complex, every checkpoint check-in follows a **Hybrid Signed-QR + Geofence + Anti-Mock + Mandatory Live Photo with Forensic Metadata** workflow backed by **Dual Verification (Automated + Manual Admin Audit)**.

### 3.1 Check-In Flow (Officer)
1. Officer taps a checkpoint on the interactive map (or taps "Scan Pos Patroli") during an active shift.
2. **Step 1 (QR Scan):** Officer scans the printed QR sticker affixed to the physical checkpoint. The QR encodes `RD1|<site_id>|<checkpoint_id>|<token_version>|<hmac_signature>`. Because stickers are static printed media, tokens do NOT expire every 3 minutes; instead, Admins can **revoke and regenerate** a checkpoint's `token_version` at any time if a sticker is damaged or leaked.
3. **Step 2 (Mandatory Live Camera Photo):** Immediately after QR decode, the camera opens directly (gallery import is disabled for patrol check-ins). Officer captures a real-time photo of the checkpoint area.
4. **Step 3 (Forensic Metadata Capture):** At capture time, the app binds immutable forensic metadata to the check-in record:
   - `captured_at_client` (ISO-8601 UTC device time) + monotonic elapsed offset (for offline tampering detection)
   - `synced_at_server` (authoritative Postgres server timestamp on ingestion)
   - `latitude`, `longitude`, `accuracy_meters`
   - `distance_meters` (Haversine distance to checkpoint coordinates)
   - `is_mocked` (Android/iOS mock-location detection flag)
   - `photo_sha256` (SHA-256 digest of compressed JPEG bytes computed before upload)
   - `is_offline_submission` (boolean indicating whether queued offline)
   - Optional lightweight context: `battery_level`, `device_model`
   - A non-destructive forensic stamp overlay is rendered in Admin review (and optionally burned into exported evidence PDFs) showing timestamp, coordinates, distance, and checkpoint code.
5. **Step 4 (Submission or Offline Queue):** If online, photo uploads to private Storage and check-in executes via server RPC. If offline, photo file and full forensic record persist in local SQLite (`sqflite`) and auto-sync when connectivity returns.

### 3.2 Dual Verification Mechanism (Automated Check + Manual Admin Audit)

#### Mechanism 1: Automated Integrity Engine (`auto_status`)
Every submitted check-in is evaluated automatically by deterministic rules (server-side authoritative, mirrored locally for immediate officer feedback):

| Rule Code | Condition | Severity | Resulting `auto_status` |
| :--- | :--- | :--- | :--- |
| `QR_INVALID_OR_REVOKED` | Signature mismatch, wrong site, or old `token_version` | Hard Fail | `auto_rejected` |
| `MOCK_GPS_DETECTED` | `is_mocked == true` | Hard Fail | `auto_rejected` |
| `OUTSIDE_GEOFENCE_EXTREME` | `distance_meters > max(checkpoint.radius_m * 3, 150m)` | Hard Fail | `auto_rejected` |
| `OUTSIDE_GEOFENCE_BORDERLINE` | `checkpoint.radius_m < distance_meters <= max(radius_m * 3, 150m)` | Soft Flag | `flagged_review` |
| `LOW_GPS_ACCURACY` | `accuracy_meters > 35.0` (e.g., dense roof, heavy rain, narrow alley) | Soft Flag | `flagged_review` |
| `OUTSIDE_SHIFT_WINDOW` | Scanned outside officer's assigned shift hours | Soft Flag | `flagged_review` |
| `OFFLINE_DELAY_OR_CLOCK_SKEW` | Offline sync delay > 30 min or device clock drift > 5 min vs server | Soft Flag | `flagged_review` |
| `PHOTO_HASH_MISSING_OR_MISMATCH` | Uploaded photo fails integrity check | Hard Fail | `auto_rejected` |
| All checks passed | Zero hard fails and zero soft flags | Pass | `auto_verified` |

*Key design rule:* Even `auto_rejected` records are **persisted in the audit trail** (never silently dropped) so Admins can inspect potential false positives caused by faulty GPS hardware or environmental interference.

#### Mechanism 2: Manual Admin Audit & False-Positive Override (`manual_status`)
- Admins have a dedicated **Rekap & Audit Check-In** screen filterable by status (`Perlu Tinjauan / Flagged`, `Ditolak Otomatis`, `Terverifikasi Otomatis`, `Semua`) and by date/officer/checkpoint.
- Opening any check-in displays:
  1. Full-resolution zoomable evidence photo.
  2. Mini-map comparing the checkpoint pin + geofence radius against the officer's recorded GPS dot + accuracy circle.
  3. Complete Forensic Metadata Table (client capture time, server receipt time, distance, GPS accuracy, `is_mocked`, offline flag, photo SHA-256 status, list of triggered `flag_reasons`).
- Admin actions (both require a short mandatory `review_note` recorded in an immutable audit log):
  - **Setujui Manual (`manual_approved`):** Overrides an automated `flagged_review` or `auto_rejected` false positive (e.g., GPS drifted 38 m due to rain, but the live photo clearly proves the officer stood at Pos 3). Updates shift compliance counts immediately.
  - **Tolak Manual (`manual_rejected`):** Overrides an `auto_verified` false negative (e.g., officer scanned inside radius but photographed a pitch-black pocket or irrelevant object).
- Effective status logic: `effective_status = manual_status ?? auto_status`.

---

## 4. Functional Requirements

### Module 1: Multi-Tenant Onboarding, Auth & Site Management
- **FR-AUTH-01:** Users register and sign in via Email + Password (Supabase Auth) with profile fields: `full_name`, `phone_whatsapp`, `unit_address` (optional per site).
- **FR-AUTH-02:** Authenticated users without a site see an onboarding choice: **Buat Wilayah Baru** (becomes `admin`) or **Gabung Wilayah** via 8-character invite code (or scanning a site invite QR).
- **FR-AUTH-03:** Site Admins configure join policy (auto-approve vs manual approval), manage members (approve, assign role `admin`/`officer`/`resident`, deactivate), and switch sites if belonging to multiple sites.
- **FR-SITE-01:** Site Admins configure site name, type (Desa, Perumahan, Klaster, RT/RW, Fasilitas), map center coordinates, default geofence radius (default 30 m), and SOS escalation timeout (default 3 minutes).

### Module 2: Interactive Patrol Map & Checkpoint Management
- **FR-MAP-01:** Interactive OpenStreetMap view (`flutter_map`) centered on the active site's boundary/checkpoints, showing:
  - Checkpoint markers color-coded AND icon/label-coded (never color-only) for the active shift: `Selesai` (verified), `Perlu Tinjauan` (flagged), `Waktunya Scan` (active window), `Terlewat` (missed), `Mendatang` (upcoming).
  - Geofence radius circles around checkpoints.
  - Active SOS emergency markers (prominent alert pin with reporter location and distance).
  - Active Empty House / Lapor Mudik priority pins (visible strictly to `admin` and `officer` roles).
  - Live user GPS dot + recenter control.
- **FR-MAP-02:** Tapping any checkpoint pin opens a bottom sheet showing target scan window, last check-in status (per individual officer), live distance from officer's GPS, and direct CTA **Scan QR & Ambil Foto** (for officers on shift) or **Lihat Bukti & Audit** (for admins).
- **FR-MAP-03 (Checkpoint CRUD & Printable QR):** Admins can add/edit/deactivate checkpoints by tapping the map, set target check-in times per shift template, regenerate a checkpoint's QR token (revoking old stickers), and export a clean **Printable QR Poster** (PNG/PDF with site name, checkpoint code, location label, and QR code) via native share/save.

### Module 3: Interactive Schedule, Shift Swaps & Shift Handover (Buku Mutasi)
- **FR-SCHED-01:** Interactive calendar powered by `table_calendar` displaying monthly/weekly roster dots and shift assignments per date across all roles (transparency for residents, full controls for admin/officers).
- **FR-SCHED-02:** Admins create shift templates (e.g., Shift Pagi, Sore, Malam), assign officers manually, or run a fair **Auto-Scheduler** (configurable work/rest ratio, e.g., 5 active + 1 off) with collision detection preventing the same officer from overlapping shifts on the same date.
- **FR-SCHED-03 (Peer-to-Peer Shift Swap):** Officers can request a shift swap with a colleague on a selected date/shift with a reason.
  - Single-pending constraint: max 1 active `pending` swap per shift assignment.
  - Peer consent: once the target officer accepts, schedule ownership transfers atomically via Postgres RPC (`accept_shift_swap`) and notifies the Admin audit feed.
  - Admin override: Admin can intervene or reassign in disputes.
  - Expiration rule: Unanswered swap requests expire automatically 3 hours before shift start.
- **FR-HANDOVER-01 (Buku Mutasi / Shift Handover):** Before ending or starting a shift, officers submit structured handover notes (status gerbang/aset, catatan penting, referensi laporan yang belum selesai, optional photo). The incoming shift officer sees unread handover notes pinned at the top of their shift screen and taps **Konfirmasi Terima Shift** (recorded with timestamp).

### Module 4: SOS Emergency System (Realtime + Background FCM + Auto-Escalation)
- **FR-SOS-01:** Residents, officers, and admins can trigger SOS via a **3-second hold-to-activate button** (prevents accidental taps; haptic feedback during hold) with optional 1-tap category (Pencurian, Kebakaran, Medis, Darurat Lain) that defaults immediately without blocking panic dispatch.
- **FR-SOS-02 (Instant Broadcast to All Patrol Officers):** Triggering SOS inserts an `sos_events` row and invokes a Supabase Edge Function (`dispatch-sos-alert`) that sends high-priority **FCM push notifications** with custom alarm channel/sound to **all officers and admins in that `site_id`** (prioritizing on-duty officers, waking locked/background devices) plus Realtime updates to open apps.
- **FR-SOS-03 (Response Lifecycle & Self-Cancel):**
  - Status flow: `open` -> `acknowledged` (officer taps "Menuju Lokasi", showing responder name & live distance) -> `on_scene` -> `resolved` (with resolution note + optional proof photo) OR `cancelled_false_alarm` (self-cancellation by reporter with reason before resolution).
  - Anti-spam debounce: 30-second cooldown per user while an SOS is already `open`.
- **FR-SOS-04 (Auto-Escalation):** If an `open` SOS is not acknowledged within the site's configured SLA (default 3 minutes), the backend escalates (`escalated_at` set, status banner heightened) and dispatches a second urgent FCM alert to all site Admins and off-duty officers.

### Module 5: Non-SOS Incident & Facility Reporting
- **FR-REP-01:** Residents, officers, and admins can submit non-SOS reports categorized by type: `Orang Mencurigakan`, `Kerusakan Fasilitas`, `Lampu Jalan Mati`, `Keamanan / Vandalisme`, `Kebersihan / Lingkungan`, `Lainnya`.
- **FR-REP-02:** Every report includes description, auto-captured GPS coordinates (adjustable pin on map), and mandatory live/gallery photo (compressed JPEG <= 1.5 MB).
- **FR-REP-03:** Structured triage lifecycle managed by Admins and Officers: `open` -> `in_progress` -> `resolved` / `rejected`, with timestamped status updates visible to the reporter.

### Module 6: Empty House / Lapor Mudik (Temporary Patrol Priority)
- **FR-EMPTY-01:** Residents can submit a temporary watch request with address/house pin on map, start date, end date, emergency contact phone, and notes (e.g., lights left on, authorized caretaker).
- **FR-EMPTY-02 (Strict Privacy):** Empty house pins and details are **strictly invisible to other residents** (enforced at PostgreSQL RLS level). Only `admin` and `officer` members of the same `site_id` can view active pins on the patrol map during the declared date range.
- **FR-EMPTY-03:** Pins expire automatically after `end_date` (or when the resident taps "Sudah Kembali").

### Module 7: Offline-First Persistence & Auto-Sync
- **FR-OFF-01:** Check-in records (including local photo file path and computed SHA-256), incident report drafts, and handover drafts are persisted in local SQLite (`sqflite`) when network connectivity is unavailable.
- **FR-OFF-02:** Each queued item carries a client-generated UUID (`client_event_id`) ensuring idempotent server ingestion (zero duplicates on retries).
- **FR-OFF-03:** A visible sync indicator shows pending queue count and automatically flushes when connectivity returns, with manual "Sinkronkan Sekarang" retry action.

### Module 8: Compliance Dashboard, Manual Audit & Monthly Export
- **FR-DASH-01:** Admin compliance view calculates real metrics from persisted data only (never fabricated numbers): shift completion rate, on-time vs late check-ins, count of `flagged_review` and `auto_rejected` items awaiting audit, open reports, and SOS response times (median/average).
- **FR-DASH-02:** Export monthly patrol audit logs, incident reports, and SOS history to **CSV** (zero heavy dependencies) and **PDF summary** (`pdf` pure Dart package) via native share sheet.

---

## 5. Non-Functional Requirements & App Size Budget

| Category | Measurable Target |
| :--- | :--- |
| **APK Size Budget** | Release Android `arm64-v8a` APK <= 25 MB (enforced via `--split-per-abi`, `--tree-shake-icons`, lightweight pure-Dart libraries, OS-native `sqflite`). |
| **SOS Dispatch Latency** | < 3 seconds from hold completion to FCM push delivery on devices with standard 4G/Wi-Fi. |
| **Multi-Tenant Isolation** | 100% of database tables and storage paths protected by PostgreSQL RLS scoped to `site_id` and verified via `site_memberships`. |
| **Photo Compression** | Max 1600px longest edge, JPEG quality 78%, target <= 1.2 MB (hard limit 2.0 MB) before SHA-256 hashing and upload. |
| **Offline Durability** | Queued check-ins survive app termination and device reboot via `sqflite`; zero duplicate records on retry. |
| **Accessibility** | WCAG AA contrast (4.5:1 normal text, 3:1 large text & UI borders) across both Light Mode and Dark Mode; minimum 44x44 dp tap targets; non-color-only status indicators. |
| **Code Maintainability** | Feature-first Clean Architecture; max ~350 lines per UI screen file; `flutter analyze` exits with 0 warnings/errors. |

---

## 6. High-Level Acceptance Criteria (Release Gate)

1. A new user can create a brand-new site, drop 3 checkpoints on the map, generate printable QR codes, invite an officer and a resident via invite code, and operate completely isolated from other sites.
2. Scanning a checkpoint QR requires taking a live photo, records forensic metadata (timestamp, GPS, accuracy, distance, `is_mocked`, photo SHA-256), evaluates automated rules, and appears immediately in the Admin audit queue if flagged or rejected.
3. Admin can inspect the evidence photo + GPS comparison map + forensic metadata and manually approve a false-positive check-in (or manually reject a false-negative check-in) with an immutable audit note.
4. Performing a check-in with Airplane Mode enabled saves to SQLite, survives an app restart, and syncs cleanly without duplicates once online.
5. Triggering SOS from a resident device delivers a high-priority FCM alarm notification to officers even when the officer's app is in the background, tracks response status live, and escalates automatically if unacknowledged past SLA.
6. Officers can swap shifts peer-to-peer on an interactive `table_calendar` schedule, log shift handover notes (Buku Mutasi), view resident Empty House pins (hidden from other residents), and process non-SOS reports.
7. Admin can view real compliance metrics and export a monthly CSV/PDF patrol report.
