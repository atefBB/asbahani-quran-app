---
title: Page 300 viewBox x=-6 keeps the Warsh page centered
author: Atef
date: 2026-11-23
branch: svg-pages
id: l-da6e4a74
scope: repo
status: active
src: agent
touches:
  - assets/azrak/300.svg
  - assets/warsh_json/viewboxes.json
  - test/ayah_geometry_test.dart
---

## Decided
- Keep `assets/azrak/300.svg` at `viewBox="-6 -2.292 345 550"` and change the matching `300` entry in `assets/warsh_json/viewboxes.json` in the same change.

## Tried and ruled out
- The earlier x=-31.875 came from auto-centering on stray trailing glyphs in the page content path. Rendering at 690x1100 showed a 70px left margin with the right edge clipped; x=-6 gives balanced 19/20px margins.

## Watch out
- Screen-to-ayah hit testing uses the JSON viewBox, so a viewBox-only SVG edit shifts long-press targeting. The JSON/SVG parity test now includes page 300.
