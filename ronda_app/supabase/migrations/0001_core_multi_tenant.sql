-- 0001_core_multi_tenant.sql
-- Core multi-tenant tables: profiles, sites, site_memberships, and checkpoints.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Resolve pgcrypto from either public or Supabase's extensions schema.
CREATE OR REPLACE FUNCTION public.generate_qr_secret()
RETURNS text
LANGUAGE plpgsql
VOLATILE
SET search_path = public, extensions
AS $$
BEGIN
  RETURN encode(gen_random_bytes(16), 'hex');
END;
$$;

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL DEFAULT '',
  phone_whatsapp text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.sites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  site_type text NOT NULL CHECK (
    site_type IN ('desa', 'perumahan', 'rt_rw', 'klaster', 'fasilitas', 'lainnya')
  ),
  address_summary text NOT NULL DEFAULT '',
  invite_code text NOT NULL UNIQUE CHECK (
    char_length(invite_code) = 8 AND invite_code = upper(invite_code)
  ),
  require_join_approval boolean NOT NULL DEFAULT true,
  center_lat double precision NOT NULL CHECK (center_lat BETWEEN -90 AND 90),
  center_lng double precision NOT NULL CHECK (center_lng BETWEEN -180 AND 180),
  default_geofence_m integer NOT NULL DEFAULT 30 CHECK (default_geofence_m BETWEEN 10 AND 200),
  sos_escalation_minutes integer NOT NULL DEFAULT 3 CHECK (sos_escalation_minutes BETWEEN 1 AND 30),
  created_by uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.site_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('admin', 'officer', 'resident')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended')),
  unit_address text NOT NULL DEFAULT '',
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (site_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.checkpoints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  code text NOT NULL CHECK (char_length(trim(code)) >= 1),
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  description text NOT NULL DEFAULT '',
  latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  radius_m integer NOT NULL DEFAULT 30 CHECK (radius_m BETWEEN 10 AND 200),
  sort_order integer NOT NULL DEFAULT 0,
  target_time_local text CHECK (
    target_time_local IS NULL OR target_time_local ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
  ),
  qr_token_version integer NOT NULL DEFAULT 1 CHECK (qr_token_version >= 1),
  qr_secret text NOT NULL DEFAULT public.generate_qr_secret(),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (site_id, code)
);

CREATE INDEX IF NOT EXISTS idx_site_memberships_user_status
  ON public.site_memberships (user_id, status);

CREATE INDEX IF NOT EXISTS idx_site_memberships_site_role_status
  ON public.site_memberships (site_id, role, status);

CREATE INDEX IF NOT EXISTS idx_checkpoints_site_active_order
  ON public.checkpoints (site_id, is_active, sort_order);

-- Auto-provision a profile row when a new Supabase Auth user signs up.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_full_name text;
  v_phone text;
BEGIN
  v_full_name := coalesce(
    nullif(trim(NEW.raw_user_meta_data ->> 'full_name'), ''),
    nullif(split_part(coalesce(NEW.email, ''), '@', 1), ''),
    'Pengguna'
  );
  v_phone := coalesce(trim(NEW.raw_user_meta_data ->> 'phone_whatsapp'), '');

  INSERT INTO public.profiles (id, full_name, phone_whatsapp)
  VALUES (NEW.id, v_full_name, v_phone)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

-- Column-level protection ensures checkpoints.qr_secret is never readable by client APIs.
REVOKE ALL ON public.checkpoints FROM anon, authenticated;
GRANT SELECT (
  id,
  site_id,
  code,
  name,
  description,
  latitude,
  longitude,
  radius_m,
  sort_order,
  target_time_local,
  qr_token_version,
  is_active,
  created_at
) ON public.checkpoints TO authenticated;
GRANT INSERT (
  site_id,
  code,
  name,
  description,
  latitude,
  longitude,
  radius_m,
  sort_order,
  target_time_local,
  is_active
) ON public.checkpoints TO authenticated;
GRANT UPDATE (
  code,
  name,
  description,
  latitude,
  longitude,
  radius_m,
  sort_order,
  target_time_local,
  is_active
) ON public.checkpoints TO authenticated;
GRANT DELETE ON public.checkpoints TO authenticated;

CREATE OR REPLACE VIEW public.checkpoints_public
WITH (security_invoker = true) AS
SELECT
  id,
  site_id,
  code,
  name,
  description,
  latitude,
  longitude,
  radius_m,
  sort_order,
  target_time_local,
  qr_token_version,
  is_active,
  created_at
FROM public.checkpoints;

GRANT SELECT ON public.checkpoints_public TO authenticated;
