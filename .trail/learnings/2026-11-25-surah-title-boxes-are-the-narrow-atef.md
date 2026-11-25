---
title: Surah-title boxes are the narrow glyph band above the Basmala
author: Atef
date: 2026-11-25
branch: svg-pages
id: l-6787d7fb
scope: repo
status: active
src: agent
touches:
  - lib/screens/quran_page.dart
  - pubspec.yaml
---

## Decided
- Frame the surah title printed inside Azrak page artwork with a thin black rectangle on surah-start pages.
- The title is the *narrow* band of many small glyph subpaths directly above a longer three-part Basmala band; the wide band is the Basmala, not the title.

## Tried and ruled out
- Framing the wide band produced a box around the Basmala and was rejected visually.
- Guessing a fixed offset from the first ayah polygon misses titles that appear mid-page (e.g. page 106).

## In the code
- `assets/azrak_surah_titles.json` holds normalized page-relative rects for 96 pages, generated from `test/fixtures/azrak/*.svg` with a Python path parser: cluster content subpaths by y, pick narrow candidates above the ayah-1 polygon, convert through the SVG transform chain, then divide by the page viewBox.
- `lib/data/surah_title_markers.dart` loads and caches that JSON; `SurahTitleBoxPainter` in `lib/screens/quran_page.dart` draws the boxes over the SVG.
