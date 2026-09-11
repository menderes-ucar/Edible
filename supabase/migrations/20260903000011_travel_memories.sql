create table if not exists public.travel_memories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  travel_visit_id uuid not null references public.travel_visits(id)
    on delete cascade,

  country_code text not null,
  country_name text not null,
  city_name text not null,
  visit_date date not null,

  title text not null default '',
  note text not null default '',
  favorite_food text not null default '',
  rating integer check (rating between 1 and 5),
  mood text check (
    mood is null or
    mood in ('happy', 'amazed', 'relaxed', 'adventurous')
  ),

  photo_paths text[] not null default '{}'::text[],

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique(user_id, travel_visit_id)
);

create index if not exists travel_memories_user_date_idx
on public.travel_memories(user_id, visit_date desc);

alter table public.travel_memories enable row level security;

drop policy if exists "users read own travel memories"
on public.travel_memories;

create policy "users read own travel memories"
on public.travel_memories
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "users insert own travel memories"
on public.travel_memories;

create policy "users insert own travel memories"
on public.travel_memories
for insert
to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.travel_visits visit
    where visit.id = travel_visit_id
      and visit.user_id = auth.uid()
  )
);

drop policy if exists "users update own travel memories"
on public.travel_memories;

create policy "users update own travel memories"
on public.travel_memories
for update
to authenticated
using (auth.uid() = user_id)
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.travel_visits visit
    where visit.id = travel_visit_id
      and visit.user_id = auth.uid()
  )
);

drop policy if exists "users delete own travel memories"
on public.travel_memories;

create policy "users delete own travel memories"
on public.travel_memories
for delete
to authenticated
using (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values (
  'travel-memory-photos',
  'travel-memory-photos',
  false
)
on conflict (id) do update
set public = false;

drop policy if exists "users read own travel memory photos"
on storage.objects;

create policy "users read own travel memory photos"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'travel-memory-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users upload own travel memory photos"
on storage.objects;

create policy "users upload own travel memory photos"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'travel-memory-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users update own travel memory photos"
on storage.objects;

create policy "users update own travel memory photos"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'travel-memory-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'travel-memory-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users delete own travel memory photos"
on storage.objects;

create policy "users delete own travel memory photos"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'travel-memory-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);
