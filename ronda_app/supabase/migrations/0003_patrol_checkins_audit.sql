-- 0003_patrol_checkins_audit.sql
-- Forensic patrol check-ins, immutable audit trail, automated integrity engine, and manual review RPC.

CREATE TABLE IF NOT EXISTS public.patrol_checkins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_event_id uuid NOT NULL UNIQUE,
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  checkpoint_id uuid NOT NULL REFERENCES public.checkpoints(id) ON DELETE CASCADE,
  -- Foreign key to public.patrol_schedules is attached in 0004_schedule_swap_handover.sql.
  schedule_id uuid,
  officer_id uuid NOT NULL REFERENCES public.profiles(id),
  qr_token_version_scanned integer NOT NULL,
  photo_path text NOT NULL,
  photo_sha256 text NOT NULL DEFAULT '',
  captured_at_client timestamptz NOT NULL,
  synced_at_server timestamptz NOT NULL DEFAULT now(),
  latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  accuracy_m double precision NOT NULL CHECK (accuracy_m >= 0),
  distance_m double precision NOT NULL CHECK (distance_m >= 0),
  is_mocked boolean NOT NULL DEFAULT false,
  is_offline_submission boolean NOT NULL DEFAULT false,
  device_model text,
  officer_note text NOT NULL DEFAULT '',
  auto_status text NOT NULL CHECK (
    auto_status IN ('auto_verified', 'flagged_review', 'auto_rejected')
  ),
  flag_reasons text[] NOT NULL DEFAULT '{}',
  manual_status text CHECK (
    manual_status IN ('manual_approved', 'manual_rejected')
  ),
  reviewed_by uuid REFERENCES public.profiles(id),
  reviewed_at timestamptz,
  review_note text,
  effective_status text GENERATED ALWAYS AS (coalesce(manual_status, auto_status)) STORED,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.checkin_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checkin_id uuid NOT NULL REFERENCES public.patrol_checkins(id) ON DELETE CASCADE,
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES public.profiles(id),
  action text NOT NULL CHECK (
    action IN ('auto_evaluated', 'manual_approved', 'manual_rejected')
  ),
  previous_status text,
  new_status text NOT NULL,
  note text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_patrol_checkins_site_captured
  ON public.patrol_checkins (site_id, captured_at_client DESC);

CREATE INDEX IF NOT EXISTS idx_patrol_checkins_site_effective_status
  ON public.patrol_checkins (site_id, effective_status, captured_at_client DESC);

CREATE INDEX IF NOT EXISTS idx_patrol_checkins_site_officer
  ON public.patrol_checkins (site_id, officer_id, captured_at_client DESC);

CREATE INDEX IF NOT EXISTS idx_patrol_checkins_site_checkpoint
  ON public.patrol_checkins (site_id, checkpoint_id, captured_at_client DESC);

CREATE INDEX IF NOT EXISTS idx_patrol_checkins_schedule
  ON public.patrol_checkins (schedule_id);

CREATE INDEX IF NOT EXISTS idx_checkin_audit_logs_checkin_created
  ON public.checkin_audit_logs (checkin_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_checkin_audit_logs_site_created
  ON public.checkin_audit_logs (site_id, created_at DESC);

ALTER TABLE public.patrol_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checkin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Staff and admins read site check-ins; writes happen strictly through RPCs.
DROP POLICY IF EXISTS patrol_checkins_select_staff ON public.patrol_checkins;
CREATE POLICY patrol_checkins_select_staff
  ON public.patrol_checkins
  FOR SELECT
  TO authenticated
  USING (public.is_site_staff(site_id));

-- Audit logs are read-only for site staff; direct inserts, updates, and deletes are blocked.
DROP POLICY IF EXISTS checkin_audit_logs_select_staff ON public.checkin_audit_logs;
CREATE POLICY checkin_audit_logs_select_staff
  ON public.checkin_audit_logs
  FOR SELECT
  TO authenticated
  USING (public.is_site_staff(site_id));

CREATE OR REPLACE FUNCTION public.submit_patrol_checkin(p_payload jsonb)
RETURNS public.patrol_checkins
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_client_event_id uuid;
  v_site_id uuid;
  v_checkpoint_id uuid;
  v_schedule_id uuid;
  v_qr_raw_payload text;
  v_photo_path text;
  v_photo_sha256 text;
  v_captured_at timestamptz;
  v_lat double precision;
  v_lng double precision;
  v_accuracy_m double precision;
  v_is_mocked boolean;
  v_is_offline boolean;
  v_device_model text;
  v_officer_note text;
  v_role text;
  v_existing public.patrol_checkins;
  v_checkpoint public.checkpoints;
  v_qr_parts text[];
  v_qr_version integer := 0;
  v_expected_hmac text;
  v_qr_valid boolean := false;
  v_distance_m double precision;
  v_extreme_limit_m double precision;
  v_has_hard_fail boolean := false;
  v_has_soft_flag boolean := false;
  v_flag_reasons text[] := '{}';
  v_auto_status text;
  v_has_active_shift boolean := false;
  v_has_any_scheduled_shift boolean := false;
  v_skew_seconds double precision;
  v_result public.patrol_checkins;
  v_audit_note text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan untuk mengirim check-in patroli.'
      USING ERRCODE = '42501';
  END IF;

  v_client_event_id := (p_payload ->> 'client_event_id')::uuid;
  v_site_id := (p_payload ->> 'site_id')::uuid;
  v_checkpoint_id := (p_payload ->> 'checkpoint_id')::uuid;
  v_schedule_id := nullif(trim(coalesce(p_payload ->> 'schedule_id', '')), '')::uuid;
  v_qr_raw_payload := coalesce(trim(p_payload ->> 'qr_raw_payload'), '');
  v_photo_path := coalesce(trim(p_payload ->> 'photo_path'), '');
  v_photo_sha256 := lower(coalesce(trim(p_payload ->> 'photo_sha256'), ''));
  v_captured_at := (p_payload ->> 'captured_at_client')::timestamptz;
  v_lat := (p_payload ->> 'latitude')::double precision;
  v_lng := (p_payload ->> 'longitude')::double precision;
  v_accuracy_m := coalesce((p_payload ->> 'accuracy_m')::double precision, 999.0);
  v_is_mocked := coalesce((p_payload ->> 'is_mocked')::boolean, false);
  v_is_offline := coalesce((p_payload ->> 'is_offline_submission')::boolean, false);
  v_device_model := nullif(trim(coalesce(p_payload ->> 'device_model', '')), '');
  v_officer_note := coalesce(trim(p_payload ->> 'officer_note'), '');

  IF v_client_event_id IS NULL
     OR v_site_id IS NULL
     OR v_checkpoint_id IS NULL
     OR v_captured_at IS NULL
     OR v_lat IS NULL
     OR v_lng IS NULL THEN
    RAISE EXCEPTION 'Payload check-in tidak lengkap.'
      USING ERRCODE = '22023';
  END IF;

  -- Idempotency check for offline sync retries.
  SELECT *
  INTO v_existing
  FROM public.patrol_checkins
  WHERE client_event_id = v_client_event_id;

  IF FOUND THEN
    IF v_existing.officer_id <> v_user_id AND NOT public.is_site_admin(v_existing.site_id) THEN
      RAISE EXCEPTION 'Anda tidak memiliki izin mengakses check-in ini.'
        USING ERRCODE = '42501';
    END IF;
    RETURN v_existing;
  END IF;

  v_role := public.current_site_role(v_site_id);
  IF v_role IS NULL OR v_role NOT IN ('officer', 'admin') THEN
    RAISE EXCEPTION 'Hanya petugas patroli aktif di wilayah ini yang dapat melakukan check-in.'
      USING ERRCODE = '42501';
  END IF;

  -- Admins may check in only when they also have a scheduled shift in this site.
  IF v_role = 'admin' THEN
    SELECT EXISTS (
      SELECT 1
      FROM public.patrol_schedules ps
      WHERE ps.site_id = v_site_id
        AND ps.officer_id = v_user_id
        AND ps.status IN ('scheduled', 'completed')
    )
    INTO v_has_any_scheduled_shift;

    IF NOT v_has_any_scheduled_shift THEN
      RAISE EXCEPTION 'Admin hanya dapat melakukan check-in jika memiliki jadwal patroli di wilayah ini.'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  SELECT *
  INTO v_checkpoint
  FROM public.checkpoints
  WHERE id = v_checkpoint_id
    AND site_id = v_site_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pos patroli tidak ditemukan pada wilayah aktif.'
      USING ERRCODE = 'P0002';
  END IF;

  -- Rule 1: Signed QR payload verification (RD1|<site_id>|<checkpoint_id>|<version>|<hmac>).
  v_qr_parts := string_to_array(v_qr_raw_payload, '|');
  IF v_checkpoint.is_active
     AND array_length(v_qr_parts, 1) = 5
     AND v_qr_parts[1] = 'RD1'
     AND v_qr_parts[2] = v_site_id::text
     AND v_qr_parts[3] = v_checkpoint_id::text
     AND v_qr_parts[4] ~ '^[0-9]+$' THEN
    v_qr_version := v_qr_parts[4]::integer;
    IF v_qr_version = v_checkpoint.qr_token_version THEN
      v_expected_hmac := public.compute_checkpoint_qr_hmac(
        v_site_id,
        v_checkpoint_id,
        v_checkpoint.qr_token_version,
        v_checkpoint.qr_secret
      );
      IF lower(v_qr_parts[5]) = lower(v_expected_hmac) THEN
        v_qr_valid := true;
      END IF;
    END IF;
  ELSIF array_length(v_qr_parts, 1) >= 4 AND v_qr_parts[4] ~ '^[0-9]+$' THEN
    v_qr_version := v_qr_parts[4]::integer;
  END IF;

  IF NOT v_qr_valid THEN
    v_has_hard_fail := true;
    v_flag_reasons := array_append(v_flag_reasons, 'QR_INVALID_OR_REVOKED');
  END IF;

  -- Rule 2: Mock GPS detection.
  IF v_is_mocked THEN
    v_has_hard_fail := true;
    v_flag_reasons := array_append(v_flag_reasons, 'MOCK_GPS_DETECTED');
  END IF;

  -- Rule 3: Photo path ownership and SHA-256 format validation.
  IF v_photo_path = ''
     OR left(v_photo_path, length(v_site_id::text || '/checkins/' || v_user_id::text || '/'))
        <> (v_site_id::text || '/checkins/' || v_user_id::text || '/')
     OR v_photo_sha256 !~ '^[0-9a-f]{64}$' THEN
    v_has_hard_fail := true;
    v_flag_reasons := array_append(v_flag_reasons, 'PHOTO_HASH_MISSING_OR_MISMATCH');
  END IF;

  -- Rule 4 & 5: Server-side Haversine geofence check.
  v_distance_m := public.compute_haversine_m(
    v_lat,
    v_lng,
    v_checkpoint.latitude,
    v_checkpoint.longitude
  );
  v_extreme_limit_m := greatest(v_checkpoint.radius_m * 3.0, 150.0);

  IF v_distance_m > v_extreme_limit_m THEN
    v_has_hard_fail := true;
    v_flag_reasons := array_append(v_flag_reasons, 'OUTSIDE_GEOFENCE_EXTREME');
  ELSIF v_distance_m > v_checkpoint.radius_m THEN
    v_has_soft_flag := true;
    v_flag_reasons := array_append(v_flag_reasons, 'OUTSIDE_GEOFENCE_BORDERLINE');
  END IF;

  -- Rule 6: GPS accuracy check.
  IF v_accuracy_m > 35.0 THEN
    v_has_soft_flag := true;
    v_flag_reasons := array_append(v_flag_reasons, 'LOW_GPS_ACCURACY');
  END IF;

  -- Rule 7: Shift window check against assigned patrol_schedules.
  IF v_schedule_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1
      FROM public.patrol_schedules ps
      WHERE ps.id = v_schedule_id
        AND ps.site_id = v_site_id
        AND ps.officer_id = v_user_id
        AND ps.status IN ('scheduled', 'completed')
        AND v_captured_at BETWEEN ps.starts_at AND ps.ends_at
    )
    INTO v_has_active_shift;

    IF NOT EXISTS (
      SELECT 1
      FROM public.patrol_schedules ps
      WHERE ps.id = v_schedule_id
        AND ps.site_id = v_site_id
        AND ps.officer_id = v_user_id
    ) THEN
      v_schedule_id := NULL;
    END IF;
  ELSE
    SELECT ps.id
    INTO v_schedule_id
    FROM public.patrol_schedules ps
    WHERE ps.site_id = v_site_id
      AND ps.officer_id = v_user_id
      AND ps.status IN ('scheduled', 'completed')
      AND v_captured_at BETWEEN ps.starts_at AND ps.ends_at
    ORDER BY ps.starts_at ASC
    LIMIT 1;

    v_has_active_shift := v_schedule_id IS NOT NULL;
  END IF;

  IF NOT v_has_active_shift THEN
    v_has_soft_flag := true;
    v_flag_reasons := array_append(v_flag_reasons, 'OUTSIDE_SHIFT_WINDOW');
  END IF;

  -- Rule 8: Offline sync delay (> 30 min) or clock skew (> 5 min).
  v_skew_seconds := extract(epoch FROM (now() - v_captured_at));
  IF v_skew_seconds < -300.0
     OR (v_is_offline AND v_skew_seconds > 1800.0)
     OR (NOT v_is_offline AND v_skew_seconds > 300.0) THEN
    v_has_soft_flag := true;
    v_flag_reasons := array_append(v_flag_reasons, 'OFFLINE_DELAY_OR_CLOCK_SKEW');
  END IF;

  IF v_has_hard_fail THEN
    v_auto_status := 'auto_rejected';
  ELSIF v_has_soft_flag THEN
    v_auto_status := 'flagged_review';
  ELSE
    v_auto_status := 'auto_verified';
  END IF;

  INSERT INTO public.patrol_checkins (
    client_event_id,
    site_id,
    checkpoint_id,
    schedule_id,
    officer_id,
    qr_token_version_scanned,
    photo_path,
    photo_sha256,
    captured_at_client,
    synced_at_server,
    latitude,
    longitude,
    accuracy_m,
    distance_m,
    is_mocked,
    is_offline_submission,
    device_model,
    officer_note,
    auto_status,
    flag_reasons
  )
  VALUES (
    v_client_event_id,
    v_site_id,
    v_checkpoint_id,
    v_schedule_id,
    v_user_id,
    v_qr_version,
    v_photo_path,
    v_photo_sha256,
    v_captured_at,
    now(),
    v_lat,
    v_lng,
    v_accuracy_m,
    v_distance_m,
    v_is_mocked,
    v_is_offline,
    v_device_model,
    v_officer_note,
    v_auto_status,
    v_flag_reasons
  )
  ON CONFLICT (client_event_id) DO NOTHING
  RETURNING * INTO v_result;

  IF v_result.id IS NULL THEN
    SELECT *
    INTO v_result
    FROM public.patrol_checkins
    WHERE client_event_id = v_client_event_id;
    RETURN v_result;
  END IF;

  v_audit_note := CASE
    WHEN array_length(v_flag_reasons, 1) IS NULL THEN
      'Evaluasi otomatis lolos seluruh pemeriksaan integritas.'
    ELSE
      'Evaluasi otomatis menandai: ' || array_to_string(v_flag_reasons, ', ')
  END;

  INSERT INTO public.checkin_audit_logs (
    checkin_id,
    site_id,
    actor_id,
    action,
    previous_status,
    new_status,
    note
  )
  VALUES (
    v_result.id,
    v_site_id,
    NULL,
    'auto_evaluated',
    NULL,
    v_auto_status,
    v_audit_note
  );

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.review_patrol_checkin(
  p_checkin_id uuid,
  p_decision text,
  p_review_note text
)
RETURNS public.patrol_checkins
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_note text := trim(coalesce(p_review_note, ''));
  v_checkin public.patrol_checkins;
  v_previous_status text;
  v_updated public.patrol_checkins;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan untuk meninjau check-in.'
      USING ERRCODE = '42501';
  END IF;

  IF p_decision NOT IN ('manual_approved', 'manual_rejected') THEN
    RAISE EXCEPTION 'Keputusan audit harus manual_approved atau manual_rejected.'
      USING ERRCODE = '22023';
  END IF;

  IF char_length(v_note) < 5 THEN
    RAISE EXCEPTION 'Catatan audit manual minimal 5 karakter.'
      USING ERRCODE = '22023';
  END IF;

  SELECT *
  INTO v_checkin
  FROM public.patrol_checkins
  WHERE id = p_checkin_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Data check-in tidak ditemukan.'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT public.is_site_admin(v_checkin.site_id) THEN
    RAISE EXCEPTION 'Hanya admin wilayah yang dapat melakukan audit manual check-in.'
      USING ERRCODE = '42501';
  END IF;

  v_previous_status := v_checkin.effective_status;

  UPDATE public.patrol_checkins
  SET
    manual_status = p_decision,
    reviewed_by = v_user_id,
    reviewed_at = now(),
    review_note = v_note
  WHERE id = p_checkin_id
  RETURNING * INTO v_updated;

  INSERT INTO public.checkin_audit_logs (
    checkin_id,
    site_id,
    actor_id,
    action,
    previous_status,
    new_status,
    note
  )
  VALUES (
    v_updated.id,
    v_updated.site_id,
    v_user_id,
    p_decision,
    v_previous_status,
    p_decision,
    v_note
  );

  RETURN v_updated;
END;
$$;

-- Safe transparency summary RPC for residents without exposing forensic photos or audit flags.
CREATE OR REPLACE FUNCTION public.get_site_patrol_summary(
  p_site_id uuid,
  p_since timestamptz DEFAULT date_trunc('day', now())
)
RETURNS TABLE (
  checkpoint_id uuid,
  last_verified_at timestamptz,
  verified_count bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  IF NOT public.is_active_site_member(p_site_id) THEN
    RAISE EXCEPTION 'Anda bukan anggota aktif wilayah ini.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    c.id AS checkpoint_id,
    max(pc.captured_at_client) AS last_verified_at,
    count(pc.id) AS verified_count
  FROM public.checkpoints c
  LEFT JOIN public.patrol_checkins pc
    ON pc.checkpoint_id = c.id
   AND pc.site_id = p_site_id
   AND pc.effective_status IN ('auto_verified', 'manual_approved')
   AND pc.captured_at_client >= coalesce(p_since, date_trunc('day', now()))
  WHERE c.site_id = p_site_id
    AND c.is_active = true
  GROUP BY c.id;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_patrol_checkin(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.review_patrol_checkin(uuid, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_site_patrol_summary(uuid, timestamptz) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.submit_patrol_checkin(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_patrol_checkin(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_site_patrol_summary(uuid, timestamptz) TO authenticated;
