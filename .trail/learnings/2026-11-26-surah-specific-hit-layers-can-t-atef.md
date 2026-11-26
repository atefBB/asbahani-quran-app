---
title: "Surah-specific hit layers can't be reused for full-page highlights"
author: Atef
date: 2026-11-26
branch: svg-pages
id: l-e903ee7d
scope: repo
status: active
src: agent
touches:
  - handover.md
  - lib/main.dart
  - lib/screens/quran_page.dart
  - assets/warsh_json/README.md
---

## Decided
- Keep the bundled full-page ayah JSON (`assets/warsh_json/NNN.json`) as the hit layer for the compiled azrak pages. Leave `NNN-surahX.json` and `markers.json` unused until the app renders surah-specific page variants.

## Tried and ruled out
- Compared `106.json` with `106-surah4.json` / `106-surah5.json`: the polygons are in different coordinate spaces. Ayah 4:175 is at y=149.25 in the base layer but y=5.5 in the variant, whose viewBox is a different crop. Mapping variant polygons onto the bundled full page would misalign the highlight overlay.

## Watch out
- `assets/warsh_json/README.md` calls them "surah-specific page variants"; they are separate layouts, not sub-rectangles of the 604 compiled pages shipped in `assets/azrak/`.

In the code: `lib/data/ayah_geometry.dart` (`loadKey`, `viewboxes.json`), `lib/screens/quran_page.dart` (`_highlightFor`, `AyahHighlightPainter`).
