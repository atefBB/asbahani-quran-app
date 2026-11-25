---
title: Surah title boxes were dropped from the Azrak pages
author: Atef
date: 2026-11-25
branch: svg-pages
id: l-b8446f14
scope: repo
status: active
replaces: l-89e6c1a5
src: agent
touches:
  - lib/screens/quran_page.dart
  - pubspec.yaml
---

## Decided
- No rectangle overlays on surah titles inside Azrak pages. The user rejected the boxes after the width/exclusion fixes.
- The header page-side marker stays, but as a small dash: 1.2 px wide and 8 px tall, centred vertically beside the page number — not stretched to the number's full height.

## Tried and ruled out
- Tight line-width boxes: rejected.
- Full-page-width boxes: rejected.
- Skipping surahs 1 and 2 (which have no printed title in the SVGs): correct, but the whole feature was still unwanted.

## In the code
- Removed `assets/azrak_surah_titles.json`, `lib/data/surah_title_markers.dart`, `test/surah_title_markers_test.dart`, their `pubspec.yaml` asset entry, and the import/overlay/painter from `lib/screens/quran_page.dart`.
- The header marker is now plain `SizedBox(width: 1.2, height: 8)` children in the page-number row; `IntrinsicHeight`/stretch are gone.
