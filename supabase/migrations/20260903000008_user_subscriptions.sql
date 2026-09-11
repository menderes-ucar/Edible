create table if not exists public.user_subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plan text not null default 'free' check (plan in ('free', 'premium')),
  status text not null default 'inactive'
    check (status in ('inactive', 'active', 'trialing', 'expired', 'cancelled')),
  provider text,
  provider_customer_id text,
  provider_entitlement_id text,
  started_at timestamptz,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.user_subscriptions enable row level security;

drop policy if exists "users read own subscription"
on public.user_subscriptions;

create policy "users read own subscription"
on public.user_subscriptions
for select
to authenticated
using (auth.uid() = user_id);

-- Client writes are intentionally not allowed.
-- Subscription state should be updated by a trusted backend/webhook later.

insert into public.user_subscriptions (
  user_id,
  plan,
  status,
  updated_at
)
select
  id,
  'free',
  'inactive',
  now()
from auth.users
on conflict (user_id) do nothing;

create or replace function public.handle_new_user_subscription()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_subscriptions (
    user_id,
    plan,
    status,
    updated_at
  )
  values (
    new.id,
    'free',
    'inactive',
    now()
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_subscription on auth.users;

create trigger on_auth_user_created_subscription
after insert on auth.users
for each row
execute function public.handle_new_user_subscription();
