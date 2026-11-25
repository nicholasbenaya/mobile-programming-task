-- Akun DEMO Ronda tanpa Supabase Auth.
-- Jalankan seluruh file ini sekali di Supabase Dashboard > SQL Editor.
-- Hanya cocok untuk demo: semua sesi aplikasi memakai role anon, bukan identitas Auth.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.ronda_demo_accounts (
  id text primary key,
  rt_id text not null,
  nama_lengkap text not null,
  nomor_whatsapp text not null unique,
  alamat_rumah text not null,
  role text not null check (role in ('admin_rt', 'petugas_ronda', 'warga')),
  fcm_token text,
  password_hash text not null,
  password_salt text not null
);

alter table public.ronda_demo_accounts enable row level security;
revoke all on public.ronda_demo_accounts from anon, authenticated;

create or replace function public.ronda_demo_login(
  p_whatsapp text,
  p_password text
)
returns table (
  id text,
  rt_id text,
  nama_lengkap text,
  nomor_whatsapp text,
  alamat_rumah text,
  role text,
  fcm_token text
)
language sql
security definer
set search_path = ''
as $$
  select a.id, a.rt_id, a.nama_lengkap, a.nomor_whatsapp,
         a.alamat_rumah, a.role, a.fcm_token
  from public.ronda_demo_accounts a
  where a.nomor_whatsapp = regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g')
    and a.password_hash = encode(
      extensions.digest(coalesce(p_password, '') || a.password_salt, 'sha256'),
      'hex'
    )
  limit 1;
$$;

revoke all on function public.ronda_demo_login(text, text) from public;
grant execute on function public.ronda_demo_login(text, text) to anon, authenticated;

-- Password semua akun demo: password123
-- INSERT ini aman diulang dan ID-nya sama dengan SeedData aplikasi.
insert into public.ronda_demo_accounts
  (id, rt_id, nama_lengkap, nomor_whatsapp, alamat_rumah, role, fcm_token,
   password_hash, password_salt)
values
  ('user-rt-01', 'RT-04-RW-02-SUKOLILO', 'Nicholas Benaya (Ketua RT)', '081234567801', 'Jl. Teknik Komputer No. 01, RT 04', 'admin_rt', 'fcm_token_admin_rt_01', encode(extensions.digest('password123ronda_salt_its_kelompok_4', 'sha256'), 'hex'), 'ronda_salt_its_kelompok_4'),
  ('user-petugas-01', 'RT-04-RW-02-SUKOLILO', 'Jordi (Petugas Ronda)', '081234567802', 'Jl. Gebang Putih Blok A No. 10', 'petugas_ronda', 'fcm_token_petugas_jordi', encode(extensions.digest('password123ronda_salt_its_kelompok_4', 'sha256'), 'hex'), 'ronda_salt_its_kelompok_4'),
  ('user-petugas-02', 'RT-04-RW-02-SUKOLILO', 'Devi Putri Sekar Arum', '081234567803', 'Jl. Gebang Putih Blok B No. 04', 'petugas_ronda', 'fcm_token_petugas_devi', encode(extensions.digest('password123ronda_salt_its_kelompok_4', 'sha256'), 'hex'), 'ronda_salt_its_kelompok_4'),
  ('user-petugas-03', 'RT-04-RW-02-SUKOLILO', 'Budi Santoso (Petugas Ronda)', '081234567806', 'Jl. Gebang Timur Blok C No. 08', 'petugas_ronda', 'fcm_token_petugas_budi', encode(extensions.digest('password123ronda_salt_its_kelompok_4', 'sha256'), 'hex'), 'ronda_salt_its_kelompok_4'),
  ('user-warga-01', 'RT-04-RW-02-SUKOLILO', 'Fito Dwi Ardiansah (Warga)', '081234567804', 'Jl. Gebang Timur No. 15', 'warga', 'fcm_token_warga_fito', encode(extensions.digest('password123ronda_salt_its_kelompok_4', 'sha256'), 'hex'), 'ronda_salt_its_kelompok_4')
on conflict (id) do update set
  rt_id = excluded.rt_id,
  nama_lengkap = excluded.nama_lengkap,
  nomor_whatsapp = excluded.nomor_whatsapp,
  alamat_rumah = excluded.alamat_rumah,
  role = excluded.role,
  fcm_token = excluded.fcm_token,
  password_hash = excluded.password_hash,
  password_salt = excluded.password_salt;
