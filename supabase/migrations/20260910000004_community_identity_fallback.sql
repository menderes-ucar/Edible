-- Edible: make community author identity resilient for existing accounts.
-- The feed is SECURITY DEFINER, so it can safely read auth.users metadata as a
-- fallback when a legacy profile row has no display_name.

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
security definer
set search_path=public
as $$
  select
    p.id,
    p.user_id,
    coalesce(
      nullif(trim(pr.display_name), ''),
      nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''),
      nullif(trim(concat_ws(
        ' ',
        nullif(trim(u.raw_user_meta_data ->> 'first_name'), ''),
        nullif(trim(u.raw_user_meta_data ->> 'last_name'), '')
      )), ''),
      'Edible kullanıcısı'
    ) as display_name,
    coalesce(
      nullif(trim(pr.avatar_url), ''),
      nullif(trim(u.raw_user_meta_data ->> 'avatar_url'), '')
    ) as avatar_url,
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
  left join auth.users u on u.id=p.user_id
  left join public.community_post_images i on i.post_id=p.id
  left join public.community_post_reactions r on r.post_id=p.id
  group by p.id, pr.display_name, pr.avatar_url, u.raw_user_meta_data
  order by p.created_at desc
  limit greatest(1,least(coalesce(p_limit,30),100))
  offset greatest(coalesce(p_offset,0),0);
$$;

grant execute on function public.get_community_feed(integer,integer) to anon,authenticated;

-- Backfill legacy blank profile names as well, so other public-profile surfaces
-- also stop falling back to the generic account label.
update public.profiles p
set display_name = coalesce(
  nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''),
  nullif(trim(concat_ws(
    ' ',
    nullif(trim(u.raw_user_meta_data ->> 'first_name'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'last_name'), '')
  )), ''),
  p.display_name
),
updated_at = now()
from auth.users u
where u.id = p.id
  and coalesce(trim(p.display_name), '') = '';
