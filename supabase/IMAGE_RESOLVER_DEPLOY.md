# Image Resolver deployment checklist

The current project archive had a critical mismatch:
- Flutter `SupabaseProjectConfig` points to `lylliolgjxmbpawkriww`.
- The supplied `supabase/.temp/linked-project.json` points to `xfgusdjbyxhloytifcdj` (`karavan-kamp`).

Do NOT deploy this function while the CLI is linked to `xfgusdjbyxhloytifcdj`.

## 1. Link the Supabase project used by Edible

From the project root:

```powershell
supabase link --project-ref lylliolgjxmbpawkriww
```

## 2. Deploy the resolver

```powershell
supabase functions deploy resolve-content-image --project-ref lylliolgjxmbpawkriww
```

The function is configured as public because Explore image resolution must work before/without a user JWT:

```toml
[functions.resolve-content-image]
verify_jwt = false
```

Supabase documents that `verify_jwt` defaults to true and can be disabled per function in `supabase/config.toml`.

## 3. Optional provider secrets

The resolver works without these keys using free/public providers:
- Wikimedia Commons
- Openverse
- Wikipedia
- Library of Congress
- Internet Archive

For additional providers, add project secrets:

```powershell
supabase secrets set PEXELS_API_KEY=...
supabase secrets set UNSPLASH_ACCESS_KEY=...
supabase secrets set PIXABAY_API_KEY=...
supabase secrets set FLICKR_API_KEY=...
supabase secrets set EUROPEANA_API_KEY=...
```

Do not put these keys into Flutter `--dart-define` values. They belong in Edge Function secrets.

## 4. Verify

After deployment, the function should be reachable at:

`https://lylliolgjxmbpawkriww.supabase.co/functions/v1/resolve-content-image`

Test with the Supabase Dashboard Edge Function tester or a POST request containing:

```json
{
  "title": "Hagia Sophia",
  "city": "Istanbul",
  "country": "Turkey",
  "locale": "en"
}
```

A successful response contains:

```json
{
  "imageUrl": "...",
  "provider": "...",
  "sourceUrl": "...",
  "attribution": "...",
  "score": 0.0
}
```
