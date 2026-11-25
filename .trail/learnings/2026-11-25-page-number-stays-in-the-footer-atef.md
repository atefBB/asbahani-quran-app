---
title: Page number stays in the footer instead of the header
author: Atef
date: 2026-11-25
branch: svg-pages
id: l-44877ca5
scope: repo
status: active
replaces: l-db0926ec
src: agent
touches:
  - lib/screens/quran_page.dart
---

## Decided
- The header has no page number and no side marker; it keeps only the hizb and surah labels.
- The original tappable page-number block belongs at the bottom again, restoring `_footerRow(index)` after the expanded page image. Tapping it opens the go-to-page dialog.
- Keep the 10 px spacer below the header so the page artwork's top decoration stays clear.

## Tried and ruled out
- Moving the old footer block into the header was tried and explicitly corrected by the user; the number must stay at the bottom.
- The header bookmark button stays removed; it was not reintroduced with the footer restore.

## In the code
- `lib/screens/quran_page.dart`: `_headerRow` has just the hizb and surah `GestureDetector`s; `_footerRow(index)` holds the original `GestureDetector` -> `Padding(all: 1.0)` -> centered `Row` -> `DefaultTextStyle(fontSize: 12, bold, black)` -> `Text('${index + 1}')`.
- `build()` calls `_footerRow(index)` after the `Expanded` page image; the spacer comment no longer says the footer was removed.
