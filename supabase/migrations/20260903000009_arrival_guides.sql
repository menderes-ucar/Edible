create table if not exists public.arrival_guides (
  id uuid primary key default gen_random_uuid(),
  country_id uuid not null references public.countries(id) on delete cascade,
  city_id uuid not null references public.cities(id) on delete cascade,
  currency_code text,
  emergency_number text,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(country_id, city_id)
);

create table if not exists public.arrival_guide_translations (
  arrival_guide_id uuid not null references public.arrival_guides(id) on delete cascade,
  language_code text not null,
  airport_transfer text not null default '',
  taxi_tip text not null default '',
  sim_tip text not null default '',
  tipping_tip text not null default '',
  first_day_checklist text[] not null default '{}'::text[],
  scam_warnings text[] not null default '{}'::text[],
  must_try_titles text[] not null default '{}'::text[],
  basic_phrases jsonb not null default '[]'::jsonb,
  primary key (arrival_guide_id, language_code)
);

-- Compatibility with the existing remote schema: the table may already exist without this column.
alter table public.arrival_guides
  add column if not exists id uuid default gen_random_uuid();

-- Compatibility with the existing remote schema: some installations use guide_id instead of id.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'arrival_guides' and column_name = 'guide_id'
  ) then
    update public.arrival_guides
    set id = guide_id
    where id is distinct from guide_id;
  end if;
end $$;

alter table public.arrival_guides
  add column if not exists country_id uuid,
  add column if not exists city_id uuid,
  add column if not exists currency_code text,
  add column if not exists emergency_number text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

-- Compatibility with existing installations that identify the guide by country/city codes.
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='arrival_guides' and column_name='country_code') then
    update public.arrival_guides guide
    set country_id = country.id
    from public.countries country
    where guide.country_id is null
      and upper(guide.country_code) = upper(country.code);
  end if;

  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='arrival_guides' and column_name='city_code') then
    update public.arrival_guides guide
    set city_id = city.id
    from public.cities city
    where guide.city_id is null
      and guide.city_code = city.code;
  end if;
end $$;

alter table public.arrival_guides
  add column if not exists is_published boolean not null default true;

-- Compatibility with the existing remote schema: some installations use guide_id/item_id
-- and locale instead of the migration column names. Add the expected columns
-- before policies/functions reference them.
alter table public.arrival_guide_translations
  add column if not exists arrival_guide_id uuid,
  add column if not exists language_code text,
  add column if not exists airport_transfer text not null default '',
  add column if not exists taxi_tip text not null default '',
  add column if not exists sim_tip text not null default '',
  add column if not exists tipping_tip text not null default '',
  add column if not exists first_day_checklist text[] not null default '{}'::text[],
  add column if not exists scam_warnings text[] not null default '{}'::text[],
  add column if not exists must_try_titles text[] not null default '{}'::text[],
  add column if not exists basic_phrases jsonb not null default '[]'::jsonb;

do $$
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='arrival_guide_translations' and column_name='guide_id') then
    update public.arrival_guide_translations
    set arrival_guide_id = guide_id
    where arrival_guide_id is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='arrival_guide_translations' and column_name='locale') then
    update public.arrival_guide_translations
    set language_code = locale
    where language_code is null;
  end if;
end $$;

alter table public.arrival_guides enable row level security;
alter table public.arrival_guide_translations enable row level security;

drop policy if exists "public read published arrival guides"
on public.arrival_guides;

create policy "public read published arrival guides"
on public.arrival_guides
for select
to anon, authenticated
using (is_published = true);

drop policy if exists "public read arrival guide translations"
on public.arrival_guide_translations;

create policy "public read arrival guide translations"
on public.arrival_guide_translations
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.arrival_guides guide
    where guide.id = arrival_guide_id
      and guide.is_published = true
  )
);

drop function if exists public.get_arrival_guide(text, text, text);

create function public.get_arrival_guide(
  p_country_code text,
  p_city_name text,
  p_locale text default 'en'
)
returns table (
  country_code text,
  country_name text,
  city_name text,
  currency_code text,
  emergency_number text,
  airport_transfer text,
  taxi_tip text,
  sim_tip text,
  tipping_tip text,
  first_day_checklist text[],
  scam_warnings text[],
  must_try_titles text[],
  basic_phrases jsonb
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    country.code as country_code,
    coalesce(country_tr.display_name, country_en.display_name, country.default_name) as country_name,
    coalesce(city_tr.display_name, city_en.display_name, city.default_name) as city_name,
    guide.currency_code,
    guide.emergency_number,
    coalesce(tr.airport_transfer, en.airport_transfer, '') as airport_transfer,
    coalesce(tr.taxi_tip, en.taxi_tip, '') as taxi_tip,
    coalesce(tr.sim_tip, en.sim_tip, '') as sim_tip,
    coalesce(tr.tipping_tip, en.tipping_tip, '') as tipping_tip,
    coalesce(tr.first_day_checklist, en.first_day_checklist, '{}'::text[]) as first_day_checklist,
    coalesce(tr.scam_warnings, en.scam_warnings, '{}'::text[]) as scam_warnings,
    coalesce(tr.must_try_titles, en.must_try_titles, '{}'::text[]) as must_try_titles,
    coalesce(tr.basic_phrases, en.basic_phrases, '[]'::jsonb) as basic_phrases
  from public.arrival_guides guide
  join public.countries country on country.id = guide.country_id
  join public.cities city on city.id = guide.city_id
  left join public.country_translations country_tr
    on country_tr.country_id = country.id
   and country_tr.locale = p_locale
  left join public.country_translations country_en
    on country_en.country_id = country.id
   and country_en.locale = 'en'
  left join public.city_translations city_tr
    on city_tr.city_id = city.id
   and city_tr.locale = p_locale
  left join public.city_translations city_en
    on city_en.city_id = city.id
   and city_en.locale = 'en'
  left join public.arrival_guide_translations tr
    on tr.arrival_guide_id = guide.id
   and tr.language_code = p_locale
  left join public.arrival_guide_translations en
    on en.arrival_guide_id = guide.id
   and en.language_code = 'en'
  where upper(country.code) = upper(p_country_code)
    and lower(coalesce(city_tr.display_name, city_en.display_name, city.default_name)) =
        lower(p_city_name)
    and guide.is_published = true
  limit 1;
$$;

grant execute on function public.get_arrival_guide(text, text, text)
to anon, authenticated;
