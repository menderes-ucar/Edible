create table if not exists public.content_description_resolutions (
  id uuid primary key default gen_random_uuid(),
  cache_key text not null unique,
  title text not null,
  locale text not null,
  city text,
  country text,
  category text,
  short_description text not null default '',
  description text not null,
  source text not null,
  source_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.content_description_resolutions enable row level security;

revoke all on table public.content_description_resolutions from anon, authenticated;
grant select on table public.content_description_resolutions to anon, authenticated;

create index if not exists idx_content_description_resolutions_cache_key
  on public.content_description_resolutions(cache_key);

create or replace function public.set_content_description_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_content_description_updated_at
  on public.content_description_resolutions;

create trigger trg_content_description_updated_at
before update on public.content_description_resolutions
for each row execute function public.set_content_description_updated_at();
