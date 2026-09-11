create table if not exists public.content_images (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.contents(id) on delete cascade,
  storage_path text not null,
  alt_text text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (content_id, storage_path)
);

create index if not exists idx_content_images_content_sort
on public.content_images(content_id, sort_order);

alter table public.content_images enable row level security;

drop policy if exists "public read content images" on public.content_images;
create policy "public read content images"
on public.content_images for select
to anon, authenticated
using (
  exists (
    select 1
    from public.contents c
    where c.id = content_id
      and c.status = 'published'
  )
);

insert into storage.buckets (id, name, public)
values (
  'edible-content-images',
  'edible-content-images',
  true
)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "public read edible content storage" on storage.objects;
create policy "public read edible content storage"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'edible-content-images');

drop function if exists public.get_explore_contents(text);

create function public.get_explore_contents(
  p_locale text default 'en'
)
returns table (
  id uuid,
  country_code text,
  country_name text,
  city_name text,
  category text,
  title text,
  short_description text,
  description text,
  latitude double precision,
  longitude double precision,
  cover_image_url text,
  is_featured boolean,
  tags text[],
  metadata jsonb,
  image_paths text[]
)
language sql
stable
security invoker
set search_path = public
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
    c.latitude,
    c.longitude,
    c.cover_image_url,
    c.is_featured,
    coalesce(tr.tags, en.tags, '{}'::text[]) as tags,
    c.metadata,
    coalesce(
      (
        select array_agg(img.storage_path order by img.sort_order, img.created_at)
        from public.content_images img
        where img.content_id = c.id
      ),
      '{}'::text[]
    ) as image_paths
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
    on tr.content_id = c.id and tr.locale = p_locale
  left join public.content_translations en
    on en.content_id = c.id and en.locale = 'en'
  where c.status = 'published'
  order by c.is_featured desc, co.default_name, ci.default_name;
$$;

grant execute on function public.get_explore_contents(text)
to anon, authenticated;
