# Handover

Living document for the `svg-pages` branch. Update it whenever a backlog item
starts or finishes.

## Current state

- Branch: `svg-pages`
- Latest tag: `v1.10.0-beta` (`2c8c107`)
- Latest release APK: **331.8 MB / 316 MiB** (`v1.10.0-beta`), down from
  339.3 MB at `v1.9.9-beta`.
- `flutter analyze`: clean
- `flutter test`: 15/15 passing

The app bundles two complete mushaf styles: 604 Asbahani PNG pages and 604
compiled Warsh `.svg.vec` pages. The ayah hit layer comes from vendored
`assets/warsh_json/`, not from parsing the SVGs.

## Size background

The APK jumped from 241.8 MB (`v1.9.7`, raw SVGs) to 338.9 MB (`v1.9.8`,
compiled `.vec`) even though the source assets shrank from 329 MB to 262 MB.
Reason: raw SVG text compresses ~68% inside the APK, while binary vec data
compresses only ~23%. Azrak assets alone went from 111.3 MB to 209.6 MB
deflated.

The menu change in `v1.9.9` added only ~0.36 MB.

## Backlog

Status legend: `[done]`, `[in progress]`, `[open]`, `[declined]`.

### 1. Split Android builds by ABI / publish AAB — `[open]`

The universal APK carries native libraries for three ABIs (49.0 MB total):
arm64-v8a 16.7 MB, armeabi-v7a 14.1 MB, x86_64 18.2 MB.
`flutter build apk --split-per-abi` or an AAB would cut an arm64 download by
roughly 32 MB with no visual risk. GitHub releases need separate split APKs;
Play can use the AAB.

### 2. Remove unused bundled assets — `[done]`

- Deleted `assets/quran.db` (unused; 2.436 MB compressed in the APK).
- Removed the `arabic_font` dependency (71 files, 4.996 MB compressed) and the
  unused local `avenir` family / `avenir-regular.otf` (0.037 MB). Vendored only
  Avenir Arabic Regular into `assets/fonts/AvenirArabic/` with its MIT licence;
  the theme now uses `fontFamily: 'Avenir Arabic'` from the app bundle.
- Removed the release `INTERNET` permission from
  `android/app/src/main/AndroidManifest.xml` (debug/profile manifests keep it
  for the Flutter tool).
- Updated README references to `quran.db`, `arabic_font` and the azrak asset type.
- **Measured asset saving: 7.431 MB deflated**; the released APK dropped
  7,467,262 bytes (339,296,477 → 331,829,215) after Dex/manifest changes.
- Verified: `flutter pub get`, `flutter analyze` clean, `flutter test` 15/15, and
  a clean `flutter build bundle` contains only the vendored Avenir font — no
  `quran.db`, `avenir-regular.otf` or `arabic_font` package assets.
- CI built and published `v1.10.0-beta` successfully; the released APK was
  inspected and contains none of the three removed assets.

### 3. Half-precision compiled SVG pages — `[declined]`

`--use-half-precision-control-points` would cut azrak from 209.6 MB to 82.4 MB
deflated, projecting a ~212 MB APK. Page 300 stays intact but differs from raw
SVG in 13.3% of pixels (mean channel delta 1.5/255). User chose to keep the
current visually exact build.

### 4. Build/release reliability — `[open]`

- Release builds still use `signingConfigs.debug`; add a real upload keystore
  via CI secrets.
- Add a PR workflow running `flutter analyze` and `flutter test`; today CI only
  builds tags.
- Add a test that decodes all 604 `.svg.vec` assets with the vector graphics
  codec, not just checks that files exist.

### 5. Runtime/UX — `[open]`

- Prefetch does both `rootBundle.load()` and invisible decoy widgets, plus
  `setState` on every page change. Consolidate into one caching path.
- Text search lowercases the whole Quran on every keystroke; precompute a
  normalized search index.
- Compiled vector pages have no error UI; add one like the PNG `errorBuilder`.
- Make wakelock optional instead of always on.
- Use the vendored surah-specific hit layers and `markers.json` for better
  highlighting on shared pages.

### 6. Maintainability — `[open]`

- `lib/screens/quran_page.dart` is ~923 lines; split data loading, preferences,
  navigation and gestures into separate files.
- Derive 604 from `quranPages` or a manifest instead of hardcoding.
- Add `mounted` guards and error states to async loaders.
- README is partly stale: the `quran.db`, `arabic_font` and azrak PNG references
  were fixed in point 2, but it still describes five menu tabs and audio
  playback that no longer exists.
- Raw SVG fixtures are 329 MB in the working tree; consider Git LFS or a
  separate artifact repo.

## Change log

- 2026-11-24: Created this handover with the size investigation and backlog.
- 2026-11-24: Point 2 done — removed `quran.db`, the `arabic_font` package and
  unused `avenir` font, vendored Avenir Arabic Regular, dropped release
  `INTERNET` permission, updated README. Analyze clean, 15/15 tests pass.
  Tagged/pushed `v1.10.0-beta`; CI APK is 331.8 MB, 7.47 MB smaller than
  `v1.9.9-beta`, and contains none of the removed assets.
