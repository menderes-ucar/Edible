# Edible release image pipeline

The app must not search the internet while the user scrolls. Image discovery is a release-time operation.

## Build

From the Flutter project root:

```text
dart tooling/build_image_manifest.dart
```

The builder scans the complete `lib/` tree and recognizes the catalogue constructors currently used by Edible. It searches Wikimedia Commons first and Openverse second, then accepts only open licences suitable for commercial redistribution (for example CC0, Public Domain, CC BY and CC BY-SA). It records the image URL, source page, author and licence metadata.

If an item cannot be matched confidently, it is written to:

```text
tooling/image_manifest_missing.txt
```

The build exits with code 1 while any item is unresolved. **Do not ship with unresolved items.**

## Verify

```text
dart tooling/verify_image_manifest.dart
```

This is a release gate: a catalogue title without an exact manifest key fails verification.

## Runtime rule

`SmartContentImage` may only use exact generated/verified/curated records. It must not use generic category URLs, random Unsplash/Pexels queries, or live search results.

Wikimedia's own guidance says the applicable licence, source and author should be identifiable on the file description page, and Commons excludes non-commercial-only media. The builder therefore keeps licence/source metadata beside each selected image rather than treating a bare image URL as sufficient.
