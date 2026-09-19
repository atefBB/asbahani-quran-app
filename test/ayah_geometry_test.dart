import 'package:flutter/services.dart';
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

  test('surah-start pages give the first ayah its full top line', () async {
    for (final page in [77, 282]) {
      final g = await AyahPageGeometry.load(page);
      // the first ayah of the page now spans the full page text width
      final first = g.findAt(170, 174); // middle of the first text line
      expect(first, isNotNull, reason: 'page $page top-line press should hit');
      final hitFirst = first!;
      expect(hitFirst.surah, g.ayahs.first.surah);
      expect(hitFirst.ayah, g.ayahs.first.ayah);
    }
  });

  test('surah-start repair keeps short-ayah rows intact (page 604)', () async {
    final g = await AyahPageGeometry.load(604);
    // Al-Ikhlas: 3 short ayahs share one line; pressing the middle part must
    // still resolve to ayah 2, not ayah 1.
    final ayah2 = g.findAt(172, 104);
    expect(ayah2, isNotNull);
    final hit = ayah2!;
    expect(hit.surah, 112);
    expect(hit.ayah, 2);
  });
}