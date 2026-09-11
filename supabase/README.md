# Edible Supabase

Database migrations are intentionally deferred to the next stage.

Planned schema:
- profiles
- countries
- cities
- categories
- contents
- content_translations
- content_images
- favorites

RLS will be enabled from the first migration.
Guest users will only receive read access to published discovery content.
Authenticated users will own their profile and favorites.
