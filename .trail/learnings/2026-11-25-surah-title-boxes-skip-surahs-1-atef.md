---
title: Surah-title boxes skip surahs 1 and 2 and fit only the title line
author: Atef
date: 2026-11-25
branch: svg-pages
id: l-89e6c1a5
scope: repo
status: active
replaces: l-6787d7fb
src: agent
touches:
  - lib/screens/quran_page.dart
  - pubspec.yaml
---

## Decided
- Frame only surah titles actually printed in the Azrak page artwork. Surahs 1 and 2 have no title in those SVGs, so pages 1 and 2 carry no box.
- The box hugs the full horizontal extent of the printed title line — not the whole page width, and not the Basmala band below it.

## Tried and ruled out
- Stretching boxes to the full page width was rejected; the user wants the width of the surah-name line itself.
- The wide three-subpath band is the Basmala (identical across pages), so framing it frames the wrong line.

## In the code
- `assets/azrak_surah_titles.json` now has 94 pages; pages 1 and 2 are absent, and each rect's normalized `x`/`w` come from the narrow glyph band above the ayah-1 polygon.
- `test/surah_title_markers_test.dart` guards those exclusions and the line-width bounds.
