# Warsh/KFQC ayah hit layers

Vendored from
`https://github.com/AhmedAbuelenin/quran-svg-with-aya-clickable-layer/tree/main/mushafs/warsh/kfqc/json`
at pinned commit `0198423eb867ba26051aba6ac902cd5d10aadd1b`.

That commit is important: older revisions have `surahNumber: 0` / `ayahNumber: 0`
in most per-page JSON files.

- `001.json` … `604.json` — ayah polygons for the 604 base pages.
- `NNN-surahX.json` — surah-specific page variants (54 shared pages).
- `surah.json`, `markers.json` — surah index and medallion centres (not yet used).
- `viewboxes.json` — generated locally from `assets/azrak/*.svg` and the upstream
  variant SVGs; keeps the exact viewBox each page is rendered with.

Polygon/metadata contribution is CC0 1.0 upstream; KFQC page artwork is free
for digital use. See upstream `NOTICE.md` for full terms.
