create table if not exists public.food_details (
  content_id uuid primary key references public.contents(id) on delete cascade,
  currency_code text,
  typical_price_min numeric(12,2),
  typical_price_max numeric(12,2),
  spicy_level integer check (spicy_level between 0 and 5),
  vegetarian boolean,
  vegan boolean,
  halal boolean,
  contains_pork boolean,
  contains_alcohol boolean,
  gluten_free boolean,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.food_detail_translations (
  content_id uuid not null references public.food_details(content_id) on delete cascade,
  locale text not null,
  ingredients text[] not null default '{}'::text[],
  allergens text[] not null default '{}'::text[],
  portion_info text,
  how_locals_eat text,
  when_locals_eat text,
  before_you_order text,
  primary key (content_id, locale)
);

-- Compatibility for the pre-existing remote food_detail_translations schema.
alter table public.food_detail_translations
  add column if not exists ingredients text[] not null default '{}'::text[],
  add column if not exists allergens text[] not null default '{}'::text[],
  add column if not exists portion_info text,
  add column if not exists how_locals_eat text,
  add column if not exists when_locals_eat text,
  add column if not exists before_you_order text;

alter table public.food_details enable row level security;
alter table public.food_detail_translations enable row level security;

drop policy if exists "public read food details" on public.food_details;
create policy "public read food details"
on public.food_details for select
to anon, authenticated
using (
  exists (
    select 1
    from public.contents c
    where c.id = content_id
      and c.status = 'published'
  )
);

drop policy if exists "public read food detail translations" on public.food_detail_translations;
create policy "public read food detail translations"
on public.food_detail_translations for select
to anon, authenticated
using (
  exists (
    select 1
    from public.contents c
    where c.id = content_id
      and c.status = 'published'
  )
);

drop function if exists public.get_food_details(uuid[], text);

create function public.get_food_details(
  p_content_ids uuid[],
  p_locale text default 'en'
)
returns table (
  content_id uuid,
  currency_code text,
  typical_price_min numeric,
  typical_price_max numeric,
  spicy_level integer,
  vegetarian boolean,
  vegan boolean,
  halal boolean,
  contains_pork boolean,
  contains_alcohol boolean,
  gluten_free boolean,
  ingredients text[],
  allergens text[],
  portion_info text,
  how_locals_eat text,
  when_locals_eat text,
  before_you_order text
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    fd.content_id,
    fd.currency_code,
    fd.typical_price_min,
    fd.typical_price_max,
    fd.spicy_level,
    fd.vegetarian,
    fd.vegan,
    fd.halal,
    fd.contains_pork,
    fd.contains_alcohol,
    fd.gluten_free,
    coalesce(tr.ingredients, en.ingredients, '{}'::text[]) as ingredients,
    coalesce(tr.allergens, en.allergens, '{}'::text[]) as allergens,
    coalesce(tr.portion_info, en.portion_info) as portion_info,
    coalesce(tr.how_locals_eat, en.how_locals_eat) as how_locals_eat,
    coalesce(tr.when_locals_eat, en.when_locals_eat) as when_locals_eat,
    coalesce(tr.before_you_order, en.before_you_order) as before_you_order
  from public.food_details fd
  join public.contents c on c.id = fd.content_id
  left join public.food_detail_translations tr
    on tr.content_id = fd.content_id
   and tr.locale = p_locale
  left join public.food_detail_translations en
    on en.content_id = fd.content_id
   and en.locale = 'en'
  where fd.content_id = any(p_content_ids)
    and c.status = 'published';
$$;

grant execute on function public.get_food_details(uuid[], text)
to anon, authenticated;

-- Optional starter data for the Phase 2 demo IDs.
insert into public.food_details (
  content_id,
  currency_code,
  typical_price_min,
  typical_price_max,
  spicy_level,
  vegetarian,
  vegan,
  halal,
  contains_pork,
  contains_alcohol,
  gluten_free
)
select
  id,
  case
    when id in (
      '30000000-0000-0000-0000-000000000002'::uuid,
      '30000000-0000-0000-0000-000000000003'::uuid
    ) then 'TRY'
    when id = '30000000-0000-0000-0000-000000000005'::uuid then 'JPY'
  end,
  case
    when id = '30000000-0000-0000-0000-000000000002'::uuid then 15
    when id = '30000000-0000-0000-0000-000000000003'::uuid then 120
    when id = '30000000-0000-0000-0000-000000000005'::uuid then 900
  end,
  case
    when id = '30000000-0000-0000-0000-000000000002'::uuid then 40
    when id = '30000000-0000-0000-0000-000000000003'::uuid then 280
    when id = '30000000-0000-0000-0000-000000000005'::uuid then 1500
  end,
  case
    when id = '30000000-0000-0000-0000-000000000005'::uuid then 2
    else 0
  end,
  case
    when id = '30000000-0000-0000-0000-000000000005'::uuid then false
    else true
  end,
  case
    when id = '30000000-0000-0000-0000-000000000002'::uuid then true
    else false
  end,
  case
    when id = '30000000-0000-0000-0000-000000000005'::uuid then false
    else true
  end,
  case
    when id = '30000000-0000-0000-0000-000000000005'::uuid then true
    else false
  end,
  false,
  false
from public.contents
where id in (
  '30000000-0000-0000-0000-000000000002'::uuid,
  '30000000-0000-0000-0000-000000000003'::uuid,
  '30000000-0000-0000-0000-000000000005'::uuid
)
on conflict (content_id) do update set
  currency_code = excluded.currency_code,
  typical_price_min = excluded.typical_price_min,
  typical_price_max = excluded.typical_price_max,
  spicy_level = excluded.spicy_level,
  vegetarian = excluded.vegetarian,
  vegan = excluded.vegan,
  halal = excluded.halal,
  contains_pork = excluded.contains_pork,
  contains_alcohol = excluded.contains_alcohol,
  gluten_free = excluded.gluten_free,
  updated_at = now();

insert into public.food_detail_translations (
  content_id,
  locale,
  ingredients,
  allergens,
  portion_info,
  how_locals_eat,
  when_locals_eat,
  before_you_order
)
select
  id,
  'en',
  case
    when id = '30000000-0000-0000-0000-000000000002'::uuid
      then array['sesame','flour','yeast']
    when id = '30000000-0000-0000-0000-000000000003'::uuid
      then array['phyllo','pistachio','butter','syrup']
    else array['noodles','broth','toppings']
  end,
  case
    when id = '30000000-0000-0000-0000-000000000002'::uuid
      then array['gluten','sesame']
    when id = '30000000-0000-0000-0000-000000000003'::uuid
      then array['gluten','nuts','milk']
    else array['gluten','soy']
  end,
  case
    when id = '30000000-0000-0000-0000-000000000002'::uuid
      then 'Usually eaten as a light snack.'
    when id = '30000000-0000-0000-0000-000000000003'::uuid
      then 'One or two pieces can be very filling.'
    else 'Normally served as a complete single-bowl meal.'
  end,
  case
    when id = '30000000-0000-0000-0000-000000000002'::uuid
      then 'Often eaten fresh with tea while walking or at breakfast.'
    when id = '30000000-0000-0000-0000-000000000003'::uuid
      then 'Usually served in small portions with tea or coffee.'
    else 'Slurping noodles is normal and helps cool them.'
  end,
  case
    when id = '30000000-0000-0000-0000-000000000002'::uuid
      then 'Breakfast or anytime during the day.'
    when id = '30000000-0000-0000-0000-000000000003'::uuid
      then 'Dessert or an afternoon treat.'
    else 'Lunch, dinner, or late night.'
  end,
  case
    when id = '30000000-0000-0000-0000-000000000002'::uuid
      then 'Ask for a fresh, warm simit if possible.'
    when id = '30000000-0000-0000-0000-000000000003'::uuid
      then 'Pistachio and walnut versions are both common.'
    else 'Broth styles vary widely; check whether pork is used.'
  end
from public.contents
where id in (
  '30000000-0000-0000-0000-000000000002'::uuid,
  '30000000-0000-0000-0000-000000000003'::uuid,
  '30000000-0000-0000-0000-000000000005'::uuid
)
on conflict (content_id, locale) do nothing;
