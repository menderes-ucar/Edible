-- Edible production hardening: favorites + SECURITY DEFINER boundaries.
-- Favorites are also used for bundled/offline catalog items. The app resolves
-- those IDs locally, so a hard FK to public.contents prevents legitimate saves
-- whenever the bundled catalog is ahead of the online catalog. RLS remains
-- owner-only.

alter table if exists public.favorites
  drop constraint if exists favorites_content_id_fkey;

comment on table public.favorites is
  'Authenticated user favorites. content_id is an opaque catalog UUID resolved by the app; owner-only RLS protects rows.';

-- Trigger-only SECURITY DEFINER functions must not be callable by arbitrary
-- clients through PostgREST.
revoke all on function public.handle_new_user_subscription() from public;
revoke all on function public.create_message_app_notification() from public;
revoke all on function public.cleanup_saved_trip_itinerary_item() from public;
revoke all on function public.cleanup_saved_trip_itinerary_days() from public;

-- Daily push is an Edge Function, not a client-facing RPC.
-- Keep service-role access at the Edge layer rather than exposing it through
-- SQL grants.


-- Tour user state tables used by the bundled tour catalog. Package IDs are
-- stable application IDs, so they intentionally do not depend on a missing
-- server-side tour catalog table.
create table if not exists public.tour_package_favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  package_id text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, package_id)
);

create table if not exists public.tour_package_ratings (
  user_id uuid not null references auth.users(id) on delete cascade,
  package_id text not null,
  rating smallint not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, package_id)
);

create table if not exists public.user_tour_packages (
  user_id uuid not null references auth.users(id) on delete cascade,
  package_id text not null,
  status text not null check (status in ('active', 'completed')),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, package_id)
);

create table if not exists public.tour_stop_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  package_id text not null,
  stop_id text not null,
  completed boolean not null default false,
  rating smallint check (rating between 1 and 5),
  updated_at timestamptz not null default now(),
  primary key (user_id, package_id, stop_id)
);

create index if not exists tour_package_favorites_package_idx
  on public.tour_package_favorites(package_id);
create index if not exists tour_package_ratings_package_idx
  on public.tour_package_ratings(package_id);

alter table public.tour_package_favorites enable row level security;
alter table public.tour_package_ratings enable row level security;
alter table public.user_tour_packages enable row level security;
alter table public.tour_stop_progress enable row level security;

drop policy if exists "tour favorites own select" on public.tour_package_favorites;
create policy "tour favorites own select" on public.tour_package_favorites
for select to authenticated using (user_id = auth.uid());
drop policy if exists "tour favorites own insert" on public.tour_package_favorites;
create policy "tour favorites own insert" on public.tour_package_favorites
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "tour favorites own delete" on public.tour_package_favorites;
create policy "tour favorites own delete" on public.tour_package_favorites
for delete to authenticated using (user_id = auth.uid());

drop policy if exists "tour ratings own select" on public.tour_package_ratings;
create policy "tour ratings own select" on public.tour_package_ratings
for select to authenticated using (user_id = auth.uid());
drop policy if exists "tour ratings own insert" on public.tour_package_ratings;
create policy "tour ratings own insert" on public.tour_package_ratings
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "tour ratings own update" on public.tour_package_ratings;
create policy "tour ratings own update" on public.tour_package_ratings
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "tour packages own select" on public.user_tour_packages;
create policy "tour packages own select" on public.user_tour_packages
for select to authenticated using (user_id = auth.uid());
drop policy if exists "tour packages own insert" on public.user_tour_packages;
create policy "tour packages own insert" on public.user_tour_packages
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "tour packages own update" on public.user_tour_packages;
create policy "tour packages own update" on public.user_tour_packages
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "tour stop progress own select" on public.tour_stop_progress;
create policy "tour stop progress own select" on public.tour_stop_progress
for select to authenticated using (user_id = auth.uid());
drop policy if exists "tour stop progress own insert" on public.tour_stop_progress;
create policy "tour stop progress own insert" on public.tour_stop_progress
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "tour stop progress own update" on public.tour_stop_progress;
create policy "tour stop progress own update" on public.tour_stop_progress
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Public aggregate only; no user-level rows are exposed.
create or replace view public.tour_package_stats as
select
  p.package_id,
  coalesce(r.rating_average, 0)::double precision as rating_average,
  coalesce(r.rating_count, 0)::bigint as rating_count,
  coalesce(f.favorite_count, 0)::bigint as favorite_count
from (
  select package_id from public.tour_package_ratings
  union
  select package_id from public.tour_package_favorites
) p
left join (
  select package_id, avg(rating)::double precision as rating_average, count(*)::bigint as rating_count
  from public.tour_package_ratings
  group by package_id
) r using (package_id)
left join (
  select package_id, count(*)::bigint as favorite_count
  from public.tour_package_favorites
  group by package_id
) f using (package_id);

grant select on public.tour_package_stats to anon, authenticated;


-- The original trip_plans table was created without RLS. It is currently not
-- used by the Flutter trip-planner path, but leaving it exposed would allow
-- cross-user access if table privileges are granted through the API.
alter table if exists public.trip_plans enable row level security;

drop policy if exists "trip plans own select" on public.trip_plans;
create policy "trip plans own select" on public.trip_plans
for select to authenticated using (user_id = auth.uid());
drop policy if exists "trip plans own insert" on public.trip_plans;
create policy "trip plans own insert" on public.trip_plans
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "trip plans own update" on public.trip_plans;
create policy "trip plans own update" on public.trip_plans
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "trip plans own delete" on public.trip_plans;
create policy "trip plans own delete" on public.trip_plans
for delete to authenticated using (user_id = auth.uid());
