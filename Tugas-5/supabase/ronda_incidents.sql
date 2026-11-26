-- Penyimpanan metadata laporan insiden; foto tetap di bucket privat ronda-evidence.
create table if not exists public.incident_reports (
  id text primary key,
  rt_id text not null,
  user_id text not null,
  reporter_name text not null,
  category text not null,
  keterangan text not null,
  photo_path text not null,
  latitude double precision not null,
  longitude double precision not null,
  compass double precision,
  created_at timestamptz not null default now()
);

create index if not exists incident_reports_rt_created_idx
  on public.incident_reports (rt_id, created_at desc);

alter table public.incident_reports enable row level security;

drop policy if exists "incident_reports_select_rt_members" on public.incident_reports;
create policy "incident_reports_select_rt_members"
on public.incident_reports for select to authenticated
using (rt_id = (auth.jwt() -> 'app_metadata' ->> 'rt_id'));

drop policy if exists "incident_reports_insert_member" on public.incident_reports;
create policy "incident_reports_insert_member"
on public.incident_reports for insert to authenticated
with check (
  rt_id = (auth.jwt() -> 'app_metadata' ->> 'rt_id')
  and user_id = (auth.jwt() -> 'app_metadata' ->> 'ronda_user_id')
);

do $$
begin
  alter publication supabase_realtime add table public.incident_reports;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

notify pgrst, 'reload schema';
