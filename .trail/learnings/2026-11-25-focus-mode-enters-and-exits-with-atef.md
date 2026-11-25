---
title: Focus mode enters and exits with edge swipes on the same page view
author: Atef
date: 2026-11-25
branch: svg-pages
id: l-caab7e2b
scope: repo
status: active
src: agent
touches:
  - lib/screens/quran_page.dart
---

## Decided
- Focus mode stays on the existing `PageView`: swipe up from the bottom edge to enter, swipe down from the top edge to exit. A short-lived pill at the top also exits.
- The header, top spacer, and footer fade and collapse together; the page image keeps its gestures. Focus mode is session-only, but the one-time gesture hint is persisted.
- Single tap still opens the menu, long-press still bookmarks an ayah on Azrak pages, and horizontal swipes still turn pages.

## Tried and ruled out
- Double-tap would either fire the menu too or delay single taps while Flutter waits to distinguish tap from double-tap.
- Long-press is already claimed by ayah bookmarking.
- A separate screen/route was ruled out: the user explicitly wants the same page view.

## In the code
- `lib/screens/quran_page.dart`: `_focusMode`, `_focusHintSeen`, `_showFocusHint`, `_focusControlsVisible`, `_focusDragDistance` and two `Timer`s hold state; `_setFocusMode`, `_animatedChrome`, `_focusEdgeStrip`, `_focusExitPill` implement the behavior.
- `build()` wraps `SafeArea` > `Column`; header + 10 px spacer and footer are wrapped in `_animatedChrome`, and the edge strips/pill are `Positioned` in the existing `Stack`.
- Edge strips use `HitTestBehavior.translucent` so tapping the footer page number still opens go-to-page; `SharedPreferences` key `focusHintSeen` stores only the hint, not the mode.
