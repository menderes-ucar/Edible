-- Edible production notification infrastructure.
-- Creates an in-app inbox, device token registry, message-notification trigger,
-- and RLS policies. FCM delivery itself is handled by Edge Functions so that
-- Firebase service-account credentials never ship inside the Flutter app.

create table if not exists public.device_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios', 'web')),
  enabled boolean not null default true,
  language_code text not null default 'en',
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

create index if not exists device_push_tokens_user_enabled_idx
  on public.device_push_tokens(user_id, enabled);

create table if not exists public.app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  dedupe_key text unique,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists app_notifications_user_created_idx
  on public.app_notifications(user_id, created_at desc);

create index if not exists app_notifications_user_unread_idx
  on public.app_notifications(user_id, created_at desc)
  where read_at is null;

alter table public.device_push_tokens enable row level security;
alter table public.app_notifications enable row level security;

drop policy if exists "device_push_tokens_select_own" on public.device_push_tokens;
create policy "device_push_tokens_select_own"
on public.device_push_tokens for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "device_push_tokens_insert_own" on public.device_push_tokens;
create policy "device_push_tokens_insert_own"
on public.device_push_tokens for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "device_push_tokens_update_own" on public.device_push_tokens;
create policy "device_push_tokens_update_own"
on public.device_push_tokens for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "device_push_tokens_delete_own" on public.device_push_tokens;
create policy "device_push_tokens_delete_own"
on public.device_push_tokens for delete
to authenticated
using (user_id = auth.uid());

drop policy if exists "app_notifications_select_own" on public.app_notifications;
create policy "app_notifications_select_own"
on public.app_notifications for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "app_notifications_update_own" on public.app_notifications;
create policy "app_notifications_update_own"
on public.app_notifications for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Only server-side code may create notifications. This prevents a client from
-- fabricating notifications for another account.
drop policy if exists "app_notifications_insert_service_only" on public.app_notifications;

create or replace function public.create_message_app_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient_id uuid;
  sender_name text;
begin
  select p.user_id
    into recipient_id
    from public.direct_conversation_participants p
   where p.conversation_id = new.conversation_id
     and p.user_id <> new.sender_id
   limit 1;

  if recipient_id is null then
    return new;
  end if;

  select coalesce(nullif(trim(pr.display_name), ''), 'Edible kullanıcısı')
    into sender_name
    from public.profiles pr
   where pr.id = new.sender_id;

  insert into public.app_notifications (
    user_id,
    type,
    title,
    body,
    data,
    dedupe_key
  ) values (
    recipient_id,
    'message',
    coalesce(sender_name, 'Edible kullanıcısı'),
    left(new.body, 240),
    jsonb_build_object(
      'route', '/messages/chat/' || new.sender_id::text,
      'conversation_id', new.conversation_id::text,
      'message_id', new.id::text,
      'type', 'message'
    ),
    'message:' || new.id::text
  )
  on conflict (dedupe_key) do nothing;

  return new;
end;
$$;

drop trigger if exists direct_message_app_notification_trigger
  on public.direct_messages;

create trigger direct_message_app_notification_trigger
after insert on public.direct_messages
for each row
execute function public.create_message_app_notification();

-- Realtime is used by the in-app notification center.
do $$
begin
  alter publication supabase_realtime add table public.app_notifications;
exception
  when duplicate_object then null;
end $$;

grant select, insert, update, delete on public.device_push_tokens to authenticated;
grant select, update on public.app_notifications to authenticated;
