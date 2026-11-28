-- 0002_rls_helpers.sql
-- Multi-tenant SECURITY DEFINER RLS helpers, core table RLS policies, and site/QR RPCs.

CREATE OR REPLACE FUNCTION public.is_active_site_member(p_site_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.site_memberships sm
    WHERE sm.site_id = p_site_id
      AND sm.user_id = auth.uid()
      AND sm.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION public.current_site_role(p_site_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT sm.role
  FROM public.site_memberships sm
  WHERE sm.site_id = p_site_id
    AND sm.user_id = auth.uid()
    AND sm.status = 'active'
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_site_admin(p_site_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.site_memberships sm
    WHERE sm.site_id = p_site_id
      AND sm.user_id = auth.uid()
      AND sm.status = 'active'
      AND sm.role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_site_staff(p_site_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.site_memberships sm
    WHERE sm.site_id = p_site_id
      AND sm.user_id = auth.uid()
      AND sm.status = 'active'
      AND sm.role IN ('admin', 'officer')
  );
$$;

CREATE OR REPLACE FUNCTION public.compute_haversine_m(
  p_lat1 double precision,
  p_lng1 double precision,
  p_lat2 double precision,
  p_lng2 double precision
)
RETURNS double precision
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public, extensions
AS $$
DECLARE
  v_earth_radius_m constant double precision := 6371000.0;
  v_dlat double precision;
  v_dlng double precision;
  v_a double precision;
  v_c double precision;
BEGIN
  v_dlat := radians(p_lat2 - p_lat1);
  v_dlng := radians(p_lng2 - p_lng1);
  v_a := power(sin(v_dlat / 2.0), 2)
    + cos(radians(p_lat1)) * cos(radians(p_lat2)) * power(sin(v_dlng / 2.0), 2);
  v_c := 2.0 * atan2(sqrt(least(1.0, greatest(0.0, v_a))), sqrt(greatest(0.0, 1.0 - v_a)));
  RETURN v_earth_radius_m * v_c;
END;
$$;

CREATE OR REPLACE FUNCTION public.compute_checkpoint_qr_hmac(
  p_site_id uuid,
  p_checkpoint_id uuid,
  p_token_version integer,
  p_qr_secret text
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public, extensions
AS $$
  SELECT encode(
    hmac(
      convert_to(
        'RD1|' || p_site_id::text || '|' || p_checkpoint_id::text || '|' || p_token_version::text,
        'UTF8'
      ),
      convert_to(p_qr_secret, 'UTF8'),
      'sha256'
    ),
    'hex'
  );
$$;

CREATE OR REPLACE FUNCTION public.generate_site_invite_code()
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  -- Exclude ambiguous glyphs (0, O, 1, I) for printed invite posters.
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_bytes bytea;
  v_code text;
  v_idx integer;
  v_attempt integer := 0;
BEGIN
  LOOP
    v_attempt := v_attempt + 1;
    IF v_attempt > 25 THEN
      RAISE EXCEPTION 'Gagal membuat kode undangan unik setelah beberapa percobaan.'
        USING ERRCODE = 'P0001';
    END IF;

    v_bytes := gen_random_bytes(8);
    v_code := '';
    FOR v_idx IN 0..7 LOOP
      v_code := v_code || substr(v_alphabet, (get_byte(v_bytes, v_idx) % length(v_alphabet)) + 1, 1);
    END LOOP;

    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.sites s WHERE s.invite_code = v_code
    );
  END LOOP;

  RETURN v_code;
END;
$$;

-- Enable RLS on core multi-tenant tables.
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checkpoints ENABLE ROW LEVEL SECURITY;

-- profiles policies
DROP POLICY IF EXISTS profiles_select_own_or_shared_site ON public.profiles;
CREATE POLICY profiles_select_own_or_shared_site
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.site_memberships mine
      JOIN public.site_memberships other
        ON other.site_id = mine.site_id
      WHERE mine.user_id = auth.uid()
        AND mine.status = 'active'
        AND other.user_id = profiles.id
        AND (
          other.status = 'active'
          OR mine.role = 'admin'
        )
    )
  );

DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
CREATE POLICY profiles_insert_own
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- sites policies (creation happens atomically via create_site_with_admin)
DROP POLICY IF EXISTS sites_select_member_or_pending ON public.sites;
CREATE POLICY sites_select_member_or_pending
  ON public.sites
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.site_memberships sm
      WHERE sm.site_id = sites.id
        AND sm.user_id = auth.uid()
        AND sm.status IN ('active', 'pending')
    )
  );

DROP POLICY IF EXISTS sites_update_admin ON public.sites;
CREATE POLICY sites_update_admin
  ON public.sites
  FOR UPDATE
  TO authenticated
  USING (public.is_site_admin(id))
  WITH CHECK (public.is_site_admin(id));

DROP POLICY IF EXISTS sites_delete_admin ON public.sites;
CREATE POLICY sites_delete_admin
  ON public.sites
  FOR DELETE
  TO authenticated
  USING (public.is_site_admin(id));

-- site_memberships policies (creation via RPCs; role/status mutation strictly admin-only)
DROP POLICY IF EXISTS site_memberships_select_scoped ON public.site_memberships;
CREATE POLICY site_memberships_select_scoped
  ON public.site_memberships
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_site_admin(site_id)
    OR (
      public.is_active_site_member(site_id)
      AND status = 'active'
    )
  );

DROP POLICY IF EXISTS site_memberships_update_admin ON public.site_memberships;
CREATE POLICY site_memberships_update_admin
  ON public.site_memberships
  FOR UPDATE
  TO authenticated
  USING (public.is_site_admin(site_id))
  WITH CHECK (public.is_site_admin(site_id));

DROP POLICY IF EXISTS site_memberships_delete_admin_or_self ON public.site_memberships;
CREATE POLICY site_memberships_delete_admin_or_self
  ON public.site_memberships
  FOR DELETE
  TO authenticated
  USING (
    public.is_site_admin(site_id)
    OR user_id = auth.uid()
  );

-- checkpoints policies
DROP POLICY IF EXISTS checkpoints_select_active_member ON public.checkpoints;
CREATE POLICY checkpoints_select_active_member
  ON public.checkpoints
  FOR SELECT
  TO authenticated
  USING (public.is_active_site_member(site_id));

DROP POLICY IF EXISTS checkpoints_insert_admin ON public.checkpoints;
CREATE POLICY checkpoints_insert_admin
  ON public.checkpoints
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_site_admin(site_id));

DROP POLICY IF EXISTS checkpoints_update_admin ON public.checkpoints;
CREATE POLICY checkpoints_update_admin
  ON public.checkpoints
  FOR UPDATE
  TO authenticated
  USING (public.is_site_admin(site_id))
  WITH CHECK (public.is_site_admin(site_id));

DROP POLICY IF EXISTS checkpoints_delete_admin ON public.checkpoints;
CREATE POLICY checkpoints_delete_admin
  ON public.checkpoints
  FOR DELETE
  TO authenticated
  USING (public.is_site_admin(site_id));

-- Authoritative multi-tenant RPCs
CREATE OR REPLACE FUNCTION public.create_site_with_admin(
  p_name text,
  p_site_type text,
  p_address text DEFAULT '',
  p_center_lat double precision DEFAULT -7.2575,
  p_center_lng double precision DEFAULT 112.7521,
  p_radius_m integer DEFAULT 30
)
RETURNS public.sites
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_invite_code text;
  v_site public.sites;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan untuk membuat wilayah.'
      USING ERRCODE = '42501';
  END IF;

  IF char_length(trim(coalesce(p_name, ''))) < 2 THEN
    RAISE EXCEPTION 'Nama wilayah minimal 2 karakter.'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.profiles (id, full_name, phone_whatsapp)
  VALUES (v_user_id, 'Admin Wilayah', '')
  ON CONFLICT (id) DO NOTHING;

  v_invite_code := public.generate_site_invite_code();

  INSERT INTO public.sites (
    name,
    site_type,
    address_summary,
    invite_code,
    center_lat,
    center_lng,
    default_geofence_m,
    created_by
  )
  VALUES (
    trim(p_name),
    p_site_type,
    coalesce(trim(p_address), ''),
    v_invite_code,
    p_center_lat,
    p_center_lng,
    p_radius_m,
    v_user_id
  )
  RETURNING * INTO v_site;

  INSERT INTO public.site_memberships (
    site_id,
    user_id,
    role,
    status
  )
  VALUES (
    v_site.id,
    v_user_id,
    'admin',
    'active'
  );

  RETURN v_site;
END;
$$;

CREATE OR REPLACE FUNCTION public.join_site_by_code(
  p_invite_code text,
  p_unit_address text DEFAULT ''
)
RETURNS public.site_memberships
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_normalized_code text;
  v_site public.sites;
  v_existing public.site_memberships;
  v_membership public.site_memberships;
  v_status text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan untuk bergabung ke wilayah.'
      USING ERRCODE = '42501';
  END IF;

  v_normalized_code := upper(trim(coalesce(p_invite_code, '')));
  IF char_length(v_normalized_code) <> 8 THEN
    RAISE EXCEPTION 'Kode undangan harus terdiri dari 8 karakter.'
      USING ERRCODE = '22023';
  END IF;

  SELECT *
  INTO v_site
  FROM public.sites
  WHERE invite_code = v_normalized_code;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Kode undangan tidak ditemukan.'
      USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.profiles (id, full_name, phone_whatsapp)
  VALUES (v_user_id, 'Warga', '')
  ON CONFLICT (id) DO NOTHING;

  SELECT *
  INTO v_existing
  FROM public.site_memberships
  WHERE site_id = v_site.id
    AND user_id = v_user_id;

  IF FOUND THEN
    IF v_existing.status = 'suspended' THEN
      RAISE EXCEPTION 'Keanggotaan Anda di wilayah ini sedang dinonaktifkan oleh admin.'
        USING ERRCODE = '42501';
    END IF;
    RETURN v_existing;
  END IF;

  v_status := CASE WHEN v_site.require_join_approval THEN 'pending' ELSE 'active' END;

  INSERT INTO public.site_memberships (
    site_id,
    user_id,
    role,
    status,
    unit_address
  )
  VALUES (
    v_site.id,
    v_user_id,
    'resident',
    v_status,
    coalesce(trim(p_unit_address), '')
  )
  RETURNING * INTO v_membership;

  RETURN v_membership;
END;
$$;

CREATE OR REPLACE FUNCTION public.regenerate_site_invite_code(p_site_id uuid)
RETURNS public.sites
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_site public.sites;
BEGIN
  IF NOT public.is_site_admin(p_site_id) THEN
    RAISE EXCEPTION 'Hanya admin wilayah yang dapat memperbarui kode undangan.'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.sites
  SET invite_code = public.generate_site_invite_code()
  WHERE id = p_site_id
  RETURNING * INTO v_site;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wilayah tidak ditemukan.'
      USING ERRCODE = 'P0002';
  END IF;

  RETURN v_site;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_my_unit_address(
  p_site_id uuid,
  p_unit_address text
)
RETURNS public.site_memberships
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_membership public.site_memberships;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan.'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.site_memberships
  SET unit_address = coalesce(trim(p_unit_address), '')
  WHERE site_id = p_site_id
    AND user_id = auth.uid()
    AND status IN ('active', 'pending')
  RETURNING * INTO v_membership;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Keanggotaan wilayah tidak ditemukan.'
      USING ERRCODE = 'P0002';
  END IF;

  RETURN v_membership;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_checkpoint_qr_payload(p_checkpoint_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_checkpoint public.checkpoints;
  v_signature text;
  v_payload text;
BEGIN
  SELECT *
  INTO v_checkpoint
  FROM public.checkpoints
  WHERE id = p_checkpoint_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pos patroli tidak ditemukan.'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT public.is_site_admin(v_checkpoint.site_id) THEN
    RAISE EXCEPTION 'Hanya admin wilayah yang dapat membuat atau mencetak QR pos.'
      USING ERRCODE = '42501';
  END IF;

  v_signature := public.compute_checkpoint_qr_hmac(
    v_checkpoint.site_id,
    v_checkpoint.id,
    v_checkpoint.qr_token_version,
    v_checkpoint.qr_secret
  );

  v_payload := 'RD1|'
    || v_checkpoint.site_id::text || '|'
    || v_checkpoint.id::text || '|'
    || v_checkpoint.qr_token_version::text || '|'
    || v_signature;

  RETURN jsonb_build_object(
    'checkpoint_id', v_checkpoint.id,
    'site_id', v_checkpoint.site_id,
    'code', v_checkpoint.code,
    'name', v_checkpoint.name,
    'qr_token_version', v_checkpoint.qr_token_version,
    'qr_payload', v_payload
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.regenerate_checkpoint_qr(p_checkpoint_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_checkpoint public.checkpoints;
BEGIN
  SELECT *
  INTO v_checkpoint
  FROM public.checkpoints
  WHERE id = p_checkpoint_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pos patroli tidak ditemukan.'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT public.is_site_admin(v_checkpoint.site_id) THEN
    RAISE EXCEPTION 'Hanya admin wilayah yang dapat mengganti token QR pos.'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.checkpoints
  SET
    qr_token_version = qr_token_version + 1,
    qr_secret = public.generate_qr_secret()
  WHERE id = p_checkpoint_id;

  RETURN public.get_checkpoint_qr_payload(p_checkpoint_id);
END;
$$;

REVOKE ALL ON FUNCTION public.is_active_site_member(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.current_site_role(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_site_admin(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_site_staff(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.generate_site_invite_code() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_site_with_admin(text, text, text, double precision, double precision, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.join_site_by_code(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.regenerate_site_invite_code(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_my_unit_address(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_checkpoint_qr_payload(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.regenerate_checkpoint_qr(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.is_active_site_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_site_role(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_site_admin(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_site_staff(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_site_with_admin(text, text, text, double precision, double precision, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_site_by_code(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.regenerate_site_invite_code(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_my_unit_address(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_checkpoint_qr_payload(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.regenerate_checkpoint_qr(uuid) TO authenticated;
