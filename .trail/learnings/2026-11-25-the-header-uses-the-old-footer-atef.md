---
title: The header uses the old footer page-number block
author: Atef
date: 2026-11-25
branch: svg-pages
id: l-db0926ec
scope: repo
status: active
replaces: l-3f72606c
src: agent
touches:
  - lib/screens/quran_page.dart
---

## Decided
- The header page number is the original bottom-number widget: `GestureDetector` -> `Padding(all: 1.0)` -> centered `Row` -> `DefaultTextStyle(fontSize: 12, bold, black)` -> `Text('${index + 1}')`.
- Tapping it still opens the go-to-page dialog. No side indicator, no tooltip.

## Tried and ruled out
- A plain `Text` with an explicit style looked different; the user asked for the old footer block itself.

## In the code
- `lib/screens/quran_page.dart` has `_pageNumberBlock(index)` holding that old footer widget; `_headerRow` calls it instead of building a `Text` inline.
- `mainAxisSize: MainAxisSize.min` was added to the inner `Row`, since a header `Row` gives its children unbounded width.
