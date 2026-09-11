create table if not exists public.image_resolutions (
  id uuid primary key default gen_random_uuid(),
  cache_key text not null unique,
  title text not null,
  city text,
  country text,
  image_url text not null,
  provider text not null,
  source_url text,
  attribution text,
  score double precision not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_image_resolutions_title_city_country
on public.image_resolutions(title, city, country);

alter table public.image_resolutions enable row level security;

drop policy if exists "public read image resolutions" on public.image_resolutions;
create policy "public read image resolutions"
on public.image_resolutions for select
to anon, authenticated
using (true);

revoke insert, update, delete on public.image_resolutions from anon, authenticated;
grant select on public.image_resolutions to anon, authenticated;
