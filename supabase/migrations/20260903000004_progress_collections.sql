create table if not exists public.content_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  content_id uuid not null references public.contents(id) on delete cascade,
  progress_type text not null check (progress_type in ('visited','tried')),
  created_at timestamptz not null default now(),
  primary key (user_id, content_id, progress_type)
);
alter table public.content_progress enable row level security;
create policy "users read own progress" on public.content_progress for select to authenticated using (auth.uid() = user_id);
create policy "users add own progress" on public.content_progress for insert to authenticated with check (auth.uid() = user_id);
create policy "users delete own progress" on public.content_progress for delete to authenticated using (auth.uid() = user_id);

create table if not exists public.trip_collections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.trip_collections enable row level security;
create policy "users read own collections" on public.trip_collections for select to authenticated using (auth.uid() = user_id);
create policy "users create own collections" on public.trip_collections for insert to authenticated with check (auth.uid() = user_id);
create policy "users update own collections" on public.trip_collections for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users delete own collections" on public.trip_collections for delete to authenticated using (auth.uid() = user_id);

create table if not exists public.trip_collection_items (
  collection_id uuid not null references public.trip_collections(id) on delete cascade,
  content_id uuid not null references public.contents(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (collection_id, content_id)
);
alter table public.trip_collection_items enable row level security;
create policy "users read own collection items" on public.trip_collection_items for select to authenticated using (exists(select 1 from public.trip_collections c where c.id=collection_id and c.user_id=auth.uid()));
create policy "users add own collection items" on public.trip_collection_items for insert to authenticated with check (exists(select 1 from public.trip_collections c where c.id=collection_id and c.user_id=auth.uid()));
create policy "users delete own collection items" on public.trip_collection_items for delete to authenticated using (exists(select 1 from public.trip_collections c where c.id=collection_id and c.user_id=auth.uid()));
