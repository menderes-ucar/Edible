-- Edible: community feed must be able to read public profile identity.
-- The feed only exposes display_name/avatar_url; it does not expose private data.
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
set search_path = public
as $$
  select
    p.id,
    p.user_id,
    coalesce(
      nullif(trim(pr.display_name), ''),
      nullif(trim(concat_ws(
        ' ',
        nullif(trim(u.raw_user_meta_data ->> 'first_name'), ''),
        nullif(trim(u.raw_user_meta_data ->> 'last_name'), '')
      )), ''),
      nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''),
      'Edible kullanıcısı'
    ) as display_name,
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
    count(distinct r.user_id) filter (where r.reaction = 'like') as like_count,
    count(distinct r.user_id) filter (where r.reaction = 'dislike') as dislike_count
  from public.community_posts p
  left join public.profiles pr on pr.id = p.user_id
  left join auth.users u on u.id = p.user_id
  left join public.community_post_images i on i.post_id = p.id
  left join public.community_post_reactions r on r.post_id = p.id
  group by p.id, pr.display_name, pr.avatar_url, u.raw_user_meta_data
  order by p.created_at desc
  limit greatest(1, least(coalesce(p_limit, 30), 100))
  offset greatest(coalesce(p_offset, 0), 0);
$$;

grant execute on function public.get_community_feed(integer, integer) to anon, authenticated;
