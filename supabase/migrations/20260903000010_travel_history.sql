create table if not exists public.travel_visits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  country_code text not null,
  country_name text not null,
  city_name text not null,
  visit_day date not null default current_date,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  detection_count integer not null default 1
    check (detection_count >= 1),
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  unique(user_id, country_code, city_name, visit_day)
);

create index if not exists travel_visits_user_day_idx
on public.travel_visits(user_id, visit_day desc);

alter table public.travel_visits enable row level security;

drop policy if exists "users read own travel visits"
on public.travel_visits;

create policy "users read own travel visits"
on public.travel_visits
for select
to authenticated
using (auth.uid() = user_id);

-- Direct client INSERT/UPDATE/DELETE is intentionally not granted.
-- Writes go through record_travel_visit(), which always uses auth.uid().

drop function if exists public.record_travel_visit(
  text,
  text,
  text,
  double precision,
  double precision
);

create function public.record_travel_visit(
  p_country_code text,
  p_country_name text,
  p_city_name text,
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  insert into public.travel_visits (
    user_id,
    country_code,
    country_name,
    city_name,
    visit_day,
    first_seen_at,
    last_seen_at,
    detection_count,
    latitude,
    longitude
  )
  values (
    v_user_id,
    upper(trim(p_country_code)),
    trim(p_country_name),
    trim(p_city_name),
    current_date,
    now(),
    now(),
    1,
    p_latitude,
    p_longitude
  )
  on conflict (user_id, country_code, city_name, visit_day)
  do update set
    country_name = excluded.country_name,
    last_seen_at = now(),
    detection_count = public.travel_visits.detection_count + 1,
    latitude = excluded.latitude,
    longitude = excluded.longitude;
end;
$$;

revoke all on function public.record_travel_visit(
  text,
  text,
  text,
  double precision,
  double precision
) from public;

grant execute on function public.record_travel_visit(
  text,
  text,
  text,
  double precision,
  double precision
) to authenticated;
