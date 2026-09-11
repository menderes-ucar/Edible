create table if not exists public.saved_trips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  country_code text not null,
  country_name text not null,
  city_name text not null,
  start_date date not null,
  end_date date not null,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint saved_trips_dates_valid
    check (end_date >= start_date)
);

create index if not exists saved_trips_user_start_idx
on public.saved_trips(user_id, start_date);

create table if not exists public.saved_trip_items (
  trip_id uuid not null references public.saved_trips(id)
    on delete cascade,
  content_id uuid not null references public.contents(id)
    on delete cascade,
  created_at timestamptz not null default now(),
  primary key (trip_id, content_id)
);

alter table public.saved_trips enable row level security;
alter table public.saved_trip_items enable row level security;

drop policy if exists "users read own saved trips"
on public.saved_trips;

create policy "users read own saved trips"
on public.saved_trips
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "users insert own saved trips"
on public.saved_trips;

create policy "users insert own saved trips"
on public.saved_trips
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "users update own saved trips"
on public.saved_trips;

create policy "users update own saved trips"
on public.saved_trips
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users delete own saved trips"
on public.saved_trips;

create policy "users delete own saved trips"
on public.saved_trips
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "users read own saved trip items"
on public.saved_trip_items;

create policy "users read own saved trip items"
on public.saved_trip_items
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

drop policy if exists "users insert own saved trip items"
on public.saved_trip_items;

create policy "users insert own saved trip items"
on public.saved_trip_items
for insert
to authenticated
with check (
  exists (
    select 1
    from public.saved_trips trip
    where trip.id = trip_id
      and trip.user_id = auth.uid()
  )
);

drop policy if exists "users delete own saved trip items"
on public.saved_trip_items;

create policy "users delete own saved trip items"
on public.saved_trip_items
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
