-- Phase 24: keep persisted itinerary rows consistent when a Saved Trip is
-- edited after an itinerary has already been generated.

-- 1) Removing a discovery from saved_trip_items must also remove it from the
-- itinerary. The itinerary table cannot express this relationship with a
-- simple FK because ownership is (trip_id, content_id), so use a trigger.
create or replace function public.cleanup_saved_trip_itinerary_item()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.saved_trip_itinerary_stops
  where trip_id = old.trip_id
    and content_id = old.content_id;

  return old;
end;
$$;

drop trigger if exists cleanup_saved_trip_itinerary_item_trigger
on public.saved_trip_items;

create trigger cleanup_saved_trip_itinerary_item_trigger
before delete on public.saved_trip_items
for each row
execute function public.cleanup_saved_trip_itinerary_item();

-- 2) If a trip is shortened from e.g. 5 days to 3 days, itinerary rows on
-- day indexes 3/4 would become impossible to display. Remove only those
-- out-of-range rows and keep valid earlier days intact.
create or replace function public.cleanup_saved_trip_itinerary_days()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_day_count integer;
begin
  v_day_count := (new.end_date - new.start_date) + 1;

  delete from public.saved_trip_itinerary_stops
  where trip_id = new.id
    and day_index >= v_day_count;

  return new;
end;
$$;

drop trigger if exists cleanup_saved_trip_itinerary_days_trigger
on public.saved_trips;

create trigger cleanup_saved_trip_itinerary_days_trigger
after update of start_date, end_date on public.saved_trips
for each row
when (
  old.start_date is distinct from new.start_date
  or old.end_date is distinct from new.end_date
)
execute function public.cleanup_saved_trip_itinerary_days();

revoke all on function public.cleanup_saved_trip_itinerary_item()
from public;

revoke all on function public.cleanup_saved_trip_itinerary_days()
from public;
