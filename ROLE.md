# Project Rules: Ronda Digital Multi-Tenant (JSM HQ)

> JSM HQ automatically reads this root `ROLE.md` and appends it to every agent's generated `.jsmhq-role.md`. Every agent (PM/Lead, Front End, Back End) must follow these rules strictly.

## 1. Active Scope & Folder Boundaries

- **Active project folder:** `ronda_app/` (product name: **RondaDigital**).
- **Read-only legacy folders:** `Tugas-1/`, `Tugas-2/`, `Tugas-3/`, `Tugas-4/`, `Tugas-5/`, and root legacy artifacts (`README.md`, `CHEATSHEET_PEMROGRAMAN_BERGERAK.md`, `*.pdf`, `*.ipynb`). Never modify, delete, import from, or build on top of any file inside `Tugas-*`.
- **Single sources of truth (read before planning or writing code):**
  1. `ROLE.md`: Global JSM HQ guardrails, team boundaries, library budget, and PR rules.
  2. `ronda_app/PRD.md`: Product scope, multi-tenant requirements, forensic photo check-in + dual verification rules, features, and acceptance criteria.
  3. `ronda_app/DESIGN.md`: Civic Operational visual system (Light & Dark), WCAG AA verified tokens, typography, component specs, screen map, and antislop constraints.
  4. `ronda_app/ARCHITECTURE.md`: Database schema, RLS policies, RPC/Edge Functions, FCM alarm contract, SQLite offline sync design, and folder ownership map.
  5. `plan.md`: Master phased task plan for JSM HQ boards and task creation.
- **Never edit `docs/plan.md` manually:** JSM HQ generates and overwrites `docs/plan.md` automatically whenever Export Plan is enabled. Always maintain human/lead planning in root `plan.md`.

## 2. Multi-Agent Team Roles & Strict Ownership

This project uses a 3-agent JSM HQ team:

### A. PM / Lead Agent (`lead`)
- **Owns:** `plan.md`, JSM HQ boards/tasks, PR review coordination, merge ordering, cross-agent contract alignment, and user escalations via `ask_user`.
- **Rules:**
  - Never writes application code directly.
  - Breaks work into atomic tasks (`1 task = 1 branch = 1 PR`) with strict, non-overlapping `files` lists so Front End and Back End work in parallel without merge conflicts.
  - Never merges PRs unless HQ explicitly switches merge authority to the lead.
  - Rejects PRs that touch unlisted files, introduce unapproved packages, skip tests, or violate `DESIGN.md` / `ARCHITECTURE.md`.

### B. Back End Agent (`backend`)
- **Owns:**
  - `ronda_app/supabase/**` (SQL migrations, RLS policies, Postgres RPCs, Storage policies, Edge Functions for FCM dispatch & SOS escalation, seed scripts).
  - `ronda_app/lib/core/config/**` (environment config via `--dart-define`, never hardcoded keys).
  - `ronda_app/lib/data/**` (Supabase repositories, SQLite offline database & sync worker, DTOs/mappers, forensic metadata & SHA-256 photo hash utilities, Haversine & QR verification services).
  - `ronda_app/lib/domain/**` (pure Dart models, enums, verification rule engine, schedule collision rules).
  - `ronda_app/test/unit/**` and `ronda_app/test/integration/**` (unit tests for domain rules, verification engine, SQLite queue, and repositories).
- **Rules:**
  - Enforces multi-tenant isolation (`site_id`) in PostgreSQL Row-Level Security (RLS) on every table and storage object. Never trust client-supplied `role` or `site_id` without checking `site_memberships`.
  - Every check-in runs automated integrity checks server-side (and mirrors preview locally when offline) and persists full forensic evidence for manual Admin audit override.
  - Never swallows Supabase errors silently (`catch` blocks must map to typed `AppFailure` errors).

### C. Front End Agent (`frontend`)
- **Owns:**
  - `ronda_app/lib/core/theme/**` (Material 3 Light & Dark theme, `ThemeExtension` tokens strictly matching `ronda_app/DESIGN.md`).
  - `ronda_app/lib/core/router/**` (`go_router` configuration, role & site-membership guards, SOS deep links).
  - `ronda_app/lib/presentation/**` (screens, reusable components, role shells, map UI, calendar UI, scanner/camera UI, manual audit review UI).
  - `ronda_app/lib/providers/**` (Riverpod state notifiers binding UI to repository interfaces from Back End).
  - `ronda_app/assets/**` (bundled fonts, alarm audio asset, minimal SVG icons if approved).
  - `ronda_app/test/widget/**` (widget tests for critical flows and UI states).
- **Rules:**
  - Follows `ronda_app/DESIGN.md` token-for-token in both Light Mode and Dark Mode.
  - Never builds UI screens exceeding ~350 lines in a single file; decompose into focused widgets under each feature folder.
  - Never re-invents complex UI primitives already solved by approved lightweight packages (e.g., use `table_calendar` for schedule calendars and `flutter_map` for interactive maps).
  - Every data-driven screen must implement real Empty, Loading, and Error states with clear causes and next actions.
  - Never fabricates mock statistics, fake names, fake testimonials, or dead buttons.

### Shared Files Protocol
- `ronda_app/pubspec.yaml`, `ronda_app/android/**`, and `ronda_app/ios/**` are shared configuration files. Only edit them when explicitly listed in your assigned task's `files`, and never add dependencies outside the approved manifest in `ronda_app/ARCHITECTURE.md` without Lead approval.

## 3. Dependency & App Size Guardrails (Anti-Bloat Policy)

- **Do not re-invent the wheel, and do not bloat APK size.**
- Before adding any package to `ronda_app/pubspec.yaml`, verify it is listed in the Approved Dependency Manifest in `ronda_app/ARCHITECTURE.md`.
- **Prefer pure-Dart or OS-native bindings:**
  - Maps: `flutter_map` + `latlong2` (pure Dart, OpenStreetMap). Do NOT add Google Maps SDK or Mapbox native SDKs.
  - Calendar: `table_calendar` (pure Dart). Do NOT write custom 1,000-line calendar widgets.
  - Offline SQLite: `sqflite` + `path` (uses OS built-in SQLite, near-zero APK size impact). Do NOT add `sqlite3_flutter_libs` unless strictly approved.
  - UI Components: Material 3 + custom `ThemeExtension`. Do NOT add heavy all-in-one UI suites (GetWidget, Syncfusion, Fluent UI).
  - Fonts: Bundle only 3 weights of `Plus Jakarta Sans` (Regular 400, Medium 500, SemiBold/Bold 600-700) and 1 weight of `JetBrains Mono` (Regular 400, strictly for forensic coordinates/timestamps/QR codes) locally in `ronda_app/assets/fonts/` for offline reliability and low size.
  - Sensors: Do NOT add `sensors_plus` or `flutter_compass` unless explicitly requested later; keep metadata focused on GPS, accuracy, `isMocked`, timestamp, photo SHA-256, and optional device battery/model info.
- Always build release artifacts with `--tree-shake-icons` and split ABIs (`--split-per-abi`). Target Android arm64 release APK size: <= 25 MB.

## 4. Antislop & Craftsmanship Guardrails

- **No em dashes (`U+2014`)** in any UI copy, documentation, or code comments. Use commas, periods, colons, or parentheses.
- **No decorative emojis** in UI headings, labels, buttons, badges, or snackbars. Use meaningful Material Symbols / icons paired with clear Indonesian text.
- **No AI buzzwords or fake data:** Never display invented metrics, fake user counts, or placeholder names disguised as real people (`John Doe`, etc.).
- **Dual-theme integrity:** Both Light Mode and Dark Mode must pass WCAG AA contrast (4.5:1 normal text, 3:1 large text and interactive UI borders).
- **No dead controls:** Every button, tab, menu item, and form must perform its real action.

## 5. Secrets, Security & Environment Handling

- **Never commit secrets or live credentials:** Never commit `.env`, `.env.local`, `google-services.json`, `GoogleService-Info.plist`, `secret.dart`, `secrets.dart`, keystores, or Supabase service role keys.
- Use `--dart-define` / `--dart-define-from-file` for Flutter runtime configuration (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) and document placeholders in `ronda_app/.env.example`.
- When external setup is needed (creating Supabase project, deploying Edge Functions, uploading Firebase `google-services.json` or FCM server key), call `ask_user` with step-by-step instructions and variable names only. Never request secret values in plain text inside prompts or source files.

## 6. Git, PR & Pre-Review Verification Standards

- **Branching:** Always run `git pull origin main` before creating a feature branch (`feat/<task-id>-short-slug`, `fix/<task-id>-short-slug`, `chore/<task-id>-short-slug`).
- **Commit format:** `type(ronda_app): concise summary` (e.g., `feat(ronda_app): add multi-tenant rls migrations`).
- **PR title format:** `[TASK-ID] Short descriptive title`.
- **Mandatory checks before calling `set_my_status(in-review)`:**
  - Inside `ronda_app/`, run:
    1. `flutter analyze` (must exit 0 with zero errors and zero warnings).
    2. `flutter test` (all relevant unit and widget tests must pass).
  - For Back End SQL tasks, verify migration idempotency and SQL syntax cleanly before opening the PR.
  - Never include untracked agent runtime files (`.jsmhq-role.md`, `.agents/`, `.claude/`, `GEMINI.md`) in any commit.
