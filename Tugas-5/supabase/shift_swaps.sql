-- Jalankan di Supabase SQL Editor untuk membuat tabel tukar jadwal.
-- Akses RLS perlu dipasangkan dengan autentikasi dan keanggotaan RT aplikasi.
create table if not exists public.shift_swaps (
  id text primary key,
  rt_id text not null,
  schedule_id text not null,
  requester_id text not null,
  requester_name text not null,
  target_user_id text not null,
  target_user_name text not null,
  alasan text not null,
  requester_shift text not null default 'Shift Malam',
  target_date timestamptz,
  target_shift text not null default 'Shift Malam',
  status text not null default 'pending'
    check (status in ('pending', 'acceptedByTarget', 'approvedByAdmin', 'rejected', 'expired')),
  created_at timestamptz not null default now()
);

-- Upgrade tabel shift_swaps lama (CREATE TABLE IF NOT EXISTS tidak menambah kolom).
alter table public.shift_swaps
  add column if not exists rt_id text;

-- Data lama aplikasi ini berasal dari satu RT demo.
update public.shift_swaps
set rt_id = 'RT-04-RW-02-SUKOLILO'
where rt_id is null;

alter table public.shift_swaps
  alter column rt_id set not null;

create index if not exists shift_swaps_rt_created_idx
  on public.shift_swaps (rt_id, created_at desc);
create index if not exists shift_swaps_target_pending_idx
  on public.shift_swaps (rt_id, target_user_id, created_at desc)
  where status = 'pending';

alter table public.shift_swaps enable row level security;

-- Policy authenticated untuk instalasi Auth.
drop policy if exists "shift_swaps_select_rt_members" on public.shift_swaps;
create policy "shift_swaps_select_rt_members"
on public.shift_swaps for select to authenticated
using (rt_id = (auth.jwt() -> 'app_metadata' ->> 'rt_id'));

drop policy if exists "shift_swaps_insert_requester" on public.shift_swaps;
create policy "shift_swaps_insert_requester"
on public.shift_swaps for insert to authenticated
with check (
  rt_id = (auth.jwt() -> 'app_metadata' ->> 'rt_id')
  and requester_id = (auth.jwt() -> 'app_metadata' ->> 'ronda_user_id')
  and status = 'pending'
);

-- Respons hanya boleh dilakukan oleh petugas target atau admin RT terkait.
drop policy if exists "shift_swaps_update_target_or_admin" on public.shift_swaps;
create policy "shift_swaps_update_target_or_admin"
on public.shift_swaps for update to authenticated
using (
  rt_id = (auth.jwt() -> 'app_metadata' ->> 'rt_id')
  and (
    target_user_id = (auth.jwt() -> 'app_metadata' ->> 'ronda_user_id')
    or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin_rt'
  )
)
with check (
  rt_id = (auth.jwt() -> 'app_metadata' ->> 'rt_id')
  and (
    target_user_id = (auth.jwt() -> 'app_metadata' ->> 'ronda_user_id')
    or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin_rt'
  )
);

-- MODE DEMO (akun disimpan di ronda_demo_accounts, tanpa Supabase Auth).
-- Akses anon dibatasi ke satu RT demo; jangan gunakan policy ini untuk data nyata.
drop policy if exists "shift_swaps_demo_select" on public.shift_swaps;
create policy "shift_swaps_demo_select"
on public.shift_swaps for select to anon
using (rt_id = 'RT-04-RW-02-SUKOLILO');

drop policy if exists "shift_swaps_demo_insert" on public.shift_swaps;
create policy "shift_swaps_demo_insert"
on public.shift_swaps for insert to anon
with check (
  rt_id = 'RT-04-RW-02-SUKOLILO'
  and status = 'pending'
);

drop policy if exists "shift_swaps_demo_update" on public.shift_swaps;
create policy "shift_swaps_demo_update"
on public.shift_swaps for update to anon
using (rt_id = 'RT-04-RW-02-SUKOLILO')
with check (rt_id = 'RT-04-RW-02-SUKOLILO');

do $$
begin
  alter publication supabase_realtime add table public.shift_swaps;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;
