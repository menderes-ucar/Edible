create table if not exists public.culture_guide_items (
  id uuid primary key default gen_random_uuid(),
  country_id uuid not null references public.countries(id) on delete cascade,
  city_id uuid references public.cities(id) on delete cascade,
  tip_type text not null check (
    tip_type in (
      'doTip',
      'dontTip',
      'tipping',
      'transport',
      'religiousPlace',
      'touristMistake',
      'safety',
      'scam',
      'phrase'
    )
  ),
  priority integer not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Remote databases may already contain this table with an older schema.
alter table public.culture_guide_items
  add column if not exists country_id uuid;

-- Remote deployments may use an older culture guide schema without publication state.
-- Add the compatibility column before the RLS policy references it.
alter table public.culture_guide_items
  add column if not exists is_published boolean not null default true;

-- Backfill the compatibility column when the existing schema uses country_code.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'culture_guide_items'
      and column_name = 'country_code'
  ) then
    update public.culture_guide_items item
    set country_id = country.id
    from public.countries country
    where item.country_id is null
      and upper(item.country_code) = upper(country.code);
  end if;
end $$;

create index if not exists idx_culture_guide_country_city
on public.culture_guide_items(country_id, city_id, priority desc);

create table if not exists public.culture_guide_translations (
  guide_item_id uuid not null references public.culture_guide_items(id) on delete cascade,
  language_code text not null,
  title text not null,
  body text not null default '',
  phrase_local text,
  phrase_pronunciation text,
  phrase_translation text,
  primary key (guide_item_id, language_code)
);

-- Existing deployments may use a legacy translation schema without the FK key.
-- Add compatibility columns before policies/functions reference them.
alter table public.culture_guide_translations
  add column if not exists guide_item_id uuid;

-- Some remote deployments use locale while older seed data uses language_code.
alter table public.culture_guide_translations
  add column if not exists locale text;

alter table public.culture_guide_translations
  add column if not exists language_code text;

-- Existing deployments may have a reduced translation schema; add phrase fields used by the guide RPC.
alter table public.culture_guide_translations
  add column if not exists phrase_local text,
  add column if not exists phrase_pronunciation text,
  add column if not exists phrase_translation text,
  add column if not exists title text,
  add column if not exists body text not null default '';

-- Backfill guide_item_id when an older schema used item_id instead.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'culture_guide_translations'
      and column_name = 'item_id'
  ) then
    update public.culture_guide_translations tr
    set guide_item_id = tr.item_id
    where tr.guide_item_id is null;
  end if;
end $$;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'culture_guide_translations'
      and column_name = 'language_code'
  ) then
    update public.culture_guide_translations
    set locale = coalesce(locale, language_code),
        language_code = coalesce(language_code, locale)
    where locale is null or language_code is null;
  end if;
end $$;

alter table public.culture_guide_items enable row level security;
alter table public.culture_guide_translations enable row level security;

drop policy if exists "public read published culture guide items"
on public.culture_guide_items;

create policy "public read published culture guide items"
on public.culture_guide_items
for select
to anon, authenticated
using (is_published = true);

drop policy if exists "public read culture guide translations"
on public.culture_guide_translations;

create policy "public read culture guide translations"
on public.culture_guide_translations
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.culture_guide_items item
    where item.id = guide_item_id
      and item.is_published = true
  )
);

drop function if exists public.get_culture_guide(text, text, text);

create function public.get_culture_guide(
  p_country_code text,
  p_city_name text,
  p_locale text default 'en'
)
returns table (
  id uuid,
  tip_type text,
  title text,
  body text,
  priority integer,
  phrase_local text,
  phrase_pronunciation text,
  phrase_translation text
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    item.id,
    item.tip_type,
    coalesce(tr.title, en.title, '') as title,
    coalesce(tr.body, en.body, '') as body,
    item.priority,
    coalesce(tr.phrase_local, en.phrase_local) as phrase_local,
    coalesce(tr.phrase_pronunciation, en.phrase_pronunciation) as phrase_pronunciation,
    coalesce(tr.phrase_translation, en.phrase_translation) as phrase_translation
  from public.culture_guide_items item
  join public.countries country on country.id = item.country_id
  left join public.cities city on city.id = item.city_id
  left join public.city_translations city_tr
    on city_tr.city_id = city.id
   and city_tr.locale = p_locale
  left join public.city_translations city_en
    on city_en.city_id = city.id
   and city_en.locale = 'en'
  left join public.culture_guide_translations tr
    on tr.guide_item_id = item.id
   and tr.locale = p_locale
  left join public.culture_guide_translations en
    on en.guide_item_id = item.id
   and en.locale = 'en'
  where upper(country.code) = upper(p_country_code)
    and item.is_published = true
    and (
      item.city_id is null
      or lower(coalesce(city_tr.display_name, city_en.display_name, city.default_name)) =
         lower(p_city_name)
    )
  order by item.priority desc, item.created_at asc;
$$;

grant execute on function public.get_culture_guide(text, text, text)
to anon, authenticated;

-- Admin/service-role writes are intentionally not exposed through public RLS.
-- Seed culture data can be managed from Supabase SQL editor/admin tooling later.
