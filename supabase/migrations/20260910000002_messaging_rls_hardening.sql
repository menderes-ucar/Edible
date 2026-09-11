-- Edible: direct messaging RLS + notification hardening
-- Fixes the participant-RLS deadlock that made direct_messages SELECT/realtime empty.

alter table public.direct_conversation_participants enable row level security;

drop policy if exists direct_conversation_participants_select on public.direct_conversation_participants;
create policy direct_conversation_participants_select
on public.direct_conversation_participants
for select to authenticated
using (user_id = auth.uid());

-- Keep conversation/message reads explicitly participant-scoped.
drop policy if exists direct_conversations_select on public.direct_conversations;
create policy direct_conversations_select
on public.direct_conversations
for select to authenticated
using (
  exists (
    select 1
    from public.direct_conversation_participants p
    where p.conversation_id = direct_conversations.id
      and p.user_id = auth.uid()
  )
);

drop policy if exists direct_messages_select on public.direct_messages;
create policy direct_messages_select
on public.direct_messages
for select to authenticated
using (
  exists (
    select 1
    from public.direct_conversation_participants p
    where p.conversation_id = direct_messages.conversation_id
      and p.user_id = auth.uid()
  )
);

-- Harden read receipts: users can only mark messages in conversations they belong to.
create or replace function public.mark_direct_messages_read(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  if not exists (
    select 1
    from public.direct_conversation_participants
    where conversation_id = p_conversation_id
      and user_id = me
  ) then
    raise exception 'not a participant';
  end if;

  update public.direct_messages
  set read_at = now()
  where conversation_id = p_conversation_id
    and sender_id <> me
    and read_at is null;

  update public.direct_conversation_participants
  set last_read_at = now()
  where conversation_id = p_conversation_id
    and user_id = me;
end;
$$;

grant execute on function public.mark_direct_messages_read(uuid) to authenticated;
