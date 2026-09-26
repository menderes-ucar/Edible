# Edible Supabase Security Hardening — 2026-09-20

Applied fixes:

1. `get_public_profile_visits(uuid)` is now authenticated-only and can only return the caller's own travel history. Anonymous access is revoked.
2. `get_public_profile_details(uuid)` is now authenticated-only. Private registration fields (first name, last name, age, hometown, gender) are returned only when the caller requests their own profile. Other authenticated users receive only display name/avatar.
3. `resolve-content-image` now requires a valid Supabase access token (`verify_jwt = true`) and independently validates the token. It is rate-limited to 30 requests per user per UTC hour, with server-side counters.
4. Message push notifications now use an atomic Postgres claim to prevent duplicate push sends for the same message/recipient pair. A stale in-progress claim can be reclaimed after five minutes.
5. New security tables have no client privileges. Their helper functions are executable only by `service_role`.

Validation performed locally:
- TypeScript syntax transpilation passed for both modified Edge Functions.
- Migration references were checked.

Not performed here:
- Live Supabase migration execution.
- Live RLS/anonymous/authenticated penetration tests.
- Flutter integration test after changing the image resolver from public to authenticated.

After applying the migration, deploy the two modified Edge Functions and test the affected app flows.
