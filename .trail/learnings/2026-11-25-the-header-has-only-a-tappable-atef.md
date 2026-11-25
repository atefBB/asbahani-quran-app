---
title: The header has only a tappable page number now
author: Atef
date: 2026-11-25
branch: svg-pages
id: l-3f72606c
scope: repo
status: active
replaces: l-b8446f14
src: agent
touches:
  - lib/screens/quran_page.dart
---

## Decided
- No page-side indicator in the header: the vertical bar and its side tooltip are gone.
- The header keeps only the page number, still tappable to open the go-to-page dialog, at fontSize 12 bold black.

## Tried and ruled out
- Arrow, full-height bar, mihrab ornament and a smaller 8 px dash were all removed in sequence; the user wanted none of them.

## In the code
- `lib/screens/quran_page.dart` `_headerRow`: the page number is a plain `GestureDetector` + `Text`; `isRightPage`, the bar `SizedBox` widgets and the side tooltip were deleted.
