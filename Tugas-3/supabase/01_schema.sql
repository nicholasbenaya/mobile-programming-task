create table if not exists public.heroes (
  id              text primary key,
  sort_order      int  not null default 0,
  name            text not null,
  known_as        text not null,
  origin_city     text not null,
  origin_province text not null,
  region_group    text not null,
  birth_date      text not null,
  birth_place     text not null,
  death_date      text not null,
  death_place     text not null,
  age_at_death    int  not null,
  photo_path      text not null,
  short_bio       text not null,
  full_bio        text not null,
  struggle_era    text not null,
  famous_quote    text not null,
  quote_context   text not null,
  decree_number   text not null,
  burial_place    text not null
);

create table if not exists public.hero_contributions (
  id           bigint generated always as identity primary key,
  hero_id      text not null references public.heroes(id) on delete cascade,
  contribution text not null,
  sort_order   int  not null default 0
);
create unique index if not exists hero_contributions_hero_text_idx
  on public.hero_contributions (hero_id, contribution);

create table if not exists public.quiz_questions (
  id            text primary key,
  sort_order    int  not null default 0,
  hero_id       text not null references public.heroes(id) on delete cascade,
  question      text not null,
  correct_index int  not null,
  explanation   text not null
);

create table if not exists public.quiz_options (
  id           bigint generated always as identity primary key,
  question_id  text not null references public.quiz_questions(id) on delete cascade,
  option_index int  not null,
  option_text  text not null
);

create table if not exists public.favorites (
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  hero_id    text not null references public.heroes(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, hero_id)
);

alter table public.heroes             enable row level security;
alter table public.hero_contributions enable row level security;
alter table public.quiz_questions     enable row level security;
alter table public.quiz_options       enable row level security;
alter table public.favorites          enable row level security;

create policy "Semua orang boleh membaca heroes"
  on public.heroes for select to anon, authenticated using (true);
create policy "Pengguna terautentikasi boleh menambah heroes"
  on public.heroes for insert to authenticated with check (true);
create policy "Pengguna terautentikasi boleh mengubah heroes"
  on public.heroes for update to authenticated using (true) with check (true);
create policy "Pengguna terautentikasi boleh menghapus heroes"
  on public.heroes for delete to authenticated using (true);
create policy "Semua orang boleh membaca hero_contributions"
  on public.hero_contributions for select to anon, authenticated using (true);
create policy "Semua orang boleh membaca quiz_questions"
  on public.quiz_questions for select to anon, authenticated using (true);
create policy "Semua orang boleh membaca quiz_options"
  on public.quiz_options for select to anon, authenticated using (true);

create policy "User membaca favorit sendiri"
  on public.favorites for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "User menambah favorit sendiri"
  on public.favorites for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "User menghapus favorit sendiri"
  on public.favorites for delete to authenticated
  using ((select auth.uid()) = user_id);
