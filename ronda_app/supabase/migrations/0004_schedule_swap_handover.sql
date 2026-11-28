-- 0004_schedule_swap_handover.sql
-- Shift templates, patrol schedules, collision checks, peer shift swaps, and Buku Mutasi handovers.

CREATE TABLE IF NOT EXISTS public.shift_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  start_time time NOT NULL,
  end_time time NOT NULL,
  is_overnight boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.patrol_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  officer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  template_id uuid REFERENCES public.shift_templates(id) ON DELETE SET NULL,
  shift_name text NOT NULL CHECK (char_length(trim(shift_name)) >= 2),
  shift_date date NOT NULL,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL CHECK (ends_at > starts_at),
  status text NOT NULL DEFAULT 'scheduled' CHECK (
    status IN ('scheduled', 'completed', 'absent', 'swapped')
  ),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Link patrol_checkins.schedule_id now that public.patrol_schedules exists.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'patrol_checkins_schedule_id_fkey'
      AND conrelid = 'public.patrol_checkins'::regclass
  ) THEN
    ALTER TABLE public.patrol_checkins
      ADD CONSTRAINT patrol_checkins_schedule_id_fkey
      FOREIGN KEY (schedule_id)
      REFERENCES public.patrol_schedules(id)
      ON DELETE SET NULL;
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.shift_swaps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  schedule_id uuid NOT NULL REFERENCES public.patrol_schedules(id) ON DELETE CASCADE,
  requester_id uuid NOT NULL REFERENCES public.profiles(id),
  target_officer_id uuid NOT NULL REFERENCES public.profiles(id),
  target_schedule_id uuid REFERENCES public.patrol_schedules(id) ON DELETE SET NULL,
  reason text NOT NULL CHECK (char_length(trim(reason)) >= 3),
  status text NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'accepted', 'rejected', 'expired', 'admin_overridden')
  ),
  expires_at timestamptz NOT NULL,
  responded_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (requester_id <> target_officer_id)
);

-- Enforce max 1 pending swap per schedule assignment.
CREATE UNIQUE INDEX IF NOT EXISTS idx_shift_swaps_single_pending
  ON public.shift_swaps (schedule_id)
  WHERE status = 'pending';

CREATE TABLE IF NOT EXISTS public.shift_handovers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id uuid NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  from_schedule_id uuid REFERENCES public.patrol_schedules(id) ON DELETE SET NULL,
  author_id uuid NOT NULL REFERENCES public.profiles(id),
  summary text NOT NULL CHECK (char_length(trim(summary)) >= 3),
  asset_status text NOT NULL DEFAULT '',
  photo_path text,
  acknowledged_by uuid REFERENCES public.profiles(id),
  acknowledged_at timestamptz,
  client_event_id uuid UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shift_templates_site_active
  ON public.shift_templates (site_id, is_active);

CREATE INDEX IF NOT EXISTS idx_patrol_schedules_site_date
  ON public.patrol_schedules (site_id, shift_date);

CREATE INDEX IF NOT EXISTS idx_patrol_schedules_site_officer_window
  ON public.patrol_schedules (site_id, officer_id, starts_at, ends_at);

CREATE INDEX IF NOT EXISTS idx_shift_swaps_site_status
  ON public.shift_swaps (site_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_shift_handovers_site_created
  ON public.shift_handovers (site_id, created_at DESC);

-- Prevent overlapping shift assignments for the same officer within a site.
CREATE OR REPLACE FUNCTION public.prevent_overlapping_patrol_schedules()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, extensions
AS $$
BEGIN
  IF current_setting('rondadigital.bypass_collision_during_swap', true) = 'on' THEN
    RETURN NEW;
  END IF;

  IF NEW.status NOT IN ('scheduled', 'completed') THEN
    RETURN NEW;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.patrol_schedules ps
    WHERE ps.site_id = NEW.site_id
      AND ps.officer_id = NEW.officer_id
      AND ps.id <> coalesce(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
      AND ps.status IN ('scheduled', 'completed')
      AND NEW.starts_at < ps.ends_at
      AND NEW.ends_at > ps.starts_at
  ) THEN
    RAISE EXCEPTION 'Petugas sudah memiliki jadwal patroli yang bentrok pada rentang waktu tersebut.'
      USING ERRCODE = '23505';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_overlapping_patrol_schedules ON public.patrol_schedules;
CREATE TRIGGER trg_prevent_overlapping_patrol_schedules
  BEFORE INSERT OR UPDATE OF officer_id, starts_at, ends_at, status
  ON public.patrol_schedules
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_overlapping_patrol_schedules();

-- Compute 3-hour pre-shift expiration and validate schedule ownership on swap creation.
CREATE OR REPLACE FUNCTION public.prepare_shift_swap_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_schedule public.patrol_schedules;
  v_target_schedule public.patrol_schedules;
BEGIN
  SELECT *
  INTO v_schedule
  FROM public.patrol_schedules
  WHERE id = NEW.schedule_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Jadwal shift yang akan ditukar tidak ditemukan.'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_schedule.site_id <> NEW.site_id THEN
    RAISE EXCEPTION 'Jadwal shift tidak cocok dengan wilayah aktif.'
      USING ERRCODE = '42501';
  END IF;

  IF v_schedule.officer_id <> NEW.requester_id THEN
    RAISE EXCEPTION 'Anda hanya dapat mengajukan tukar shift untuk jadwal milik Anda sendiri.'
      USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.site_memberships sm
    WHERE sm.site_id = NEW.site_id
      AND sm.user_id = NEW.target_officer_id
      AND sm.status = 'active'
      AND sm.role IN ('officer', 'admin')
  ) THEN
    RAISE EXCEPTION 'Petugas pengganti bukan staf aktif di wilayah ini.'
      USING ERRCODE = '22023';
  END IF;

  IF NEW.target_schedule_id IS NOT NULL THEN
    SELECT *
    INTO v_target_schedule
    FROM public.patrol_schedules
    WHERE id = NEW.target_schedule_id
      AND site_id = NEW.site_id
      AND officer_id = NEW.target_officer_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Jadwal tukar timbal balik tidak valid untuk petugas tujuan.'
        USING ERRCODE = '22023';
    END IF;
  END IF;

  NEW.expires_at := v_schedule.starts_at - interval '3 hours';
  IF now() >= NEW.expires_at THEN
    RAISE EXCEPTION 'Permintaan tukar shift harus diajukan minimal 3 jam sebelum shift dimulai.'
      USING ERRCODE = '22023';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prepare_shift_swap_insert ON public.shift_swaps;
CREATE TRIGGER trg_prepare_shift_swap_insert
  BEFORE INSERT
  ON public.shift_swaps
  FOR EACH ROW
  EXECUTE FUNCTION public.prepare_shift_swap_insert();

ALTER TABLE public.shift_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patrol_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_swaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_handovers ENABLE ROW LEVEL SECURITY;

-- shift_templates policies
DROP POLICY IF EXISTS shift_templates_select_member ON public.shift_templates;
CREATE POLICY shift_templates_select_member
  ON public.shift_templates
  FOR SELECT
  TO authenticated
  USING (public.is_active_site_member(site_id));

DROP POLICY IF EXISTS shift_templates_manage_admin ON public.shift_templates;
CREATE POLICY shift_templates_manage_admin
  ON public.shift_templates
  FOR ALL
  TO authenticated
  USING (public.is_site_admin(site_id))
  WITH CHECK (public.is_site_admin(site_id));

-- patrol_schedules policies (transparent roster for all active members; admin manages)
DROP POLICY IF EXISTS patrol_schedules_select_member ON public.patrol_schedules;
CREATE POLICY patrol_schedules_select_member
  ON public.patrol_schedules
  FOR SELECT
  TO authenticated
  USING (public.is_active_site_member(site_id));

DROP POLICY IF EXISTS patrol_schedules_manage_admin ON public.patrol_schedules;
CREATE POLICY patrol_schedules_manage_admin
  ON public.patrol_schedules
  FOR ALL
  TO authenticated
  USING (public.is_site_admin(site_id))
  WITH CHECK (public.is_site_admin(site_id));

-- shift_swaps policies (acceptance happens atomically via accept_shift_swap RPC)
DROP POLICY IF EXISTS shift_swaps_select_staff ON public.shift_swaps;
CREATE POLICY shift_swaps_select_staff
  ON public.shift_swaps
  FOR SELECT
  TO authenticated
  USING (public.is_site_staff(site_id));

DROP POLICY IF EXISTS shift_swaps_insert_requester ON public.shift_swaps;
CREATE POLICY shift_swaps_insert_requester
  ON public.shift_swaps
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_site_staff(site_id)
    AND requester_id = auth.uid()
    AND status = 'pending'
  );

DROP POLICY IF EXISTS shift_swaps_update_reject_or_admin ON public.shift_swaps;
CREATE POLICY shift_swaps_update_reject_or_admin
  ON public.shift_swaps
  FOR UPDATE
  TO authenticated
  USING (
    public.is_site_admin(site_id)
    OR (
      public.is_site_staff(site_id)
      AND target_officer_id = auth.uid()
      AND status = 'pending'
    )
  )
  WITH CHECK (
    public.is_site_admin(site_id)
    OR (
      target_officer_id = auth.uid()
      AND status = 'rejected'
    )
  );

-- shift_handovers (Buku Mutasi) policies: strictly site staff
DROP POLICY IF EXISTS shift_handovers_select_staff ON public.shift_handovers;
CREATE POLICY shift_handovers_select_staff
  ON public.shift_handovers
  FOR SELECT
  TO authenticated
  USING (public.is_site_staff(site_id));

DROP POLICY IF EXISTS shift_handovers_insert_staff ON public.shift_handovers;
CREATE POLICY shift_handovers_insert_staff
  ON public.shift_handovers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_site_staff(site_id)
    AND author_id = auth.uid()
  );

DROP POLICY IF EXISTS shift_handovers_update_staff ON public.shift_handovers;
CREATE POLICY shift_handovers_update_staff
  ON public.shift_handovers
  FOR UPDATE
  TO authenticated
  USING (public.is_site_staff(site_id))
  WITH CHECK (public.is_site_staff(site_id));

-- Atomic peer shift swap acceptance RPC with collision check and expiration guard.
CREATE OR REPLACE FUNCTION public.accept_shift_swap(p_swap_id uuid)
RETURNS public.shift_swaps
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_swap public.shift_swaps;
  v_schedule public.patrol_schedules;
  v_target_schedule public.patrol_schedules;
  v_is_admin boolean := false;
  v_new_status text;
  v_updated public.shift_swaps;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan untuk menyetujui tukar shift.'
      USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO v_swap
  FROM public.shift_swaps
  WHERE id = p_swap_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Permintaan tukar shift tidak ditemukan.'
      USING ERRCODE = 'P0002';
  END IF;

  v_is_admin := public.is_site_admin(v_swap.site_id);
  IF v_swap.target_officer_id <> v_user_id AND NOT v_is_admin THEN
    RAISE EXCEPTION 'Hanya petugas tujuan atau admin wilayah yang dapat menyetujui tukar shift ini.'
      USING ERRCODE = '42501';
  END IF;

  IF v_swap.status <> 'pending' THEN
    RAISE EXCEPTION 'Permintaan tukar shift sudah diproses sebelumnya.'
      USING ERRCODE = '23505';
  END IF;

  IF now() >= v_swap.expires_at THEN
    UPDATE public.shift_swaps
    SET
      status = 'expired',
      responded_at = now()
    WHERE id = p_swap_id;

    RAISE EXCEPTION 'Permintaan tukar shift sudah kedaluwarsa (kurang dari 3 jam sebelum shift).'
      USING ERRCODE = '23505';
  END IF;

  SELECT *
  INTO v_schedule
  FROM public.patrol_schedules
  WHERE id = v_swap.schedule_id
  FOR UPDATE;

  IF NOT FOUND OR v_schedule.officer_id <> v_swap.requester_id THEN
    RAISE EXCEPTION 'Jadwal asal sudah berubah dan tidak dapat ditukar.'
      USING ERRCODE = '23505';
  END IF;

  IF v_swap.target_schedule_id IS NOT NULL THEN
    SELECT *
    INTO v_target_schedule
    FROM public.patrol_schedules
    WHERE id = v_swap.target_schedule_id
    FOR UPDATE;

    IF NOT FOUND OR v_target_schedule.officer_id <> v_swap.target_officer_id THEN
      RAISE EXCEPTION 'Jadwal pengganti sudah berubah dan tidak dapat ditukar.'
        USING ERRCODE = '23505';
    END IF;
  END IF;

  -- Check collision for target officer taking v_schedule.
  IF EXISTS (
    SELECT 1
    FROM public.patrol_schedules ps
    WHERE ps.site_id = v_swap.site_id
      AND ps.officer_id = v_swap.target_officer_id
      AND ps.id <> v_schedule.id
      AND (v_swap.target_schedule_id IS NULL OR ps.id <> v_swap.target_schedule_id)
      AND ps.status IN ('scheduled', 'completed')
      AND v_schedule.starts_at < ps.ends_at
      AND v_schedule.ends_at > ps.starts_at
  ) THEN
    RAISE EXCEPTION 'Petugas pengganti memiliki jadwal bentrok pada tanggal shift tersebut.'
      USING ERRCODE = '23505';
  END IF;

  -- Check collision for requester taking v_target_schedule on reciprocal swaps.
  IF v_swap.target_schedule_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1
      FROM public.patrol_schedules ps
      WHERE ps.site_id = v_swap.site_id
        AND ps.officer_id = v_swap.requester_id
        AND ps.id <> v_schedule.id
        AND ps.id <> v_target_schedule.id
        AND ps.status IN ('scheduled', 'completed')
        AND v_target_schedule.starts_at < ps.ends_at
        AND v_target_schedule.ends_at > ps.starts_at
    ) THEN
      RAISE EXCEPTION 'Pengaju tukar shift memiliki jadwal bentrok pada shift balasan tersebut.'
        USING ERRCODE = '23505';
    END IF;
  END IF;

  PERFORM set_config('rondadigital.bypass_collision_during_swap', 'on', true);

  UPDATE public.patrol_schedules
  SET officer_id = v_swap.target_officer_id
  WHERE id = v_schedule.id;

  IF v_swap.target_schedule_id IS NOT NULL THEN
    UPDATE public.patrol_schedules
    SET officer_id = v_swap.requester_id
    WHERE id = v_target_schedule.id;
  END IF;

  PERFORM set_config('rondadigital.bypass_collision_during_swap', 'off', true);

  v_new_status := CASE
    WHEN v_swap.target_officer_id = v_user_id THEN 'accepted'
    ELSE 'admin_overridden'
  END;

  UPDATE public.shift_swaps
  SET
    status = v_new_status,
    responded_at = now()
  WHERE id = p_swap_id
  RETURNING * INTO v_updated;

  RETURN v_updated;
END;
$$;

REVOKE ALL ON FUNCTION public.accept_shift_swap(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_shift_swap(uuid) TO authenticated;
