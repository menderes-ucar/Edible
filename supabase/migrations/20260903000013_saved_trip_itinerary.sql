create table if not exists public.saved_trip_itinerary_stops (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.saved_trips(id)
    on delete cascade,
  content_id uuid not null references public.contents(id)
    on delete cascade,

  day_index integer not null
    check (day_index >= 0 and day_index <= 29),

  start_minute integer not null
    check (start_minute >= 0 and start_minute < 1440),

  sort_order integer not null default 0
    check (sort_order >= 0),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique(trip_id, content_id)
);

create index if not exists saved_trip_itinerary_trip_day_idx
on public.saved_trip_itinerary_stops(
  trip_id,
  day_index,
  start_minute,
  sort_order
);

alter table public.saved_trip_itinerary_stops enable row level security;

drop policy if exists "users read own saved trip itinerary"
on public.saved_trip_itinerary_stops;

create policy "users read own saved trip itinerary"
on public.saved_trip_itinerary_stops
for select
to authenticated
using (
  exists (
    select 1
    from public.saved_trips trip
    where trip.id = trip_id
      and trip.user_id = auth.uid()
  )
);

drop policy if exists "users update own saved trip itinerary"
on public.saved_trip_itinerary_stops;

create policy "users update own saved trip itinerary"
on public.saved_trip_itinerary_stops
for update
to authenticated
using (
  exists (
    select 1
    from public.saved_trips trip
    where trip.id = trip_id
      and trip.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.saved_trips trip
    where trip.id = trip_id
      and trip.user_id = auth.uid()
  )
);

drop policy if exists "users delete own saved trip itinerary"
on public.saved_trip_itinerary_stops;

create policy "users delete own saved trip itinerary"
on public.saved_trip_itinerary_stops
for delete
to authenticated
using (
  exists (
    select 1
    from public.saved_trips trip
    where trip.id = trip_id
      and trip.user_id = auth.uid()
  )
);

-- Bulk regeneration is performed through a SECURITY DEFINER RPC so the
-- client cannot write itinerary rows for another user's trip.
drop function if exists public.replace_saved_trip_itinerary(uuid, jsonb);

create function public.replace_saved_trip_itinerary(
  p_trip_id uuid,
  p_stops jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_day_count integer;
  v_stop jsonb;
  v_content_id uuid;
  v_day_index integer;
  v_start_minute integer;
  v_sort_order integer;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select (end_date - start_date) + 1
  into v_day_count
  from public.saved_trips
  where id = p_trip_id
    and user_id = v_user_id;

  if v_day_count is null then
    raise exception 'Trip not found';
  end if;

  delete from public.saved_trip_itinerary_stops
  where trip_id = p_trip_id;

  for v_stop in
    select value from jsonb_array_elements(coalesce(p_stops, '[]'::jsonb))
  loop
    v_content_id := (v_stop->>'content_id')::uuid;
    v_day_index := (v_stop->>'day_index')::integer;
    v_start_minute := (v_stop->>'start_minute')::integer;
    v_sort_order := (v_stop->>'sort_order')::integer;

    if v_day_index < 0 or v_day_index >= v_day_count then
      raise exception 'Invalid itinerary day index';
    end if;

    if not exists (
      select 1
      from public.saved_trip_items item
      where item.trip_id = p_trip_id
        and item.content_id = v_content_id
    ) then
      raise exception 'Content must belong to the saved trip';
    end if;

    insert into public.saved_trip_itinerary_stops (
      trip_id,
      content_id,
      day_index,
      start_minute,
      sort_order
    )
    values (
      p_trip_id,
      v_content_id,
      v_day_index,
      v_start_minute,
      v_sort_order
    );
  end loop;
end;
$$;

revoke all on function public.replace_saved_trip_itinerary(uuid, jsonb)
from public;

grant execute on function public.replace_saved_trip_itinerary(uuid, jsonb)
to authenticated;
