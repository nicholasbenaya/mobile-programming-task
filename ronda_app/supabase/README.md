# Supabase Backend Setup & Migrations (`ronda_app/supabase/`)

This folder holds the idempotent PostgreSQL schema migrations, Row-Level Security (RLS) policies, private Storage rules, Realtime publication setup, and upcoming Phase 5 Edge Functions for **RondaDigital**.

Never commit `.env`, `.env.local`, service role keys, `google-services.json`, or `GoogleService-Info.plist` to Git.

## 1. Migration Inventory (Run Strictly in Order)

1. `migrations/0001_core_multi_tenant.sql`: `pgcrypto` setup, `profiles`, `sites`, `site_memberships`, `checkpoints` (with column-level `qr_secret` protection and `checkpoints_public` view), and auth profile provisioning trigger.
2. `migrations/0002_rls_helpers.sql`: `SECURITY DEFINER` tenant helpers (`is_active_site_member`, `current_site_role`, `is_site_admin`, `is_site_staff`), Haversine/QR HMAC helpers, core table RLS, and RPCs (`create_site_with_admin`, `join_site_by_code`, `regenerate_site_invite_code`, `update_my_unit_address`, `get_checkpoint_qr_payload`, `regenerate_checkpoint_qr`).
3. `migrations/0003_patrol_checkins_audit.sql`: `patrol_checkins`, immutable `checkin_audit_logs`, `submit_patrol_checkin` (Automated Integrity Engine), `review_patrol_checkin` (Manual Admin Audit Override), and resident transparency summary RPC (`get_site_patrol_summary`).
4. `migrations/0004_schedule_swap_handover.sql`: `shift_templates`, `patrol_schedules` (with overlap collision trigger and FK back-link from `patrol_checkins`), `shift_swaps` (single-pending unique index + 3-hour expiry trigger), `shift_handovers` (Buku Mutasi), and atomic `accept_shift_swap` RPC.
5. `migrations/0005_sos_reports_empty_house.sql`: `sos_events` (with 30-second anti-spam trigger), `incident_reports`, privacy-scoped `empty_house_watches` (other residents always see 0 rows), and `device_tokens`.
6. `migrations/0006_storage_and_realtime.sql`: Private `patrol-evidence` storage bucket (2 MB limit), path-scoped storage RLS (`<site_id>/<folder>/<auth.uid()>/<uuid>.jpg`), and `supabase_realtime` publication enrollment.

## 2. Applying Migrations to Your Supabase Project

### Option A: Supabase CLI (Recommended)

From `ronda_app/`:

```bash
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>
supabase db push
```

### Option B: Supabase Dashboard SQL Editor

1. Open your Supabase project Dashboard and go to **SQL Editor**.
2. Execute each file in `ronda_app/supabase/migrations/` strictly in order from `0001_core_multi_tenant.sql` through `0006_storage_and_realtime.sql`.
3. All migrations are idempotent and safe to re-run if interrupted.

## 3. Post-Migration Verification Queries

Run these checks in the Supabase SQL Editor after applying `0001..0006`:

```sql
-- 1. Confirm all 14 application tables exist with RLS enabled.
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles', 'sites', 'site_memberships', 'checkpoints',
    'shift_templates', 'patrol_schedules', 'shift_swaps', 'shift_handovers',
    'patrol_checkins', 'checkin_audit_logs', 'sos_events',
    'incident_reports', 'empty_house_watches', 'device_tokens'
  )
ORDER BY tablename;

-- 2. Confirm private patrol-evidence bucket exists (public = false).
SELECT id, public, file_size_limit FROM storage.buckets WHERE id = 'patrol-evidence';

-- 3. Confirm operational tables are enrolled in supabase_realtime.
SELECT tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime' AND schemaname = 'public'
ORDER BY tablename;

-- 4. Confirm authoritative RPCs exist.
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'create_site_with_admin',
    'join_site_by_code',
    'get_checkpoint_qr_payload',
    'regenerate_checkpoint_qr',
    'submit_patrol_checkin',
    'review_patrol_checkin',
    'accept_shift_swap'
  )
ORDER BY routine_name;
```

## 4. Flutter Client Runtime Configuration

1. Copy `ronda_app/.env.example` to `ronda_app/.env.local` (gitignored).
2. Fill in your project values from Supabase Dashboard (**Project Settings -> API**):
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY` (publishable/anon key)
3. Run Flutter using `--dart-define-from-file=.env.local`:

```bash
cd ronda_app
flutter run --dart-define-from-file=.env.local
```

When running inside JSM HQ, add `SUPABASE_URL` and `SUPABASE_ANON_KEY` under **Settings -> Sandbox -> App variables**.

## 5. Upcoming Phase 5 Edge Functions & FCM Secrets

Phase 5 (`P5-T01`) adds `functions/dispatch-sos-alert/` and `functions/escalate-stale-sos/`. Those functions will require setting the following Supabase Edge Function secrets (never placed in Flutter client code):
- `FIREBASE_PROJECT_ID`
- `FIREBASE_SERVICE_ACCOUNT_JSON`
