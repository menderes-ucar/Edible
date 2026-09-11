-- Edible Phase 29: Saved Trip destination integrity.
-- Existing trip destination is immutable. Create a new trip to change city/country.
create or replace function public.prevent_saved_trip_destination_change()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.country_code is distinct from old.country_code
     or new.country_name is distinct from old.country_name
     or new.city_name is distinct from old.city_name then
    raise exception 'Saved trip destination cannot be changed after creation.';
  end if;
  return new;
end;
$$;

drop trigger if exists saved_trip_destination_immutable on public.saved_trips;
create trigger saved_trip_destination_immutable
before update of country_code, country_name, city_name
on public.saved_trips
for each row
execute function public.prevent_saved_trip_destination_change();
