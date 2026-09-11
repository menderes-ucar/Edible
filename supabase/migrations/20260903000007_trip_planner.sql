create table if not exists public.trip_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  city_name text not null,
  duration_hours integer not null,
  created_at timestamptz default now()
);