-- Community sharing: posts, up to 5 compressed photos, reactions and public travel profile.
create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  caption text not null default '' check (char_length(caption) <= 2000),
  latitude double precision,
  longitude double precision,
  location_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.community_post_images (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique(post_id, storage_path)
);

create table if not exists public.community_post_reactions (
  post_id uuid not null references public.community_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction text not null check (reaction in ('like','dislike')),
  created_at timestamptz not null default now(),
  primary key(post_id,user_id)
);

create index if not exists community_posts_created_idx
  on public.community_posts(created_at desc);
create index if not exists community_posts_user_idx
  on public.community_posts(user_id);
create index if not exists community_post_images_post_idx
  on public.community_post_images(post_id,sort_order);
create index if not exists community_reactions_post_idx
  on public.community_post_reactions(post_id);

alter table public.community_posts enable row level security;
alter table public.community_post_images enable row level security;
alter table public.community_post_reactions enable row level security;

drop policy if exists "public read community posts" on public.community_posts;
create policy "public read community posts"
on public.community_posts for select
to anon, authenticated using (true);

drop policy if exists "users create own community posts" on public.community_posts;
create policy "users create own community posts"
on public.community_posts for insert
to authenticated with check (auth.uid() = user_id);

drop policy if exists "users delete own community posts" on public.community_posts;
create policy "users delete own community posts"
on public.community_posts for delete
to authenticated using (auth.uid() = user_id);

drop policy if exists "public read community post images" on public.community_post_images;
create policy "public read community post images"
on public.community_post_images for select
to anon, authenticated using (true);

drop policy if exists "users add own community post images" on public.community_post_images;
create policy "users add own community post images"
on public.community_post_images for insert
to authenticated
with check (
  exists (
    select 1 from public.community_posts p
    where p.id = post_id and p.user_id = auth.uid()
  )
);

drop policy if exists "users delete own community post images" on public.community_post_images;
create policy "users delete own community post images"
on public.community_post_images for delete
to authenticated
using (
  exists (
    select 1 from public.community_posts p
    where p.id = post_id and p.user_id = auth.uid()
  )
);

drop policy if exists "public read community reactions" on public.community_post_reactions;
create policy "public read community reactions"
on public.community_post_reactions for select
to anon, authenticated using (true);

drop policy if exists "users add own community reactions" on public.community_post_reactions;
create policy "users add own community reactions"
on public.community_post_reactions for insert
to authenticated with check (auth.uid() = user_id);

drop policy if exists "users update own community reactions" on public.community_post_reactions;
create policy "users update own community reactions"
on public.community_post_reactions for update
to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "users delete own community reactions" on public.community_post_reactions;
create policy "users delete own community reactions"
on public.community_post_reactions for delete
to authenticated using (auth.uid() = user_id);

insert into storage.buckets(id,name,public)
values ('edible-community','edible-community',true)
on conflict(id) do update set public=excluded.public;

drop policy if exists "public read community media" on storage.objects;
create policy "public read community media"
on storage.objects for select
to anon, authenticated
using (bucket_id='edible-community');

drop policy if exists "users upload own community media" on storage.objects;
create policy "users upload own community media"
on storage.objects for insert
to authenticated
with check (
  bucket_id='edible-community'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users delete own community media" on storage.objects;
create policy "users delete own community media"
on storage.objects for delete
to authenticated
using (
  bucket_id='edible-community'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create or replace function public.get_community_feed(
  p_limit integer default 30,
  p_offset integer default 0
)
returns table (
  id uuid,
  user_id uuid,
  display_name text,
  avatar_url text,
  caption text,
  latitude double precision,
  longitude double precision,
  location_name text,
  created_at timestamptz,
  image_urls text[],
  like_count bigint,
  dislike_count bigint
)
language sql
stable
security invoker
set search_path=public
as $$
  select
    p.id,
    p.user_id,
    coalesce(pr.display_name,'') as display_name,
    pr.avatar_url,
    p.caption,
    p.latitude,
    p.longitude,
    p.location_name,
    p.created_at,
    coalesce(
      array_agg(
        'https://lylliolgjxmbpawkriww.supabase.co/storage/v1/object/public/edible-community/' || i.storage_path
        order by i.sort_order
      ) filter (where i.id is not null),
      '{}'::text[]
    ) as image_urls,
    count(distinct r.user_id) filter (where r.reaction='like') as like_count,
    count(distinct r.user_id) filter (where r.reaction='dislike') as dislike_count
  from public.community_posts p
  left join public.profiles pr on pr.id=p.user_id
  left join public.community_post_images i on i.post_id=p.id
  left join public.community_post_reactions r on r.post_id=p.id
  group by p.id,pr.display_name,pr.avatar_url
  order by p.created_at desc
  limit greatest(1,least(coalesce(p_limit,30),100))
  offset greatest(coalesce(p_offset,0),0);
$$;

grant execute on function public.get_community_feed(integer,integer) to anon,authenticated;

create or replace function public.get_public_profile(p_user_id uuid)
returns table (
  id uuid,
  display_name text,
  avatar_url text,
  created_at timestamptz,
  visit_count bigint
)
language sql
stable
security definer
set search_path=public
as $$
  select p.id,p.display_name,p.avatar_url,p.created_at,
    (select count(*) from public.travel_visits tv where tv.user_id=p.id) as visit_count
  from public.profiles p
  where p.id=p_user_id;
$$;

create or replace function public.get_public_profile_visits(p_user_id uuid)
returns table (
  country_code text,
  city_name text,
  visit_day date,
  detection_count integer
)
language sql
stable
security definer
set search_path=public
as $$
  select country_code,city_name,visit_day,detection_count
  from public.travel_visits
  where user_id=p_user_id
  order by visit_day desc
  limit 100;
$$;

grant execute on function public.get_public_profile(uuid) to anon,authenticated;
grant execute on function public.get_public_profile_visits(uuid) to anon,authenticated;
