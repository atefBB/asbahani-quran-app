import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:asbahani/data/ayah_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses real azrak page geometry and hit-tests', () async {
    for (final page in [1, 2, 10, 100, 300, 604]) {
      final g = await AyahPageGeometry.load(page);
      expect(g.ayahs, isNotEmpty, reason: 'page $page should have ayahs');
      expect(g.viewBox.width, greaterThan(0));
      expect(g.viewBox.height, greaterThan(0));
      for (final a in g.ayahs) {
        expect(a.polygons, isNotEmpty);
        for (final p in a.polygons) {
          expect(p.length, greaterThanOrEqualTo(3));
        }
      }
    }
  });

  test('JSON hit layer matches the polygons embedded in the SVGs', () async {
    // The hit layer comes from `assets/warsh_json`; the raw SVGs are kept as
    // test fixtures while the app bundles only their compiled .svg.vec files.
    // Their polygons must still agree.
    for (final page in [1, 2, 3, 15, 106, 300, 604]) {
      final fromJson = await AyahPageGeometry.load(page);
      final svg = await File('test/fixtures/azrak/$page.svg').readAsString();
      final fromSvg = AyahPageGeometry.parse(svg);

      expect(fromJson.viewBox, fromSvg.viewBox,
          reason: 'viewBox for page $page must match the rendered SVG');
      expect(fromJson.ayahs.length, fromSvg.ayahs.length,
          reason: 'ayah count for page $page');

      for (var i = 0; i < fromJson.ayahs.length; i++) {
        final a = fromJson.ayahs[i];
        final b = fromSvg.ayahs[i];
        expect(a.surah, b.surah, reason: 'page $page ayah #$i surah');
        expect(a.ayah, b.ayah, reason: 'page $page ayah #$i ayah');
        expect(a.polygons, equals(b.polygons),
            reason: 'page $page ayah #$i polygons');
      }
    }
  });

  test('all compiled azrak display assets are present', () {
    for (var page = 1; page <= 604; page++) {
      final asset = File('assets/azrak/$page.svg.vec');
      expect(asset.existsSync(), isTrue,
          reason: 'missing compiled display asset for page $page');
      expect(asset.lengthSync(), greaterThan(0),
          reason: 'empty compiled display asset for page $page');
    }
  });

  test('loads surah-specific hit layers', () async {
    final g = await AyahPageGeometry.loadKey('106-surah4');
    expect(g.ayahs, isNotEmpty);
    expect(g.ayahs.first.surah, 4);
    expect(g.viewBox.height, lessThan(550));
  });

  test('parses both upstream polygon encodings', () {
    final pairs = AyahPageGeometry.parsePolygon('1,2 3,4 5,6');
    expect(pairs, hasLength(1));
    expect(pairs.single, equals(const [Offset(1, 2), Offset(3, 4), Offset(5, 6)]));

    final path = AyahPageGeometry.parsePolygon('M 0 0 L 1 0 L 1 1 Z');
    expect(path, hasLength(1));
    expect(path.single, equals(const [Offset(0, 0), Offset(1, 0), Offset(1, 1)]));
  });

  test('findAt returns first ayah polygon for page 1', () async {
    final g = await AyahPageGeometry.load(1);
    final ayah = g.findAt(g.viewBox.center.dx, g.viewBox.center.dy);
    expect(ayah, isNotNull);
    expect(ayah!.surah, 1);
  });

  test('findAt returns null below the ayah bands', () async {
    final g = await AyahPageGeometry.load(1);
    final ayah = g.findAt(g.viewBox.center.dx, g.viewBox.bottom);
    // bottom edge of page 1 has no ayah polygon areas in the sample
    expect(ayah, isNull);
  });

  test('pathFor maps an ayah to screen space for highlight overlay', () async {
    final g = await AyahPageGeometry.load(1);
    final path = g.pathFor(1, 1, const Size(400, 600));
    expect(path.computeMetrics().isNotEmpty, isTrue);
    final empty = g.pathFor(999, 999, const Size(400, 600));
    expect(empty.computeMetrics().isEmpty, isTrue);
  });

  test('roundedPolygonPath cuts each square corner', () {
    const square = [
      Offset(0, 0),
      Offset(100, 0),
      Offset(100, 100),
      Offset(0, 100),
    ];
    final rounded = roundedPolygonPath(square, 10);
    expect(rounded.computeMetrics().isNotEmpty, isTrue);
    // The corner point must be cut away by the fillet...
    expect(rounded.contains(const Offset(0, 0)), isFalse);
    // ...while the center of the band must stay covered.
    expect(rounded.contains(const Offset(50, 50)), isTrue);
    // Without rounding, the unmodified polygon still covers the corner.
    expect(
        roundedPolygonPath(square, 0).contains(const Offset(0, 0)), isTrue);
  });
}