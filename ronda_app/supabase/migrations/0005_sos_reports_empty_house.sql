-- 0005_sos_reports_empty_house.sql
-- Emergency SOS events, non-SOS incident reports, privacy-scoped empty house watches, and FCM device tokens.

CREATE TABLE IF NOT EXISTS public.sos_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  reporter_id uuid NOT NULL REFERENCES public.profiles(id),
  category text NOT NULL DEFAULT 'darurat' CHECK (
    category IN ('pencurian', 'kebakaran', 'medis', 'orang_mencurigakan', 'darurat')
  ),
  latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  address_note text NOT NULL DEFAULT '',
  note text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'open' CHECK (
    status IN ('open', 'acknowledged', 'on_scene', 'resolved', 'cancelled_false_alarm')
  ),
  triggered_at timestamptz NOT NULL DEFAULT now(),
  escalated_at timestamptz,
  responder_id uuid REFERENCES public.profiles(id),
  acknowledged_at timestamptz,
  on_scene_at timestamptz,
  resolved_at timestamptz,
  resolution_note text,
  resolution_photo_path text,
  cancel_reason text
);

CREATE TABLE IF NOT EXISTS public.incident_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_event_id uuid UNIQUE,
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  reporter_id uuid NOT NULL REFERENCES public.profiles(id),
  category text NOT NULL CHECK (
    category IN (
      'orang_mencurigakan',
      'kerusakan_fasilitas',
      'lampu_mati',
      'vandalisme',
      'kebersihan',
      'lainnya'
    )
  ),
  title text NOT NULL CHECK (char_length(trim(title)) >= 3),
  description text NOT NULL CHECK (char_length(trim(description)) >= 5),
  photo_path text NOT NULL,
  latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  status text NOT NULL DEFAULT 'open' CHECK (
    status IN ('open', 'in_progress', 'resolved', 'rejected')
  ),
  handled_by uuid REFERENCES public.profiles(id),
  resolution_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.empty_house_watches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  resident_id uuid NOT NULL REFERENCES public.profiles(id),
  house_label text NOT NULL CHECK (char_length(trim(house_label)) >= 2),
  latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  start_date date NOT NULL,
  end_date date NOT NULL CHECK (end_date >= start_date),
  emergency_contact text NOT NULL CHECK (char_length(trim(emergency_contact)) >= 6),
  notes text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'active' CHECK (
    status IN ('active', 'returned', 'cancelled')
  ),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fcm_token text NOT NULL UNIQUE,
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sos_events_site_status_triggered
  ON public.sos_events (site_id, status, triggered_at DESC);

CREATE INDEX IF NOT EXISTS idx_sos_events_site_reporter
  ON public.sos_events (site_id, reporter_id, triggered_at DESC);

CREATE INDEX IF NOT EXISTS idx_sos_events_open_unescalated
  ON public.sos_events (triggered_at)
  WHERE status = 'open' AND escalated_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_incident_reports_site_status_created
  ON public.incident_reports (site_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_incident_reports_site_reporter
  ON public.incident_reports (site_id, reporter_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_empty_house_watches_site_active_dates
  ON public.empty_house_watches (site_id, status, start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user
  ON public.device_tokens (user_id);

-- Enforce 30-second anti-spam cooldown while an SOS from the same reporter is already open.
CREATE OR REPLACE FUNCTION public.enforce_sos_cooldown()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, extensions
AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.sos_events se
    WHERE se.site_id = NEW.site_id
      AND se.reporter_id = NEW.reporter_id
      AND se.status = 'open'
      AND se.triggered_at > now() - interval '30 seconds'
  ) THEN
    RAISE EXCEPTION 'Sinyal SOS aktif sudah terkirim. Tunggu 30 detik sebelum mengirim ulang.'
      USING ERRCODE = '23505';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_sos_cooldown ON public.sos_events;
CREATE TRIGGER trg_enforce_sos_cooldown
  BEFORE INSERT
  ON public.sos_events
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_sos_cooldown();

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, extensions
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_incident_reports_updated_at ON public.incident_reports;
CREATE TRIGGER trg_incident_reports_updated_at
  BEFORE UPDATE
  ON public.incident_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_device_tokens_updated_at ON public.device_tokens;
CREATE TRIGGER trg_device_tokens_updated_at
  BEFORE UPDATE
  ON public.device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_updated_at();

ALTER TABLE public.sos_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empty_house_watches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- sos_events policies
DROP POLICY IF EXISTS sos_events_select_staff_or_reporter ON public.sos_events;
CREATE POLICY sos_events_select_staff_or_reporter
  ON public.sos_events
  FOR SELECT
  TO authenticated
  USING (
    public.is_site_staff(site_id)
    OR (
      public.is_active_site_member(site_id)
      AND reporter_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS sos_events_insert_active_member ON public.sos_events;
CREATE POLICY sos_events_insert_active_member
  ON public.sos_events
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_active_site_member(site_id)
    AND reporter_id = auth.uid()
    AND status = 'open'
  );

DROP POLICY IF EXISTS sos_events_update_staff_or_self_cancel ON public.sos_events;
CREATE POLICY sos_events_update_staff_or_self_cancel
  ON public.sos_events
  FOR UPDATE
  TO authenticated
  USING (
    public.is_site_staff(site_id)
    OR (
      public.is_active_site_member(site_id)
      AND reporter_id = auth.uid()
      AND status IN ('open', 'acknowledged', 'on_scene')
    )
  )
  WITH CHECK (
    public.is_site_staff(site_id)
    OR (
      public.is_active_site_member(site_id)
      AND reporter_id = auth.uid()
      AND status = 'cancelled_false_alarm'
    )
  );

-- incident_reports policies
DROP POLICY IF EXISTS incident_reports_select_staff_or_reporter ON public.incident_reports;
CREATE POLICY incident_reports_select_staff_or_reporter
  ON public.incident_reports
  FOR SELECT
  TO authenticated
  USING (
    public.is_site_staff(site_id)
    OR (
      public.is_active_site_member(site_id)
      AND reporter_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS incident_reports_insert_active_member ON public.incident_reports;
CREATE POLICY incident_reports_insert_active_member
  ON public.incident_reports
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_active_site_member(site_id)
    AND reporter_id = auth.uid()
    AND status = 'open'
  );

DROP POLICY IF EXISTS incident_reports_update_staff ON public.incident_reports;
CREATE POLICY incident_reports_update_staff
  ON public.incident_reports
  FOR UPDATE
  TO authenticated
  USING (public.is_site_staff(site_id))
  WITH CHECK (public.is_site_staff(site_id));

-- empty_house_watches policies: strict privacy hides pins from other residents
DROP POLICY IF EXISTS empty_house_watches_select_owner_or_staff ON public.empty_house_watches;
CREATE POLICY empty_house_watches_select_owner_or_staff
  ON public.empty_house_watches
  FOR SELECT
  TO authenticated
  USING (
    public.is_site_staff(site_id)
    OR (
      public.is_active_site_member(site_id)
      AND resident_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS empty_house_watches_insert_owner ON public.empty_house_watches;
CREATE POLICY empty_house_watches_insert_owner
  ON public.empty_house_watches
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_active_site_member(site_id)
    AND resident_id = auth.uid()
    AND status = 'active'
  );

DROP POLICY IF EXISTS empty_house_watches_update_owner_or_admin ON public.empty_house_watches;
CREATE POLICY empty_house_watches_update_owner_or_admin
  ON public.empty_house_watches
  FOR UPDATE
  TO authenticated
  USING (
    public.is_site_admin(site_id)
    OR (
      public.is_active_site_member(site_id)
      AND resident_id = auth.uid()
    )
  )
  WITH CHECK (
    public.is_site_admin(site_id)
    OR (
      public.is_active_site_member(site_id)
      AND resident_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS empty_house_watches_delete_owner_or_admin ON public.empty_house_watches;
CREATE POLICY empty_house_watches_delete_owner_or_admin
  ON public.empty_house_watches
  FOR DELETE
  TO authenticated
  USING (
    public.is_site_admin(site_id)
    OR (
      public.is_active_site_member(site_id)
      AND resident_id = auth.uid()
    )
  );

-- device_tokens policies: strictly scoped to the token owner
DROP POLICY IF EXISTS device_tokens_manage_own ON public.device_tokens;
CREATE POLICY device_tokens_manage_own
  ON public.device_tokens
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
