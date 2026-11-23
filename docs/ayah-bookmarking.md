# آيات الأزرق — وضع إشارة آية بالضغط المطوّل

Long-press an ayah on an azrak (Warsh `an-Nafi'`) page to bookmark that
specific ayah, and manage those ayah bookmarks from the bookmarks tab in the
bottom sheet menu.

## Where the hit layer comes from

The azrak pages in `assets/azrak/*.svg` are full vector renderings of the
Warsh/KFQC mushaf page. Transparent `<path class="ayahPolygon" ...>` elements
at the start of each SVG define the clickable area of every ayah; the glyphs
are rendered on top of them.

The same polygons are also published as compact per-page JSON by
[quran-svg-with-aya-clickable-layer](https://github.com/AhmedAbuelenin/quran-svg-with-aya-clickable-layer),
in `mushafs/warsh/kfqc/json/`. We vendor that JSON in `assets/warsh_json/` and
use it as the source of truth for hit-testing. Parsing a 1–3 KB JSON file is
much cheaper than regex-parsing a 300–600 KB SVG.

Pinned upstream commit: `0198423eb867ba26051aba6ac902cd5d10aadd1b`
("Fix ayah identity and complete polygon coverage in per-page data"). Earlier
commits have `surahNumber: 0, ayahNumber: 0` in most page JSON files — do not
downgrade below this commit.

The polygons themselves are CC0; the KFQC page artwork is free for digital
use. See upstream `NOTICE.md` for full terms.

### JSON structure

```json
[
  {
    "surahNumber": 2,
    "ayahNumber": 5,
    "x": 258.69,
    "y": 65.39,
    "polygon": "M 0.0 5.75 L 345.0 5.75 L 345.0 44.57 L 0.0 44.57 Z ..."
  }
]
```

`polygon` uses two encodings upstream: `M/L/Z` paths on most pages, and bare
`x,y x,y ...` point lists on pages 1 and 2. `AyahPageGeometry.parsePolygon`
handles both. `x`/`y` are medallion centres (currently unused for hit-testing).

### ViewBox mapping

The JSON polygons use the SVG's native coordinate space, so screen mapping
still needs the page's `viewBox`. Instead of reading it from the full SVG, we
store the exact values of the local SVGs in `assets/warsh_json/viewboxes.json`
(`{ "001": [left, top, width, height], ... }`). This preserves the small
per-page re-centering already applied to `assets/azrak/*.svg`.

With `BoxFit.fill` in a box of size `(w, h)` and viewBox `(vx, vy, vw, vh)`:

```
svgX = vx + localDx / (w / vw)
svgY = vy + localDy / (h / vh)
```

`AyahPageGeometry.findAt(svgX, svgY)` then runs a ray-casting point-in-polygon
test over every subpath of every ayah on the page.

## Files

- `lib/data/ayah_geometry.dart`
  - `AyahPageGeometry.load(page)` / `loadKey(key)` — load JSON + viewBox.
  - `AyahPageGeometry.fromJson(...)` — build `AyahGeometry` objects.
  - `AyahPageGeometry.parse(svg)` — legacy SVG parser, kept for parity tests.
  - `AyahPageGeometry.parsePolygon(...)` — handles both upstream encodings.
  - `AyahGeometry.contains` / `findAt` — point-in-polygon hit-testing.
  - `pathFor` / `AyahHighlightPainter` — screen-space highlight overlay.
- `lib/screens/quran_page.dart`
  - `_imageWidget(...)` wraps the SVG with a `GestureDetector` that fires
    `onLongPressStart` (only for SVG / azrak pages; PNG asbahani pages skip
    the handler because they carry no matching polygons).
  - `_handleAyahLongPress(page, localPosition, size)` — maps the position and
    toggles the bookmark.
  - `_toggleAyahBookmark(surah, ayah)` — persists and shows a snack bar.
  - `_bookmarksTab(...)` — lists page bookmarks and ayah bookmarks.

## Storage

Ayah bookmarks use a separate SharedPreferences key:

| Key            | Value                                        | Owner                |
|----------------|----------------------------------------------|----------------------|
| `bookmarks`    | `List<String>` of page numbers               | existing page feature|
| `ayahBookmarks`| `List<String>` of `"surah:ayah"` (e.g. `2:24`)| this feature        |

`_loadBookmarks()` restores them and `_pageOfAyah(surah, ayah)` resolves the
page via `assets/quran-pages-index.json`, falling back to `assets/quran.json`.

## Geometry caching

Parsed geometry is cached in `_ayahGeometryCache` (a
`Map<int, AyahPageGeometry>`) in `quran_page.dart`, and the viewBox map is
cached statically in `AyahPageGeometry`. `_prefetchPage` also warms the JSON
hit layer for neighbouring pages. Both caches are per-session only.

## UX

- Long-press anywhere on an azrak page: if the point falls inside an ayah
  polygon, the ayah reference is saved (or removed if already saved), a snack
  bar confirms the action, and the ayah is highlighted.
- Short taps still open the menu; tap vs. long-press do not conflict.
- Long-press on spaces with no ayah polygon does nothing.
- In the asbahani way there are no matching polygons, so long-press is a no-op.

## Tests

`test/ayah_geometry_test.dart` verifies that the vendored JSON produces the
same ayah identities, polygons and viewBox as the real SVGs on pages
1, 2, 3, 15, 106 and 604, in addition to the hit-test and highlight tests.

## Future work

- Use `assets/warsh_json/markers.json` for medallion-centred highlights.
- Add the 118 upstream `NNN-surahX.json` / SVG variants (54 pages) so jumping
  to a surah on a shared page can crop to that surah.
- Add Hafs/KFQC polygons if verse taps are wanted on the Asbahani PNG pages.
