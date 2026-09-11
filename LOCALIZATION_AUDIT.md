# Edible localization audit — 2026-09-08

## Exact root cause found
`LocaleProvider.availableLocales` in the uploaded project had only 7 locales:
en, tr, de, fr, es, it, ar.

`AppLanguage` already declared 13 locales, but the provider did not use it. Therefore the language selector could not actually switch to:
zh, ru, ko, ja, pt, nl.

The app was also falling back to English for many legacy keys because the legacy `_values` dictionary is complete only for the original base locales while the release override file contains only additional release keys.

## Fixed in this patch
- LocaleProvider now uses `AppLanguage.supportedLocales` (all 13).
- Locale persistence creates its directory before writing.
- Added 13-language overrides for remaining high-visibility hardcoded UI strings.
- Replaced remaining hardcoded Turkish UI in Home, Community and Public Profile.
- Replaced hardcoded tour filter/list/detail UI strings.
- Replaced hardcoded passport share labels.
- Removed the `const` trap around localized widgets.
- `AppLocalizations.text()` now checks the hardcoded UI override layer first.

## Important
This patch fixes the language-switch mechanism and the hardcoded UI strings found in the uploaded lib tree.

The catalog datasets still contain many canonical place/food names and some source descriptions. Those are content data, not Flutter UI literals. Detail-page descriptions should continue to be resolved through the existing localized Wikipedia/content resolver rather than blindly translating proper names.

Flutter/Dart is not installed in this environment, so `flutter analyze`/`flutter test` could not be executed here.
