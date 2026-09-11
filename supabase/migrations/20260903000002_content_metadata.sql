alter table public.contents
add column if not exists metadata jsonb not null default '{}'::jsonb;

create index if not exists idx_contents_metadata_gin
on public.contents using gin (metadata);

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
  metadata jsonb
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
    c.metadata
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

update public.contents
set
  cover_image_url = case id
    when '30000000-0000-0000-0000-000000000001'::uuid then
      'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80'
    when '30000000-0000-0000-0000-000000000003'::uuid then
      'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80'
    when '30000000-0000-0000-0000-000000000004'::uuid then
      'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80'
    when '30000000-0000-0000-0000-000000000005'::uuid then
      'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80'
    when '30000000-0000-0000-0000-000000000006'::uuid then
      'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?auto=format&fit=crop&w=1200&q=80'
    else cover_image_url
  end,
  metadata = case id
    when '30000000-0000-0000-0000-000000000001'::uuid then
      '{"best_time":"Early morning","local_tip":"Explore the historic district on foot.","opening_info":"Open public area","estimated_visit_minutes":120}'::jsonb
    when '30000000-0000-0000-0000-000000000002'::uuid then
      '{"price_level":1,"vegetarian":true,"vegan":true,"halal":true,"best_time":"Breakfast or snack","local_tip":"Try it with Turkish tea."}'::jsonb
    when '30000000-0000-0000-0000-000000000003'::uuid then
      '{"best_time":"Early morning","estimated_visit_minutes":90,"etiquette":"Keep a respectful tone around worship areas."}'::jsonb
    when '30000000-0000-0000-0000-000000000004'::uuid then
      '{"price_level":2,"spicy_level":1,"local_tip":"Small ramen shops with ticket machines are common."}'::jsonb
    when '30000000-0000-0000-0000-000000000005'::uuid then
      '{"best_time":"Morning","estimated_visit_minutes":120,"local_tip":"Booking ahead is useful during busy periods."}'::jsonb
    when '30000000-0000-0000-0000-000000000006'::uuid then
      '{"price_level":1,"etiquette":"Standing at the bar may be priced differently from table service."}'::jsonb
    else metadata
  end
where id in (
  '30000000-0000-0000-0000-000000000001'::uuid,
  '30000000-0000-0000-0000-000000000002'::uuid,
  '30000000-0000-0000-0000-000000000003'::uuid,
  '30000000-0000-0000-0000-000000000004'::uuid,
  '30000000-0000-0000-0000-000000000005'::uuid,
  '30000000-0000-0000-0000-000000000006'::uuid
);
