---
title: bottom sheet juzz/hizb tab merged into surah menu
author: Atef
date: 2026-11-24
branch: svg-pages
id: l-22bf9789
scope: repo
status: active
src: agent
touches:
  - lib/screens/quran_page.dart
---

## Decided
- `lib/screens/quran_menu_tab.dart` combines surahs, juz and hizb in the surah tab with chips (`الكل/سور/أجزاء/أحزاب`) and one search field.
- The bottom sheet now has four tabs; tapping the header hizb/surah text opens the surah tab preselected to that section.
- Persisted `lastTabPanelIndex` values of 4 (the removed juzz/hizb tab) are remapped to 0 in `_showMenu`.

## Watch out
- Numeric search must match exact numbers, not substrings: `جزء 2` otherwise also matches `جزء 20`, and bare `2` matches every page containing a 2. `QuranMenuIndex.search` pairs digits with their remaining non-numeric keyword.
- Widget tests cannot assert offscreen `ListView` headers such as `الأحزاب`; search first so the target header is built.
