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

create index if not exists shift_swaps_rt_created_idx
  on public.shift_swaps (rt_id, created_at desc);
create index if not exists shift_swaps_target_pending_idx
  on public.shift_swaps (rt_id, target_user_id, created_at desc)
  where status = 'pending';

alter table public.shift_swaps enable row level security;

do $$
begin
  alter publication supabase_realtime add table public.shift_swaps;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;
