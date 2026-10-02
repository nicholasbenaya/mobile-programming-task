-- Jalankan di Supabase Dashboard > SQL Editor.
-- Aktifkan juga: Authentication > Providers > "Allow anonymous sign-ins".

create table if not exists public.records (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now(),
  title       text not null check (char_length(title) between 1 and 100),
  category    text not null check (category in ('observasi','lingkungan','infrastruktur','lainnya')),
  note        text not null default '' check (char_length(note) <= 1000),
  latitude    double precision not null check (latitude between -90 and 90),
  longitude   double precision not null check (longitude between -180 and 180),
  accuracy    double precision check (accuracy >= 0),
  compass     double precision check (compass between 0 and 360),
  tilt        double precision check (tilt between -180 and 180),
  battery     double precision check (battery between 0 and 100),
  photo_path  text not null
);

create index if not exists records_user_created_idx on public.records (user_id, created_at desc);

alter table public.records enable row level security;

create policy "records_select_own" on public.records
  for select to authenticated using (auth.uid() = user_id);
create policy "records_insert_own" on public.records
  for insert to authenticated with check (auth.uid() = user_id);
create policy "records_update_own" on public.records
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "records_delete_own" on public.records
  for delete to authenticated using (auth.uid() = user_id);

-- Bucket foto (publik untuk dibaca, hanya pemilik yang boleh upload/hapus)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('record-photos', 'record-photos', true, 8388608, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy "photos_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'record-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'record-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos_select_all" on storage.objects
  for select using (bucket_id = 'record-photos');
