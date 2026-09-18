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
}