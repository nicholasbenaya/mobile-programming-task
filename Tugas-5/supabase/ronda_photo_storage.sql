-- Bucket privat untuk foto laporan, bukti SOS, dan dokumentasi ronda.
-- Role/rt_id wajib disimpan di app_metadata oleh backend tepercaya (mis. Admin API).
-- Jangan menerima role atau rt_id dari user_metadata / input aplikasi.
-- Path file: <rt_id>/<auth.uid()>/<uuid>.<jpg|jpeg|png|webp>

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'ronda-evidence',
  'ronda-evidence',
  false,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = 8388608,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

drop policy if exists "ronda_evidence_insert_member" on storage.objects;
create policy "ronda_evidence_insert_member"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'ronda-evidence'
  and (storage.foldername(name))[1] = (auth.jwt() -> 'app_metadata' ->> 'rt_id')
  and (storage.foldername(name))[2] = auth.uid()::text
  and coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '')
      in ('admin_rt', 'petugas_ronda', 'warga')
);

-- Pemilik foto dapat melihatnya; Ketua RT dapat melihat seluruh bukti di RT-nya.
drop policy if exists "ronda_evidence_select_member_or_admin" on storage.objects;
create policy "ronda_evidence_select_member_or_admin"
on storage.objects for select to authenticated
using (
  bucket_id = 'ronda-evidence'
  and (storage.foldername(name))[1] = (auth.jwt() -> 'app_metadata' ->> 'rt_id')
  and (
    (storage.foldername(name))[2] = auth.uid()::text
    or coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'admin_rt'
  )
);

drop policy if exists "ronda_evidence_delete_owner_or_admin" on storage.objects;
create policy "ronda_evidence_delete_owner_or_admin"
on storage.objects for delete to authenticated
using (
  bucket_id = 'ronda-evidence'
  and (storage.foldername(name))[1] = (auth.jwt() -> 'app_metadata' ->> 'rt_id')
  and (
    (storage.foldername(name))[2] = auth.uid()::text
    or coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'admin_rt'
  )
);

drop policy if exists "ronda_evidence_update_owner" on storage.objects;
create policy "ronda_evidence_update_owner"
on storage.objects for update to authenticated
using (
  bucket_id = 'ronda-evidence'
  and (storage.foldername(name))[1] = (auth.jwt() -> 'app_metadata' ->> 'rt_id')
  and (storage.foldername(name))[2] = auth.uid()::text
)
with check (
  bucket_id = 'ronda-evidence'
  and (storage.foldername(name))[1] = (auth.jwt() -> 'app_metadata' ->> 'rt_id')
  and (storage.foldername(name))[2] = auth.uid()::text
);
