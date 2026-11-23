---
title: quran_page.dart compiled azrak pages need AssetBytesLoader
author: Atef
date: 2026-11-23
branch: svg-pages
id: l-325dd7fc
scope: repo
status: active
src: agent
touches:
  - docs/ayah-bookmarking.md
  - lib/screens/quran_page.dart
  - pubspec.lock
  - pubspec.yaml
  - test/ayah_geometry_test.dart
  - test/fixtures/azrak/1.svg
  - test/fixtures/azrak/10.svg
  - test/fixtures/azrak/100.svg
  - test/fixtures/azrak/101.svg
  - test/fixtures/azrak/102.svg
---

## Decided
- Render azrak pages from compiled `.svg.vec` assets with `vector_graphics`' `AssetBytesLoader` / `createCompatVectorGraphic` in `lib/screens/quran_page.dart`.
- Generate those assets with `tool/compile_azrak_svgs.dart`; keep raw SVGs in `test/fixtures/azrak/` as parity fixtures so they are not bundled into the app.

## Tried and ruled out
- `SvgPicture.asset('...svg.vec')` from `flutter_svg` 2.1.0 compiles but renders blank. Compiled vec bytes must be loaded through `AssetBytesLoader`.
- The default overdraw optimizer crashes on these SVGs with `Unsupported operation: Infinity or NaN toInt`; use `enableOverdrawOptimizer: false`.
- Initializing the tessellator makes files ~3x smaller (77 MB vs 262 MB) but page 300 renders almost blank (640 non-white pixels vs 32,293); keep it disabled.

## Watch out
- Debug `flutter run -d web-server` produced a `web_entrypoint.dart.js` MIME error and blank screenshots. Use a static `flutter build web --release` plus `python3 -m http.server` for visual parity checks.
- `test/ayah_geometry_test.dart` reads raw SVGs from `test/fixtures/azrak/` with `dart:io`, not `rootBundle`.
