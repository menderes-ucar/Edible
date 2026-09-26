-- Edible security hardening: private profile data, travel history RPCs,
-- image resolver abuse protection, and message notification idempotency.

-- ---------------------------------------------------------------------------
-- 1) Public profile details: only the owner may receive private registration
-- fields. Other authenticated users receive only genuinely public identity.
-- Anonymous callers cannot invoke this RPC.
-- ---------------------------------------------------------------------------
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
    case when auth.uid() = u.id then nullif(trim(u.raw_user_meta_data ->> 'first_name'), '') else null end,
    case when auth.uid() = u.id then nullif(trim(u.raw_user_meta_data ->> 'last_name'), '') else null end,
    case
      when auth.uid() = u.id
       and (u.raw_user_meta_data ->> 'age') ~ '^[0-9]+$'
        then (u.raw_user_meta_data ->> 'age')::integer
      else null
    end,
    case when auth.uid() = u.id then nullif(trim(u.raw_user_meta_data ->> 'hometown'), '') else null end,
    case when auth.uid() = u.id then nullif(trim(u.raw_user_meta_data ->> 'gender'), '') else null end,
    nullif(trim(u.raw_user_meta_data ->> 'avatar_url'), '')
  from auth.users u
  where u.id = p_user_id
    and auth.uid() is not null;
$$;

revoke all on function public.get_public_profile_details(uuid) from public, anon;
grant execute on function public.get_public_profile_details(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 2) Travel history is private. The RPC may only return the caller's own
-- history. This prevents SECURITY DEFINER from bypassing travel_visits RLS.
-- ---------------------------------------------------------------------------
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
set search_path = public
as $$
  select tv.country_code, tv.city_name, tv.visit_day, tv.detection_count
  from public.travel_visits tv
  where tv.user_id = p_user_id
    and auth.uid() = p_user_id
  order by tv.visit_day desc
  limit 100;
$$;

revoke all on function public.get_public_profile_visits(uuid) from public, anon;
grant execute on function public.get_public_profile_visits(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3) Image resolver rate limiting. A server-side counter is used so limits do
-- not disappear when an Edge Function instance is replaced.
-- ---------------------------------------------------------------------------
create table if not exists public.image_resolution_rate_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  window_start timestamptz not null,
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, window_start)
);

revoke all on table public.image_resolution_rate_limits from public, anon, authenticated;

create or replace function public.consume_image_resolution_rate_limit(
  p_user_id uuid,
  p_limit integer default 30
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_window timestamptz := date_trunc('hour', now());
  v_count integer;
begin
  if p_user_id is null or p_limit < 1 then
    return false;
  end if;

  insert into public.image_resolution_rate_limits(user_id, window_start, request_count, updated_at)
  values (p_user_id, v_window, 1, now())
  on conflict (user_id, window_start)
  do update set
    request_count = public.image_resolution_rate_limits.request_count + 1,
    updated_at = now()
  returning request_count into v_count;

  return v_count <= p_limit;
end;
$$;

revoke all on function public.consume_image_resolution_rate_limit(uuid, integer) from public, anon, authenticated;

-- Keep only recent counters. The Edge Function calls this cleanup opportunistically.
create index if not exists image_resolution_rate_limits_window_idx
  on public.image_resolution_rate_limits(window_start);

-- ---------------------------------------------------------------------------
-- 4) Message push idempotency. One message can create one notification
-- delivery record per recipient. Retries are allowed only after a stale
-- in-progress attempt.
-- ---------------------------------------------------------------------------
create table if not exists public.message_push_deliveries (
  message_id uuid not null references public.direct_messages(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'processing'
    check (status in ('processing', 'sent')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (message_id, recipient_id)
);

revoke all on table public.message_push_deliveries from public, anon, authenticated;

create index if not exists message_push_deliveries_updated_idx
  on public.message_push_deliveries(updated_at);

create or replace function public.claim_message_push_delivery(
  p_message_id uuid,
  p_recipient_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_claimed integer;
begin
  insert into public.message_push_deliveries(message_id, recipient_id, status, updated_at)
  values (p_message_id, p_recipient_id, 'processing', now())
  on conflict (message_id, recipient_id)
  do update set
    status = 'processing',
    updated_at = now()
  where public.message_push_deliveries.status <> 'sent'
    and public.message_push_deliveries.updated_at < now() - interval '5 minutes'
  returning 1 into v_claimed;

  return coalesce(v_claimed, 0) = 1;
end;
$$;

revoke all on function public.claim_message_push_delivery(uuid, uuid) from public, anon, authenticated;

grant execute on function public.consume_image_resolution_rate_limit(uuid, integer) to service_role;
grant execute on function public.claim_message_push_delivery(uuid, uuid) to service_role;
