# Handover

Living document for the `svg-pages` branch. Update it whenever a backlog item
starts or finishes.

## Current state

- Branch: `svg-pages`
- Latest tag: `v1.13.1-beta` (this commit) — the first release built with the
  CI upload keystore.
- Latest release APK: CI builds each pushed tag; the last size recorded here is
  **332.3 MB / 317 MiB** (`v1.11.1-beta`), up ~0.47 MB from 331.8 MB at
  `v1.10.0-beta` after adding `share_plus` + `file_picker`.
- `flutter analyze`: clean
- `flutter test`: 30/30 passing

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

### 4. Build/release reliability — `[done]`

- `[done]` Release builds now use a real upload keystore instead of
  `signingConfigs.debug`. The tag workflow decodes `KEYSTORE_BASE64` into
  `android/app/upload-keystore.jks` and writes `android/key.properties` from
  `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD`; the workflow stops with
  a named list if any secret is missing, and Gradle then signs with that key.
  Local builds without `key.properties` still use the debug key so
  `flutter run --release` works.
  **Action needed: add those four secrets in GitHub repo settings before the
  next tag build.**
- `[done]` `.github/workflows/flutter-check.yml` runs `flutter analyze` and
  `flutter test` on every pull request (and on demand), with the same Flutter
  version as the release workflow.
- `[done]` `test/vector_assets_test.dart` decodes all 604 compiled pages with
  `VectorGraphicsCodec`, asserting a complete decode, a non-zero viewBox, paths
  and draw commands. `vector_graphics_codec` is pinned as a dev dependency to
  match the transitive version used by `vector_graphics`.

### 5. Runtime/UX — `[in progress]`

- `[done]` Prefetch now has one path per page type: `PagePrefetchController`
  uses Flutter's image cache for PNG pages and an invisible `VectorGraphic`
  decoy (outside the `PageView`) for compiled pages. Page changes notify only
  `PagePrefetchOverlay`, not `QuranPage`; the redundant `rootBundle.load()`
  and per-page `setState` are gone.
- `[done]` `AyahSearchIndex` normalizes ayah text once at load time instead of
  on every keystroke, and matches diacritics/alef variants like the menu.
- `[done]` Compiled vector pages now use the same 'فشل تحميل الصفحة' error
  placeholder as PNG pages.
- `[done]` Wakelock defaults on but can be turned off from the settings row in
  the last menu tab (`AppPreferences.keepAwake`); startup and the toggle share
  the same preference and ignore unsupported platforms.
- `[open]` Use the vendored surah-specific hit layers and `markers.json` for
  better highlighting on shared pages. The `NNN-surahX.json` polygons use
  different viewBoxes (surah-only layouts), not crops of the bundled full
  pages, so wiring them into the current highlight overlay would misalign;
  needs a product decision on whether to render surah-specific page variants.

### 6. Maintainability — `[open]`

- `lib/screens/quran_page.dart` is ~1190 lines; split data loading, preferences,
  navigation and gestures into separate files.
- Derive 604 from `quranPages` or a manifest instead of hardcoding.
- `[partly done]` Add `mounted` guards and error states to async loaders: guards
  added to the data loaders, startup callback and way switch; error states still
  open.
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
- 2026-11-24: Added bookmark export/import in the bookmark tab. Export shares a
  JSON file with both page and ayah bookmarks (`lib/data/bookmark_transfer.dart`);
  import picks a `.json` file and merges, deduplicating and keeping existing
  bookmarks. Added `share_plus` + `file_picker`, 7 transfer tests, and a
  notifier so the open bottom sheet refreshes after import. Analyze clean,
  22/22 tests and web release build pass.
- 2026-11-24: `v1.11.0-beta` CI build failed: `share_plus 12.0.2` ships Kotlin
  2.2 metadata, which the project's KGP 1.9.24 could not compile. Bumped
  `org.jetbrains.kotlin.android` to 2.2.20 in `android/settings.gradle`;
  `v1.11.1-beta` built and published successfully (332.3 MB APK). The
  `v1.11.0-beta` tag exists but has no release — use `v1.11.1-beta`.
- 2026-11-25: `v1.11.2-beta` moved the page number and RTL side marker into the
  header; `v1.12.0-beta` restored the tappable page number to the footer and
  added edge-swipe focus mode. This handover lagged behind those tags until the
  2026-11-26 pass.
- 2026-11-26: Runtime/UX pass on `svg-pages`: unified page prefetch behind
  `PagePrefetchController`/`PagePrefetchOverlay`, added a precomputed
  `AyahSearchIndex`, added a vector-page error placeholder, and made the
  wakelock a reader setting (on by default) in the last menu tab. Added
  `mounted` guards to the async loaders and refreshed the deprecated
  `Share.shareXFiles` call. `flutter analyze` clean, 29/29 tests pass.
  Tagged/pushed `v1.13.0-beta`.
- 2026-11-26: Build/release reliability: added a PR workflow for `flutter
  analyze` + `flutter test`, a `VectorGraphicsCodec` test that decodes all 604
  compiled pages, and real upload-key signing in CI through four repository
  secrets (debug key retained for local builds). `flutter analyze` clean,
  30/30 tests pass. Tagged/pushed `v1.13.1-beta` after the four CI signing
  secrets were configured.
