-- 0006_storage_and_realtime.sql
-- Private patrol-evidence storage bucket, path-scoped multi-tenant RLS, and Realtime publication.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'patrol-evidence',
  'patrol-evidence',
  false,
  2097152,
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Safely parse UUID segments in storage paths without throwing on malformed paths.
CREATE OR REPLACE FUNCTION public.try_parse_uuid(p_text text)
RETURNS uuid
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public, extensions
AS $$
BEGIN
  IF p_text IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN p_text::uuid;
EXCEPTION
  WHEN invalid_text_representation THEN
    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.try_parse_uuid(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.try_parse_uuid(text) TO authenticated;

-- Expected storage path contract: <site_id>/<folder>/<auth.uid()>/<uuid>.jpg
-- where <folder> is one of: checkins, handovers, incidents, sos.
DROP POLICY IF EXISTS patrol_evidence_insert ON storage.objects;
CREATE POLICY patrol_evidence_insert
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'patrol-evidence'
    AND array_length(storage.foldername(name), 1) = 3
    AND public.try_parse_uuid((storage.foldername(name))[1]) IS NOT NULL
    AND public.try_parse_uuid((storage.foldername(name))[3]) = auth.uid()
    AND (
      (
        (storage.foldername(name))[2] IN ('checkins', 'handovers')
        AND public.is_site_staff(public.try_parse_uuid((storage.foldername(name))[1]))
      )
      OR (
        (storage.foldername(name))[2] IN ('incidents', 'sos')
        AND public.is_active_site_member(public.try_parse_uuid((storage.foldername(name))[1]))
      )
    )
  );

DROP POLICY IF EXISTS patrol_evidence_select ON storage.objects;
CREATE POLICY patrol_evidence_select
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'patrol-evidence'
    AND array_length(storage.foldername(name), 1) = 3
    AND public.try_parse_uuid((storage.foldername(name))[1]) IS NOT NULL
    AND (
      (
        (storage.foldername(name))[2] IN ('checkins', 'handovers')
        AND public.is_site_staff(public.try_parse_uuid((storage.foldername(name))[1]))
      )
      OR (
        (storage.foldername(name))[2] IN ('incidents', 'sos')
        AND (
          public.is_site_staff(public.try_parse_uuid((storage.foldername(name))[1]))
          OR (
            public.is_active_site_member(public.try_parse_uuid((storage.foldername(name))[1]))
            AND public.try_parse_uuid((storage.foldername(name))[3]) = auth.uid()
          )
        )
      )
    )
  );

-- Allow idempotent offline retry upserts only for the original uploader's own path.
DROP POLICY IF EXISTS patrol_evidence_update ON storage.objects;
CREATE POLICY patrol_evidence_update
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'patrol-evidence'
    AND array_length(storage.foldername(name), 1) = 3
    AND public.try_parse_uuid((storage.foldername(name))[1]) IS NOT NULL
    AND public.try_parse_uuid((storage.foldername(name))[3]) = auth.uid()
    AND (
      (
        (storage.foldername(name))[2] IN ('checkins', 'handovers')
        AND public.is_site_staff(public.try_parse_uuid((storage.foldername(name))[1]))
      )
      OR (
        (storage.foldername(name))[2] IN ('incidents', 'sos')
        AND public.is_active_site_member(public.try_parse_uuid((storage.foldername(name))[1]))
      )
    )
  )
  WITH CHECK (
    bucket_id = 'patrol-evidence'
    AND array_length(storage.foldername(name), 1) = 3
    AND public.try_parse_uuid((storage.foldername(name))[1]) IS NOT NULL
    AND public.try_parse_uuid((storage.foldername(name))[3]) = auth.uid()
    AND (
      (
        (storage.foldername(name))[2] IN ('checkins', 'handovers')
        AND public.is_site_staff(public.try_parse_uuid((storage.foldername(name))[1]))
      )
      OR (
        (storage.foldername(name))[2] IN ('incidents', 'sos')
        AND public.is_active_site_member(public.try_parse_uuid((storage.foldername(name))[1]))
      )
    )
  );

-- Only site admins may delete evidence objects.
DROP POLICY IF EXISTS patrol_evidence_delete ON storage.objects;
CREATE POLICY patrol_evidence_delete
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'patrol-evidence'
    AND array_length(storage.foldername(name), 1) = 3
    AND public.try_parse_uuid((storage.foldername(name))[1]) IS NOT NULL
    AND public.is_site_admin(public.try_parse_uuid((storage.foldername(name))[1]))
  );

-- Register operational tables on supabase_realtime idempotently.
DO $$
DECLARE
  v_table text;
  v_tables text[] := ARRAY[
    'site_memberships',
    'checkpoints',
    'patrol_schedules',
    'shift_swaps',
    'shift_handovers',
    'patrol_checkins',
    'sos_events',
    'incident_reports',
    'empty_house_watches'
  ];
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_publication
    WHERE pubname = 'supabase_realtime'
  ) THEN
    FOREACH v_table IN ARRAY v_tables LOOP
      IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = v_table
      ) THEN
        EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', v_table);
      END IF;
    END LOOP;
  END IF;
END;
$$;
