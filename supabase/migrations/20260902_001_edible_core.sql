create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  preferred_language text not null default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.countries (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (char_length(code) = 2),
  default_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.country_translations (
  country_id uuid not null references public.countries(id) on delete cascade,
  locale text not null,
  display_name text not null,
  primary key (country_id, locale)
);

create table if not exists public.cities (
  id uuid primary key default gen_random_uuid(),
  country_id uuid not null references public.countries(id) on delete cascade,
  default_name text not null,
  latitude double precision not null,
  longitude double precision not null,
  created_at timestamptz not null default now()
);

create table if not exists public.city_translations (
  city_id uuid not null references public.cities(id) on delete cascade,
  locale text not null,
  display_name text not null,
  primary key (city_id, locale)
);

create table if not exists public.categories (
  id text primary key,
  sort_order integer not null default 0
);

create table if not exists public.contents (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references public.cities(id) on delete cascade,
  category_id text not null references public.categories(id),
  latitude double precision not null,
  longitude double precision not null,
  cover_image_url text,
  is_featured boolean not null default false,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.content_translations (
  content_id uuid not null references public.contents(id) on delete cascade,
  language_code text not null,
  title text not null,
  short_description text not null default '',
  description text not null default '',
  tags text[] not null default '{}',
  primary key (content_id, language_code)
);

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  content_id uuid not null references public.contents(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, content_id)
);

alter table public.contents add column if not exists status text;
update public.contents set status = 'draft' where status is null;
alter table public.contents alter column status set default 'draft';
alter table public.contents alter column status set not null;
alter table public.contents drop constraint if exists contents_status_check;
alter table public.contents add constraint contents_status_check check (status in ('draft', 'published', 'archived'));

alter table public.content_translations add column if not exists tags text[];
update public.content_translations set tags = '{}'::text[] where tags is null;
alter table public.content_translations alter column tags set default '{}';
alter table public.content_translations alter column tags set not null;

-- The existing production schema may use locale instead of language_code.
-- Keep the legacy-compatible language_code column because the later seed
-- migrations use it and because this function is keyed by language_code.
alter table public.content_translations
  add column if not exists language_code text;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'content_translations'
      and column_name = 'locale'
  ) then
    execute $q$update public.content_translations
      set language_code = locale
      where language_code is null$q$;
  end if;

  execute $q$update public.content_translations
    set language_code = 'en'
    where language_code is null$q$;
end $$;

alter table public.content_translations
  alter column language_code set default 'en';
alter table public.content_translations
  alter column language_code set not null;

create unique index if not exists uq_content_translations_content_language
  on public.content_translations(content_id, language_code);

create index if not exists idx_cities_country_id
  on public.cities(country_id);

create index if not exists idx_contents_city_id
  on public.contents(city_id);

create index if not exists idx_contents_category_status
  on public.contents(category_id, status);

create index if not exists idx_favorites_user_id
  on public.favorites(user_id);

alter table public.profiles enable row level security;
alter table public.countries enable row level security;
alter table public.country_translations enable row level security;
alter table public.cities enable row level security;
alter table public.city_translations enable row level security;
alter table public.categories enable row level security;
alter table public.contents enable row level security;
alter table public.content_translations enable row level security;
alter table public.favorites enable row level security;

drop policy if exists "public read countries" on public.countries;
create policy "public read countries"
on public.countries for select
to anon, authenticated
using (true);

drop policy if exists "public read country translations" on public.country_translations;
create policy "public read country translations"
on public.country_translations for select
to anon, authenticated
using (true);

drop policy if exists "public read cities" on public.cities;
create policy "public read cities"
on public.cities for select
to anon, authenticated
using (true);

drop policy if exists "public read city translations" on public.city_translations;
create policy "public read city translations"
on public.city_translations for select
to anon, authenticated
using (true);

drop policy if exists "public read categories" on public.categories;
create policy "public read categories"
on public.categories for select
to anon, authenticated
using (true);

drop policy if exists "public read published contents" on public.contents;
create policy "public read published contents"
on public.contents for select
to anon, authenticated
using (status = 'published');

drop policy if exists "public read content translations" on public.content_translations;
create policy "public read content translations"
on public.content_translations for select
to anon, authenticated
using (
  exists (
    select 1
    from public.contents c
    where c.id = content_id
      and c.status = 'published'
  )
);

drop policy if exists "users read own profile" on public.profiles;
create policy "users read own profile"
on public.profiles for select
to authenticated
using (auth.uid() = id);

drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "users read own favorites" on public.favorites;
create policy "users read own favorites"
on public.favorites for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "users add own favorites" on public.favorites;
create policy "users add own favorites"
on public.favorites for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "users delete own favorites" on public.favorites;
create policy "users delete own favorites"
on public.favorites for delete
to authenticated
using (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

drop function if exists public.get_explore_contents(text);

create function public.get_explore_contents(
  p_locale text default 'en'
)
returns table (
  id uuid, country_code text, country_name text, city_name text, category text,
  title text, short_description text, description text, latitude double precision,
  longitude double precision, cover_image_url text, is_featured boolean, tags text[]
)
language sql stable security invoker set search_path = public
as $$
  select
    c.id,
    co.code as country_code,
    coalesce(ct.display_name, cet.display_name, co.default_name) as country_name,
    coalesce(cit.display_name, ciet.display_name, ci.default_name) as city_name,
    coalesce(cat.slug, cat.key, '') as category,
    coalesce(tr.title, en.title, '') as title,
    coalesce(tr.short_description, en.short_description, '') as short_description,
    coalesce(tr.description, en.description, '') as description,
    c.latitude, c.longitude, c.cover_image_url, c.is_featured,
    coalesce(tr.tags, en.tags, '{}'::text[]) as tags
  from public.contents c
  join public.cities ci on ci.id = c.city_id
  join public.countries co on co.id = ci.country_id
  left join public.categories cat on cat.id = c.category_id
  left join public.country_translations ct
    on ct.country_id = co.id and ct.locale = p_locale
  left join public.country_translations cet
    on cet.country_id = co.id and cet.locale = 'en'
  left join public.city_translations cit
    on cit.city_id = ci.id and cit.locale = p_locale
  left join public.city_translations ciet
    on ciet.city_id = ci.id and ciet.locale = 'en'
  left join public.content_translations tr
    on tr.content_id = c.id and tr.language_code = p_locale
  left join public.content_translations en
    on en.content_id = c.id and en.language_code = 'en'
  where c.status = 'published'
  order by c.is_featured desc, co.default_name, ci.default_name;
$$;

grant execute on function public.get_explore_contents(text)
to anon, authenticated;

alter table public.categories add column if not exists sort_order integer not null default 0;
alter table public.categories add column if not exists slug text;

-- The live database uses UUID category ids. Keep human-readable slugs separately.
-- The live database already has category rows keyed by the unique `key` column.
-- Reuse those rows instead of inserting duplicate keys or assuming their UUIDs.
insert into public.categories (key, slug, sort_order) values
  ('place', 'place', 10),
  ('food', 'food', 20),
  ('snack', 'snack', 30),
  ('culture', 'culture', 40),
  ('fruit', 'fruit', 50),
  ('drink', 'drink', 60)
on conflict (key) do update
set slug = excluded.slug, sort_order = excluded.sort_order;
