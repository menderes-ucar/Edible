-- Edible: registration profile details.
-- Email/password remain in Supabase Auth and are never exposed by public profile RPCs.

create or replace function public.get_public_profile_details(p_user_id uuid)
returns table (
  user_id uuid,
  display_name text,
  first_name text,
  last_name text,
  age integer,
  hometown text,
  gender text,
  avatar_url text
)
language sql
security definer
set search_path = public, auth
stable
as $$
  select
    u.id,
    coalesce(u.raw_user_meta_data ->> 'display_name', '')::text,
    nullif(trim(u.raw_user_meta_data ->> 'first_name'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'last_name'), ''),
    case
      when (u.raw_user_meta_data ->> 'age') ~ '^[0-9]+$'
        then (u.raw_user_meta_data ->> 'age')::integer
      else null
    end,
    nullif(trim(u.raw_user_meta_data ->> 'hometown'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'gender'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'avatar_url'), '')
  from auth.users u
  where u.id = p_user_id;
$$;

grant execute on function public.get_public_profile_details(uuid) to anon, authenticated;
