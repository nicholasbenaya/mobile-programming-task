# Design System & Visual Direction: RondaDigital (Multi-Tenant)

| Field | Value |
| :--- | :--- |
| **Brand Name** | RondaDigital (placeholder geometric shield-pin mark `[LOGO]` until owner supplies final vector logo) |
| **Product Type** | Multi-Tenant Community Patrol, Shift Operations, Forensic Verification & Emergency SOS Mobile App (Flutter) |
| **Visual Language** | Civic Operational (authoritative high-contrast surfaces, structured field readability, disciplined patrol-amber focal accent, zero decorative clutter) |
| **Dial** | `ENERGY 2 / RHYTHM 2 / MOTION 1` |
| **Themes** | Dual Light Mode + Dark Mode (both first-class and WCAG AA verified; supports system default plus explicit user theme toggle for daytime admin review vs night-shift patrols) |

---

## 1. Design Read & Identity Direction

> Reading this as: operational field-security and neighborhood safety mobile app for site admins, night-shift patrol officers, and residents across Indonesian villages and housing estates, in a Civic Operational visual language, dial `ENERGY 2 / RHYTHM 2 / MOTION 1`.

### Why These Three Dials
- **ENERGY 2 (Balanced):** Clear operational authority without feeling lifeless or playful. High-contrast headers, decisive primary actions, and prominent SOS/scan affordances command attention when stress is high.
- **RHYTHM 2 (Consistent with purposeful breaks):** Operational lists (schedules, check-in logs, reports) follow predictable scannable density, broken intentionally by full-bleed map canvases, full-screen camera/QR viewfinders, and high-emphasis emergency banners when an active alert exists.
- **MOTION 1 (Functional feedback only):** Tactile press feedback, smooth sheet/route transitions, and deterministic progress rings (3-second SOS hold). Zero endless pulsing loops, floating icons, or decorative bounce animations.

### Liveliness Levers
1. **One focal point per screen:** Each screen organizes around the single decision the user needs to make (e.g., on Officer Map: the active checkpoint scan CTA; on Admin Audit: the evidence photo + GPS accuracy comparison; on Resident Home: active patrol reassurance + accessible SOS hold control).
2. **Hierarchical contrast:** Strong weight and scale separation between operational titles, structured status indicators, and crisp monospaced forensic readings (coordinates, distances, timestamps).
3. **Whitespace as structure:** Clear 16 dp screen gutters and 20-24 dp section separation group related data instead of wrapping every single element in heavy shadowed cards.
4. **One deliberate accent:** Signal Lantern Amber (`#B45309` light / `#F59E0B` dark) is reserved exclusively for active operational focus (current patrol window, active check-in prompt, selected calendar day, active navigation state).
5. **Identity motif:** Crisp 1 dp structured borders paired with compact **forensic data strips** (monospaced coordinate, timestamp, and verification state tags) that visually echo real field logbooks and inspection equipment.

---

## 2. Color System (WCAG AA Verified via `contrast-check.py`)

Active palette stays strictly disciplined: 1 neutral slate-ink family, 1 core brand color (Civic Patrol Navy / Steel), and 1 operational accent (Signal Lantern Amber). Semantic status hues (Forest Emerald for Verified, Crimson Alert for SOS/Rejected) appear strictly on real operational states, never as decoration.

### 2.1 Light Mode Tokens (Daytime Admin & Resident Use)

| Token | Hex | Role | Usage Rule |
| :--- | :--- | :--- | :--- |
| `canvas` | `#F4F6F8` | App scaffold background | Cool slate mist that cuts harsh white glare outdoors. |
| `surface` | `#FFFFFF` | Primary cards, sheets, app bars | Clean ground plane for data lists, forms, and map overlays. |
| `surfaceSubtle` | `#E9EEF3` | Input fills, recessed wells | Secondary info containers and inactive chips. |
| `inkPrimary` | `#0F172A` | Primary headings & body ink | Highest legibility under sunlight. |
| `inkSecondary` | `#475569` | Captions, metadata labels | Timestamps, secondary subtitles, helper text. |
| `brandPrimary` | `#153243` | Core Civic Patrol Navy | Primary action buttons, active headers, brand identity. |
| `onBrandPrimary` | `#FFFFFF` | Text/icons on `brandPrimary` | Button labels and primary icon glyphs. |
| `accentOperational` | `#B45309` | Signal Amber (text/icon on light) | Active shift indicator, selected calendar focus, active scan window label. |
| `accentFill` | `#F59E0B` | Signal Amber fill (high visibility) | Active checkpoint map halo, primary scan emphasis paired with `#0F172A` ink. |
| `borderHairline` | `#CBD5E1` | Structural dividers & card outlines | `1 dp` crisp separators. |
| `borderInteractive` | `#64748B` | Input outlines, outlined buttons | Meets WCAG 1.4.11 >= 3.0:1 non-text contrast. |
| `statusVerified` | `#047857` | Verified / On-time / Safe | Text & icon on `surface` or `statusVerifiedTint` (`#ECFDF5`). |
| `statusFlagged` | `#92400E` | Needs Manual Audit / Pending | Text & icon on `statusFlaggedTint` (`#FEF3C7`). |
| `statusEmergency` | `#B91C1C` | SOS Button Fill / Rejected / Missed | Solid SOS button (`#FFFFFF` ink) or alert text (`#991B1B` on `#FEE2E2`). |

### 2.2 Dark Mode Tokens (Night-Shift Patrol Comfort)

| Token | Hex | Role | Usage Rule |
| :--- | :--- | :--- | :--- |
| `canvas` | `#0B111A` | Night Watch scaffold | Low-glare deep navy charcoal to preserve officer night vision. |
| `surface` | `#131C2A` | Primary cards & list surfaces | Subtle tonal step above canvas without glowing shadows. |
| `surfaceElevated` | `#1B273A` | Bottom sheets, dialogs, nav bar | Clear elevation layer via surface tone instead of blur/glow. |
| `inkPrimary` | `#F1F5F9` | Primary headings & body ink | High readability in dark environments without pure-white halation. |
| `inkSecondary` | `#A3B3C6` | Captions & metadata labels | Readable secondary copy on both `surface` and `surfaceElevated`. |
| `brandPrimary` | `#5FA8D3` | Calm Steel Blue | Primary CTA buttons (paired with `#0B111A` dark ink) & focus rings. |
| `onBrandPrimary` | `#0B111A` | Ink on `brandPrimary` | Crisp dark text on steel blue controls. |
| `accentOperational` | `#F59E0B` | Signal Lantern Amber | Active shift window, active scan cue (paired with `#0B111A` ink on fill). |
| `borderHairline` | `#263449` | Card edges & dividers | Subtle structural lines. |
| `borderInteractive` | `#6E829B` | Input outlines, outlined controls | Meets WCAG 1.4.11 >= 3.0:1 non-text contrast against `#131C2A`. |
| `statusVerified` | `#34D399` | Verified / Safe | Text & icon on `surface` or `statusVerifiedTint` (`#0B2E26`). |
| `statusFlagged` | `#FBBF24` | Needs Manual Audit / Pending | Text & icon on `statusFlaggedTint` (`#332207`). |
| `statusEmergency` | `#FCA5A5` | Alert text/icon on dark tint (`#3B1219`) | Used for alert text; solid SOS buttons use `#B91C1C` or `#DC2626` with `#FFFFFF` ink. |

### 2.3 Verified WCAG AA Contrast Matrix (Computed)

| Mode | Foreground | Background | Ratio | Normal Text (4.5:1) | Large / UI (3.0:1) |
| :--- | :--- | :--- | :---: | :---: | :---: |
| Light | `#0F172A` (`inkPrimary`) | `#FFFFFF` (`surface`) | **17.85:1** | PASS | PASS |
| Light | `#0F172A` (`inkPrimary`) | `#F4F6F8` (`canvas`) | **16.48:1** | PASS | PASS |
| Light | `#475569` (`inkSecondary`) | `#FFFFFF` (`surface`) | **7.58:1** | PASS | PASS |
| Light | `#475569` (`inkSecondary`) | `#F4F6F8` (`canvas`) | **6.99:1** | PASS | PASS |
| Light | `#FFFFFF` (`onBrandPrimary`) | `#153243` (`brandPrimary`) | **13.38:1** | PASS | PASS |
| Light | `#B45309` (`accentOperational`) | `#FFFFFF` (`surface`) | **5.02:1** | PASS | PASS |
| Light | `#B45309` (`accentOperational`) | `#F4F6F8` (`canvas`) | **4.64:1** | PASS | PASS |
| Light | `#0F172A` (`inkPrimary`) | `#F59E0B` (`accentFill`) | **8.31:1** | PASS | PASS |
| Light | `#047857` (`statusVerified`) | `#ECFDF5` (`verifiedTint`) | **5.21:1** | PASS | PASS |
| Light | `#92400E` (`statusFlagged`) | `#FEF3C7` (`flaggedTint`) | **6.37:1** | PASS | PASS |
| Light | `#FFFFFF` (SOS label) | `#B91C1C` (`statusEmergency`) | **6.47:1** | PASS | PASS |
| Light | `#991B1B` (alert text) | `#FEE2E2` (`emergencyTint`) | **6.80:1** | PASS | PASS |
| Light | `#64748B` (`borderInteractive`) | `#F4F6F8` (`canvas`) | **4.39:1** | UI Border | PASS (1.4.11) |
| Dark | `#F1F5F9` (`inkPrimary`) | `#0B111A` (`canvas`) | **17.28:1** | PASS | PASS |
| Dark | `#F1F5F9` (`inkPrimary`) | `#131C2A` (`surface`) | **15.62:1** | PASS | PASS |
| Dark | `#F1F5F9` (`inkPrimary`) | `#1B273A` (`surfaceElevated`) | **13.71:1** | PASS | PASS |
| Dark | `#A3B3C6` (`inkSecondary`) | `#131C2A` (`surface`) | **8.00:1** | PASS | PASS |
| Dark | `#A3B3C6` (`inkSecondary`) | `#1B273A` (`surfaceElevated`) | **7.03:1** | PASS | PASS |
| Dark | `#0B111A` (`onBrandPrimary`) | `#5FA8D3` (`brandPrimary`) | **7.24:1** | PASS | PASS |
| Dark | `#5FA8D3` (`brandPrimary`) | `#131C2A` (`surface`) | **6.54:1** | PASS | PASS |
| Dark | `#5FA8D3` (focus ring) | `#1B273A` (`surfaceElevated`) | **5.74:1** | UI Focus | PASS (1.4.11) |
| Dark | `#F59E0B` (`accentOperational`) | `#131C2A` (`surface`) | **7.97:1** | PASS | PASS |
| Dark | `#0B111A` (ink on accent) | `#F59E0B` (`accentOperational`) | **8.81:1** | PASS | PASS |
| Dark | `#34D399` (`statusVerified`) | `#0B2E26` (`verifiedTint`) | **7.62:1** | PASS | PASS |
| Dark | `#FBBF24` (`statusFlagged`) | `#332207` (`flaggedTint`) | **9.16:1** | PASS | PASS |
| Dark | `#FCA5A5` (`statusEmergency`) | `#3B1219` (`emergencyTint`) | **8.60:1** | PASS | PASS |
| Dark | `#FFFFFF` (SOS label) | `#DC2626` (SOS dark fill) | **4.83:1** | PASS | PASS |
| Dark | `#6E829B` (`borderInteractive`) | `#131C2A` (`surface`) | **4.34:1** | UI Border | PASS (1.4.11) |

---

## 3. Typography System (Offline-Safe & Size-Conscious)

Bundle local `.ttf` font files directly in `ronda_app/assets/fonts/` instead of relying on runtime `google_fonts` downloads (guarantees offline rendering and keeps APK overhead under ~280 KB).

- **Primary UI Font:** `Plus Jakarta Sans` (weights `400 Regular`, `500 Medium`, `700 Bold`).
  - *Why:* Designed by an Indonesian foundry with clear open counters and crisp Bahasa Indonesia readability across compact phone screens and field light conditions.
- **Forensic Data Font:** `JetBrains Mono` (weight `400 Regular` only).
  - *Why:* Tabular monospace alignment makes GPS coordinates (`-7.28251, 112.79548`), Haversine distances (`14.2 m`), timestamps (`22:34:09 WIB`), invite codes, and SHA-256 checksums scannable without digit jitter. Strictly banned on marketing headlines or decorative banners (R-06).

### Mobile Type Scale (Respects System `textScaler` up to 200%)

| Style | Font | Size (sp) | Weight | Line Height | Usage |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `headlineMedium` | Plus Jakarta Sans | 22 | 700 | 1.25 | Screen titles & onboarding headers. |
| `titleLarge` | Plus Jakarta Sans | 18 | 700 | 1.30 | Section headers, sheet titles, SOS alert titles. |
| `titleMedium` | Plus Jakarta Sans | 15 | 700 | 1.35 | Card titles, checkpoint names, officer names. |
| `bodyLarge` | Plus Jakarta Sans | 15 | 400 | 1.45 | Report descriptions, handover notes, dialogs. |
| `bodyMedium` | Plus Jakarta Sans | 13.5 | 400 | 1.45 | Secondary details, audit reasons, list subtitles. |
| `labelLarge` | Plus Jakarta Sans | 14 | 700 | 1.20 | Primary buttons, tab labels. |
| `labelSmall` | Plus Jakarta Sans | 12 | 500 | 1.25 | Status chips, navigation labels (never below 11.5 sp). |
| `forensicMono` | JetBrains Mono | 12.5 | 400 | 1.35 | GPS lat/lng, distance, accuracy, UTC/WIB timestamps, photo hash prefix. |

---

## 4. Layout, Spacing, Radius & Mobile Ergonomics

### 4.1 Spacing & Radius Scale
- **Spacing tokens:** `4`, `8`, `12`, `16` (default screen horizontal margin), `20`, `24` (section gap), `32`.
- **Radius hierarchy (R-11, never uniform pill-everything):**
  - `6 dp`: Forensic metadata chips and compact status tags (sharp, instrument-like).
  - `10 dp`: Inputs, buttons, list containers.
  - `14 dp`: Primary content cards and map overlay cards.
  - `20 dp` (top corners only): Modal bottom sheets.
  - `999 dp` (full circle): Reserved strictly for the circular 3-second SOS hold trigger, user avatars, and map recenter FAB.
- **Elevation & Shadow (R-12, R-13):**
  - Cards sit flat with `1 dp` `borderHairline` (elevation `0`).
  - Elevation (`2-4 dp`) is reserved strictly for floating map controls, bottom sheets, and active SOS alert banners. Zero neon glows or stacked glassmorphism.

### 4.2 Mobile Ergonomics & Responsive Reflow
- **Minimum tap target:** `48 x 48 dp` for primary actions and bottom navigation items; minimum `44 x 44 dp` with at least `8 dp` gap for icon actions and chips.
- **Responsive breakpoints:**
  - Compact Phone (`< 600 dp`): Single-column scroll, `NavigationBar` at bottom, full-width bottom sheets.
  - Medium / Tablet (`600-839 dp`): `NavigationRail` on left, 2-column grid for Admin Audit photo + forensic panel side-by-side.
  - Expanded (`>= 840 dp`): Persistent split pane for Map + Checkpoint Inspector or Audit List + Evidence Detail.
- **Safe areas & keyboard resilience:** Always wrap forms in scrollable views with `MediaQuery.viewInsetsOf(context).bottom` padding so the software keyboard never covers submit buttons or notes fields. Always reserve bottom navigation height (`SafeArea`) so list tails remain tappable.

---

## 5. Role-Based Navigation & Screen Map (Zero Dead Destinations)

Every role sees only the destinations it genuinely uses. Each navigation bar has 4 clear items with icon + Indonesian label (no bare icon-only bars, no hidden burger menus for primary flows).

### 5.1 Onboarding & Auth Flow (Unauthenticated / No Active Site)
1. **Sign In / Register Screen:** Clean Email + Password form, registration collects Full Name + WhatsApp Number.
2. **Site Selector / Onboarding Screen:** Lists joined sites (with role badge & pending approval status) plus two decisive actions: **Buat Wilayah Baru** and **Gabung Pakai Kode Undangan**.

### 5.2 Officer Shell (`officer`)
Bottom Nav (4 tabs):
1. **Patroli (Map-First Home):** Top compact shift status strip (shift name, hours, offline queue sync badge if > 0) + interactive `flutter_map` showing checkpoints, active SOS pin, and active Empty House pins + floating primary CTA **Scan Pos Patroli**. Bottom sheet lists shift checkpoints and live distance.
2. **Jadwal & Mutasi:** Top segmented switcher between **Jadwal & Tukar Shift** (`table_calendar` + incoming/outgoing peer swap cards) and **Buku Mutasi** (unread handover banner + chronological handover log + compose note button).
3. **Laporan:** Tabbed list of site non-SOS incident reports with status filter + **Buat Laporan** action.
4. **SOS & Profil:** Prominent **Tombol Darurat SOS (Tahan 3 Detik)**, active SOS incident queue with **Tanggapi / Menuju Lokasi** action, site switcher, theme toggle (Sistem / Terang / Gelap), and sign out.

### 5.3 Admin Wilayah Shell (`admin`)
Bottom Nav (4 tabs):
1. **Monitor & Audit:** Priority operational view built around the admin's key decisions:
   - Active SOS Alert Card (pinned at top only when an SOS is `open`/`escalated`).
   - Pending Manual Check-in Audit Queue (`Perlu Tinjauan` / `Ditolak Otomatis` count + direct list to inspect evidence).
   - Interactive Site Patrol Map toggle (with **Kelola Pos & Cetak QR** entry point).
   - Real compliance summary for current shift/month + **Ekspor Rekap (CSV/PDF)**.
2. **Jadwal:** `table_calendar` roster manager, **Buat Jadwal Otomatis**, manual assignment sheet, shift swap audit history, and **Buku Mutasi** viewer.
3. **Laporan:** Triage inbox for resident/officer non-SOS reports (`Baru`, `Diproses`, `Selesai`) + Empty House watch list (`Lapor Mudik`).
4. **Wilayah & Anggota:** Site settings (name, geofence radius, SOS escalation SLA), invite code copy/share, member approval & role assignment, theme toggle, site switcher, sign out.

### 5.4 Resident Shell (`resident`)
Bottom Nav (4 tabs):
1. **Beranda & SOS:** Centered around the resident's primary need: active security status of their site (active shift roster & verified patrol count today, using real data only) + clear, spacious **Tombol Darurat SOS (Tahan 3 Detik)** with active SOS tracker card when triggered.
2. **Peta & Jadwal:** Read-only patrol map showing checkpoint verification progress (never showing other residents' Empty House pins!) + transparent `table_calendar` duty roster.
3. **Lapor:** Submit Non-SOS incident/facility report + track own report statuses + **Lapor Rumah Kosong / Mudik** section (manage own temporary watch windows).
4. **Profil:** Unit address, emergency contact, site switcher, theme toggle, sign out.

---

## 6. Key Specialized Screen Blueprints

### 6.1 Forensic Check-In Flow (Officer)
- **Step 1 (QR Scanner):** Full-screen `mobile_scanner` viewfinder with framing bracket, torch toggle button (crucial for night patrol), and clear prompt: *"Arahkan kamera ke stiker QR di pos patroli."*
- **Step 2 (Mandatory Live Camera Capture):** Immediately transitions to live camera preview (no gallery button). Displays live GPS status bar at top (`Akurasi GPS: 12 m | Jarak ke Pos: 8 m | Mode: Online/Offline`) so the officer knows GPS lock quality before pressing capture.
- **Step 3 (Forensic Confirmation Sheet):** Shows captured photo thumbnail + monospaced forensic strip (`Waktu`, `Koordinat`, `Jarak`, `Akurasi`, `SHA-256`) + automated pre-check verdict badge (`Siap Terverifikasi` or `Akan Ditandai untuk Tinjauan Admin: <alasan>`) + optional short field note + **Kirim Check-In** CTA.

### 6.2 Admin Manual Audit & False-Positive Override Screen
- Top bar shows checkpoint name, officer name, and current status pill (`Perlu Tinjauan`, `Ditolak Otomatis`, `Terverifikasi`, `Disetujui Manual`, `Ditolak Manual`).
- **Evidence Section:** Full-width zoomable `InteractiveViewer` photo with subtle bottom scrim (`rgba(11,17,26,0.78)`) showing capture timestamp and checkpoint code.
- **Spatial Verification Mini-Map:** `flutter_map` snippet showing:
  - Checkpoint center + geofence radius circle (green/amber dashed border).
  - Officer recorded GPS pin + GPS accuracy uncertainty circle.
- **Forensic Metadata Table:** Monospaced rows for `Waktu Foto (Perangkat)`, `Waktu Diterima (Server)`, `Koordinat`, `Jarak ke Pos`, `Akurasi GPS`, `Deteksi Fake GPS`, `Mode Pengiriman (Online/Offline)`, `Integritas Foto (SHA-256)`, and triggered `Alasan Flag Otomatis`.
- **Sticky Action Bar (safe-area padded):** Two high-contrast buttons with clear separation: **Tolak Manual** (outlined emergency) and **Setujui Manual (Override)** (filled verified/primary). Tapping either opens a sheet requiring a concise `Catatan Audit` (e.g., *"Foto jelas menunjukkan Pos 2, GPS meleset karena hujan deras"*).

### 6.3 Status Indicator Discipline (Non-Color-Only, C-4)
Every status pairs **Icon + Indonesian Label + Semantic Color**:
- `auto_verified`: Check circle icon + `"Terverifikasi"` + Emerald
- `manual_approved`: Verified user icon + `"Disetujui Admin"` + Emerald
- `flagged_review`: Warning triangle icon + `"Perlu Tinjauan"` + Amber
- `auto_rejected`: Block/cancel icon + `"Ditolak Otomatis"` + Crimson
- `manual_rejected`: Cancel icon + `"Ditolak Admin"` + Crimson
- `offline_pending`: Cloud-off icon + `"Menunggu Sinkronisasi"` + Slate/Amber

---

## 7. Copywriting, UI States & Anti-Slop Rules

### 7.1 Bahasa Indonesia Operational Voice
- Direct, human, operational Bahasa Indonesia.
- Specific CTAs (R-15): Use `"Scan QR & Ambil Foto"`, `"Tahan 3 Detik untuk SOS"`, `"Setujui Check-In"`, `"Buat Wilayah Baru"`, `"Ajukan Tukar Shift"`. Never use generic `"Get Started"`, `"Explore"`, or buzzwords (`"Seamless"`, `"Revolutionary"`, `"AI Powered"`).
- Strict R-02 rule: Zero em dashes (`U+2014`) anywhere in UI strings.
- Zero decorative emojis in any widget text, dialog title, or notification copy.

### 7.2 Mandatory UI States (R-27)
Every async screen must implement all three states with actionable text (never bare spinners or vague `"Tidak ada data"`):
- **Loading:** Named context message or focused skeleton (e.g., `"Memuat jadwal patroli minggu ini..."`).
- **Empty:** Explains why empty + single clear next CTA (e.g., `"Belum ada titik patroli di wilayah ini. Tambahkan pos pertama di peta untuk mencetak kode QR."` + button `"Tambah Pos Patroli"`).
- **Error:** Explains failure plainly + recovery action (e.g., `"Gagal memuat data wilayah karena koneksi terputus."` + button `"Coba Lagi"`).

### 7.3 Design Decision Log (R-31 Compliance)
| Decision | One-Line Written Reason |
| :--- | :--- |
| Deep Patrol Navy (`#153243`) + Night Watch Dark (`#0B111A`) | Establishes civic operational trust by day and protects night-shift patrol officers from screen glare. |
| Single Lantern Amber Accent (`#B45309` / `#F59E0B`) | Concentrates visual attention on the active patrol window and primary action without competing with red SOS alerts. |
| `Plus Jakarta Sans` + `JetBrains Mono` (forensic only) | Ensures clean Bahasa Indonesia legibility while keeping coordinates, distances, and timestamps tabularly aligned for rapid audit. |
| Flat 1 dp bordered cards instead of shadowed/glass cards | Maintains crisp hierarchy in bright sunlight and dark shifts without visual noise or GPU blur overhead. |
| 4-tab role-scoped `NavigationBar` | Puts every primary operational task within one thumb tap on mobile without hiding critical actions behind a hamburger menu. |
| Local bundled fonts (3 sans + 1 mono) | Guarantees consistent offline typography in village blank spots while staying under 280 KB. |

---

## 8. Front End Delivery Gate (Run Before Every UI PR)

Before marking any UI task `in-review`, Front End must verify:
- [ ] Both Light Mode and Dark Mode render cleanly with zero broken contrast or invisible borders (R-25, R-34).
- [ ] Tested on narrow phone width (~360 dp) with zero horizontal overflow or RenderFlex errors, and forms scroll clear of the keyboard (R-03).
- [ ] All interactive buttons, tabs, sheets, and forms execute real actions (R-24, R-26).
- [ ] Empty, Loading, and Error states exist with explicit cause and action (R-27).
- [ ] Zero em dashes, zero decorative emojis, zero invented numbers/names (R-02, R-17, R-38).
- [ ] `flutter analyze` passes with 0 issues and widget tests cover the new screen states (R-35).
