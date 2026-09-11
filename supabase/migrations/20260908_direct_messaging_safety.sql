-- Edible: production direct messaging + block/report foundation.
-- Run once in Supabase SQL Editor. This migration does not alter existing community/profile tables.

create extension if not exists pgcrypto;

create table if not exists public.direct_conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique_key text not null unique
);

create table if not exists public.direct_conversation_participants (
  conversation_id uuid not null references public.direct_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);

create table if not exists public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.direct_conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 4000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists direct_messages_conversation_created_idx on public.direct_messages(conversation_id, created_at);
create index if not exists direct_participants_user_idx on public.direct_conversation_participants(user_id, conversation_id);

create table if not exists public.blocked_users (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (char_length(trim(reason)) between 2 and 120),
  details text,
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  check (reporter_id <> reported_user_id)
);

create index if not exists user_reports_status_created_idx on public.user_reports(status, created_at desc);
create index if not exists user_reports_reported_user_idx on public.user_reports(reported_user_id, created_at desc);

alter table public.direct_conversations enable row level security;
alter table public.direct_conversation_participants enable row level security;
alter table public.direct_messages enable row level security;
alter table public.blocked_users enable row level security;
alter table public.user_reports enable row level security;

create or replace function public.is_user_blocked(p_other_user_id uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.blocked_users where blocker_id = auth.uid() and blocked_id = p_other_user_id);
$$;

create or replace function public.get_or_create_direct_conversation(p_other_user_id uuid)
returns uuid language plpgsql security definer set search_path = public
as $$
declare
  me uuid := auth.uid();
  k text;
  cid uuid;
begin
  if me is null or p_other_user_id is null or me = p_other_user_id then raise exception 'invalid conversation'; end if;
  k := least(me::text, p_other_user_id::text) || ':' || greatest(me::text, p_other_user_id::text);
  insert into public.direct_conversations(unique_key) values(k) on conflict(unique_key) do update set updated_at = now() returning id into cid;
  insert into public.direct_conversation_participants(conversation_id,user_id) values(cid,me),(cid,p_other_user_id) on conflict do nothing;
  return cid;
end;
$$;

create or replace function public.send_direct_message(p_conversation_id uuid, p_body text)
returns uuid language plpgsql security definer set search_path = public
as $$
declare
  me uuid := auth.uid();
  mid uuid;
  other uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  if not exists(select 1 from public.direct_conversation_participants where conversation_id=p_conversation_id and user_id=me) then raise exception 'not a participant'; end if;
  select user_id into other from public.direct_conversation_participants where conversation_id=p_conversation_id and user_id<>me limit 1;
  if other is null or public.is_user_blocked(other) or exists(select 1 from public.blocked_users where blocker_id=other and blocked_id=me) then raise exception 'messaging blocked'; end if;
  insert into public.direct_messages(conversation_id,sender_id,body) values(p_conversation_id,me,trim(p_body)) returning id into mid;
  update public.direct_conversations set updated_at=now() where id=p_conversation_id;
  return mid;
end;
$$;

create or replace function public.mark_direct_messages_read(p_conversation_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
declare me uuid := auth.uid();
begin
  update public.direct_messages set read_at=now() where conversation_id=p_conversation_id and sender_id<>me and read_at is null;
  update public.direct_conversation_participants set last_read_at=now() where conversation_id=p_conversation_id and user_id=me;
end;
$$;

create or replace function public.get_my_conversations()
returns table(conversation_id uuid, other_user_id uuid, display_name text, avatar_url text, last_message text, last_message_at timestamptz, unread_count bigint, is_blocked boolean)
language sql security definer set search_path = public
as $$
  select c.id, p2.user_id,
         coalesce(pr.display_name,'Edible kullanıcısı'), pr.avatar_url,
         lm.body, lm.created_at,
         (select count(*) from public.direct_messages um where um.conversation_id=c.id and um.sender_id<>auth.uid() and um.read_at is null),
         exists(select 1 from public.blocked_users b where b.blocker_id=auth.uid() and b.blocked_id=p2.user_id)
  from public.direct_conversations c
  join public.direct_conversation_participants p1 on p1.conversation_id=c.id and p1.user_id=auth.uid()
  join public.direct_conversation_participants p2 on p2.conversation_id=c.id and p2.user_id<>auth.uid()
  left join lateral (select body,created_at from public.direct_messages m where m.conversation_id=c.id order by m.created_at desc limit 1) lm on true
  left join public.profiles pr on pr.id=p2.user_id
  order by coalesce(lm.created_at,c.updated_at) desc;
$$;

create or replace function public.set_user_block(p_other_user_id uuid, p_blocked boolean)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if p_blocked then
    insert into public.blocked_users(blocker_id,blocked_id) values(auth.uid(),p_other_user_id) on conflict do nothing;
  else
    delete from public.blocked_users where blocker_id=auth.uid() and blocked_id=p_other_user_id;
  end if;
end;
$$;

create or replace function public.report_user(p_reported_user_id uuid, p_reason text, p_details text default null)
returns uuid language plpgsql security definer set search_path = public
as $$
declare rid uuid;
begin
  if auth.uid() is null or auth.uid()=p_reported_user_id then raise exception 'invalid report'; end if;
  insert into public.user_reports(reporter_id,reported_user_id,reason,details) values(auth.uid(),p_reported_user_id,trim(p_reason),nullif(trim(p_details),'')) returning id into rid;
  return rid;
end;
$$;

grant execute on function public.is_user_blocked(uuid) to authenticated;
grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;
grant execute on function public.send_direct_message(uuid,text) to authenticated;
grant execute on function public.mark_direct_messages_read(uuid) to authenticated;
grant execute on function public.get_my_conversations() to authenticated;
grant execute on function public.set_user_block(uuid,boolean) to authenticated;
grant execute on function public.report_user(uuid,text,text) to authenticated;

drop policy if exists direct_conversations_select on public.direct_conversations;
create policy direct_conversations_select on public.direct_conversations for select to authenticated using (exists(select 1 from public.direct_conversation_participants p where p.conversation_id=id and p.user_id=auth.uid()));

drop policy if exists direct_messages_select on public.direct_messages;
create policy direct_messages_select on public.direct_messages for select to authenticated using (exists(select 1 from public.direct_conversation_participants p where p.conversation_id=direct_messages.conversation_id and p.user_id=auth.uid()));

drop policy if exists blocked_users_own on public.blocked_users;
create policy blocked_users_own on public.blocked_users for select to authenticated using (blocker_id=auth.uid());

drop policy if exists user_reports_own_insert on public.user_reports;
create policy user_reports_own_insert on public.user_reports for insert to authenticated with check (reporter_id=auth.uid());

-- Realtime for live chat. Safe if already present only when the table is not yet in publication.
alter publication supabase_realtime add table public.direct_messages;
