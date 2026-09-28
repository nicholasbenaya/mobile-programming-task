-- ==============================================================================
-- MIGRASI 06: Tabel Komentar & Jejak Penghormatan Pahlawan
-- ==============================================================================
-- Tabel ini menyimpan komentar, doa, dan kesan yang disampaikan pengguna
-- untuk masing-masing pahlawan nasional.
-- ==============================================================================

create table if not exists public.hero_comments (
  id          bigint generated always as identity primary key,
  hero_id     text not null references public.heroes(id) on delete cascade,
  user_name   text not null default 'Pengunjung',
  content     text not null,
  created_at  timestamptz not null default now()
);

-- Index untuk mempercepat query komentar berdasarkan hero_id
create index if not exists hero_comments_hero_id_idx
  on public.hero_comments (hero_id, created_at desc);

-- Aktifkan Row Level Security (RLS)
alter table public.hero_comments enable row level security;

-- Kebijakan RLS:
-- 1. Semua pengguna (anon & authenticated) boleh membaca komentar
drop policy if exists "Semua orang boleh membaca hero_comments" on public.hero_comments;
create policy "Semua orang boleh membaca hero_comments"
  on public.hero_comments
  for select
  to anon, authenticated
  using (true);

-- 2. Semua pengguna boleh menambahkan komentar
drop policy if exists "Boleh menambah hero_comments" on public.hero_comments;
create policy "Boleh menambah hero_comments"
  on public.hero_comments
  for insert
  to anon, authenticated
  with check (true);

-- 3. Pengguna boleh menghapus komentar
drop policy if exists "Boleh menghapus hero_comments" on public.hero_comments;
create policy "Boleh menghapus hero_comments"
  on public.hero_comments
  for delete
  to anon, authenticated
  using (true);
