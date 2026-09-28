-- ==============================================================================
-- MIGRASI 05: Perbaikan Row Level Security (RLS) untuk Operasi CRUD Pahlawan
-- ==============================================================================
-- Masalah:
-- Sebelumnya kebijakan RLS pada tabel `heroes` dan `hero_contributions` hanya
-- mengizinkan role `authenticated`. Karena aplikasi klien Flutter menggunakan
-- kunci publishable anonim tanpa login akun terlebih dahulu, Supabase menolak
-- operasi INSERT, UPDATE, dan DELETE dengan pesan error RLS (code 42501).
--
-- Solusi:
-- Memberikan izin kepada role `anon` dan `authenticated` untuk melakukan
-- operasi CRUD penuh pada tabel pahlawan.
-- ==============================================================================

-- 1. Hapus kebijakan lama yang membatasi hanya untuk authenticated
drop policy if exists "Pengguna terautentikasi boleh menambah heroes" on public.heroes;
drop policy if exists "Pengguna terautentikasi boleh mengubah heroes" on public.heroes;
drop policy if exists "Pengguna terautentikasi boleh menghapus heroes" on public.heroes;

drop policy if exists "Boleh menambah heroes" on public.heroes;
drop policy if exists "Boleh mengubah heroes" on public.heroes;
drop policy if exists "Boleh menghapus heroes" on public.heroes;

-- 2. Buat kebijakan baru yang mengizinkan anon & authenticated untuk CRUD heroes
create policy "Boleh menambah heroes"
  on public.heroes
  for insert
  to anon, authenticated
  with check (true);

create policy "Boleh mengubah heroes"
  on public.heroes
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Boleh menghapus heroes"
  on public.heroes
  for delete
  to anon, authenticated
  using (true);

-- 3. Kebijakan serupa untuk tabel relasi kontribusi pahlawan
drop policy if exists "Boleh menambah hero_contributions" on public.hero_contributions;
drop policy if exists "Boleh mengubah hero_contributions" on public.hero_contributions;
drop policy if exists "Boleh menghapus hero_contributions" on public.hero_contributions;

create policy "Boleh menambah hero_contributions"
  on public.hero_contributions
  for insert
  to anon, authenticated
  with check (true);

create policy "Boleh mengubah hero_contributions"
  on public.hero_contributions
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Boleh menghapus hero_contributions"
  on public.hero_contributions
  for delete
  to anon, authenticated
  using (true);
