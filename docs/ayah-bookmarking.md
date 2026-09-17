# آيات الأزرق — وضع إشارة آية بالضغط المطوّل

Feature: long-press an ayah on an azrak (Warsh `an-al-Azraq`) page to
bookmark that specific ayah, and manage those ayah bookmarks from the
bookmarks tab in the bottom sheet menu.

## Why pages carry hit areas

The azrak pages in `assets/azrak/*.svg` are **not** full-page renderings of
the mushaf page. Each file contains only:

- one invisible `<path class="ayahPolygon">` per ayah, whose `d` attribute
  describes the on-page area (usually several rectangles) occupied by that
  ayah, and
- a decorative `ayah_markers` group (medallions) that is *not* used for
  hit-testing.

This means every tap / long-press target is defined purely by geometry. Those
polygons are the source of truth for "which ayah is under this point".

### SVG structure (verified on the real files)

```xml
<svg viewBox="0.854 -2.938 235 235" ...>
  <path class="ayahPolygon" fill-opacity="0" id="verse-18709"
        number="001001" ayah="1" surah="1"
        d="M 213 38 L 66 38 L 66 70 L 213 70 Z" />
  ...
  <g transform="matrix(1.3333 0 0 -1.3333 -55 640)">  <!-- ayah_markers -->
  </g>
</svg>
```

- `ayahPolygon` paths are **direct children of the `<svg>` root**, so they
  live in the same coordinate space as `viewBox` (the matrix transform only
  applies to the `ayah_markers` group).
- The `d` attribute uses only the commands `M`, `L`, `Z` (closed polygons);
  multiple subpaths in one `d` are supported.
- `number` encodes the surah (3 digits) followed by the ayah (3 digits),
  e.g. `001001` = surah 1, ayah 1.
- `viewBox` varies per file (e.g. `0.854 -2.938 235 235` for page 1,
  `-6 0 345 550` for others) because of the SVG re-centering done in
  `v1.8.2-beta`. Geometry must always be read from the file at runtime,
  never hard-coded.

## Coordinate mapping (screen → SVG space)

An SVG is rendered with `BoxFit.fill` inside a widget box of size
`(w, h)`. Mapping a long-press position local to that box back to SVG
space, given the page's `viewBox` `(vx, vy, vw, vh)`:

```
svgX = vx + localDx / (w / vw)
svgY = vy + localDy / (h / vh)
```

`AyahPageGeometry.findAt(svgX, svgY)` then runs a point-in-polygon test
(ray casting) over every subpath of every ayah on the page.

## Files

- `lib/data/ayah_geometry.dart` — the parser & hit-tester.
  - `AyahPageGeometry.parse(svg)` — reads `viewBox` + every `ayahPolygon`
    path, tokenizes `d`, and builds `AyahGeometry` objects (list of
    `Offset` polygons).
  - `AyahPageGeometry.load(page)` — async-loads `assets/azrak/<page>.svg`
    via `rootBundle`.
  - `AyahGeometry.contains(x, y)` — point-in-polygon (ray casting) over all
    subpaths.
  - `AyahPageGeometry.findAt(x, y)` — first matching ayah, or `null`.
- `lib/screens/quran_page.dart` — integration.
  - `_imageWidget(...)` wraps the SVG with a `GestureDetector` that fires
    `onLongPressStart` (only for SVG / azrak pages; PNG asbahani pages skip
    the handler because they carry no polygons).
  - `_handleAyahLongPress(page, localPosition, size)` — maps the position
    and toggles the bookmark.
  - `_toggleAyahBookmark(surah, ayah)` — persists and shows a snack bar.
  - `_bookmarksTab(...)` — lists page bookmarks and ayah bookmarks.

## Storage

Ayah bookmarks are stored separately from page bookmarks, using a new
SharedPreferences key:

| Key            | Value                                        | Owner                |
|----------------|----------------------------------------------|----------------------|
| `bookmarks`    | `List<String>` of page numbers               | existing page feature|
| `ayahBookmarks`| `List<String>` of `"surah:ayah"` (e.g. `2:24`)| this feature        |

Ayah bookmarks are loaded in `_loadBookmarks()` and jump to the correct page
via `_pageOfAyah(surah, ayah)` which scans `assets/quran-pages-index.json`
(and falls back to `assets/quran.json`).

## Geometry caching

Parsed per-page geometry is cached in `_ayahGeometryCache` (a
`Map<int, AyahPageGeometry>`) so the first long-press on a page pays the
parse cost and later presses reuse it. The cache is per session and never
persisted.

## UX

- Long-press anywhere on an azrak page: if the point falls inside an ayah
  polygon, the ayah reference is saved (or removed if already saved) and a
  snack bar confirms the action. Short taps still open the menu; the two
  gestures do not conflict (tap vs. long-press arena).
- Long-press on spaces with no ayah polygon does nothing.
- In the asbahani way there are no polygons, so long-press is a no-op.

## Tests

`test/ayah_geometry_test.dart` verifies parsing and hit-testing against the
real `assets/azrak/*.svg` files (pages 1, 2, 10, 100, 300, 604).

## Limits / future work

- No visual highlight of bookmarked ayahs on the page yet; the only feedback
  is the snack bar.
- `assets/quran.json` (search, fallback) may use a different page layout than
  the azrak mushaf; page-jump from an ayah bookmark relies on the Warsh
  `quran-pages-index.json` mapping first, which matches the azrak pages.