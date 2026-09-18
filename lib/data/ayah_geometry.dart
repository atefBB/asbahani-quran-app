import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Geometry of a single ayah on a page: one or more polygons (subpaths)
/// describing the visible/clickable area of that ayah.
class AyahGeometry {
  final int surah;
  final int ayah;
  final List<List<Offset>> polygons;

  const AyahGeometry({
    required this.surah,
    required this.ayah,
    required this.polygons,
  });

  bool contains(double x, double y) {
    for (final polygon in polygons) {
      if (_pointInPolygon(x, y, polygon)) {
        return true;
      }
    }
    return false;
  }

  static bool _pointInPolygon(double x, double y, List<Offset> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;
      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }
}

/// Parsed ayah-hitting geometry for one page.
class AyahPageGeometry {
  final Rect viewBox;
  final List<AyahGeometry> ayahs;

  const AyahPageGeometry({required this.viewBox, required this.ayahs});

  AyahGeometry? findAt(double x, double y) {
    for (final ayah in ayahs) {
      if (ayah.contains(x, y)) {
        return ayah;
      }
    }
    return null;
  }

  AyahGeometry? findAyah(int surah, int ayah) {
    for (final a in ayahs) {
      if (a.surah == surah && a.ayah == ayah) {
        return a;
      }
    }
    return null;
  }

  static Future<AyahPageGeometry> load(int page) async {
    final svg = await rootBundle.loadString('assets/azrak/$page.svg');
    return parse(svg);
  }

  static AyahPageGeometry parse(String svg) {
    final vbMatch = RegExp(r'viewBox="([-0-9. ]+)"').firstMatch(svg);
    final vbParts = vbMatch!.group(1)!.trim().split(RegExp(r'\s+')).map(double.parse).toList();
    final viewBox =
        Rect.fromLTWH(vbParts[0], vbParts[1], vbParts[2], vbParts[3]);

    final ayahs = <AyahGeometry>[];
    final polyReg = RegExp(r'<path\s+class="ayahPolygon"[^>]*?/?>');
    for (final m in polyReg.allMatches(svg)) {
      final tag = m.group(0)!;
      final surah = int.parse(RegExp(r'surah="(\d+)"').firstMatch(tag)!.group(1)!);
      final ayah = int.parse(RegExp(r'ayah="(\d+)"').firstMatch(tag)!.group(1)!);
      final d = RegExp(r'\sd="([^"]*)"').firstMatch(tag)!.group(1)!;
      ayahs.add(AyahGeometry(
        surah: surah,
        ayah: ayah,
        polygons: _parsePath(d),
      ));
    }
    return AyahPageGeometry(viewBox: viewBox, ayahs: ayahs);
  }

  static List<List<Offset>> _parsePath(String d) {
    final tokens = RegExp(r'[MLZ]|[-+]?[0-9]*\.?[0-9]+')
        .allMatches(d)
        .map((m) => m.group(0)!)
        .toList();

    final polygons = <List<Offset>>[];
    List<Offset>? current;
    int idx = 0;
    while (idx < tokens.length) {
      final t = tokens[idx];
      if (t == 'M' || t == 'L') {
        idx++;
        if (idx + 1 >= tokens.length) break;
        final x = double.parse(tokens[idx]);
        final y = double.parse(tokens[idx + 1]);
        idx += 2;
        if (t == 'M') {
          if (current != null && current.isNotEmpty) {
            polygons.add(current);
          }
          current = [Offset(x, y)];
        } else {
          current?.add(Offset(x, y));
        }
      } else if (t == 'Z') {
        idx++;
        if (current != null && current.isNotEmpty) {
          polygons.add(current);
        }
        current = null;
      } else {
        idx++;
      }
    }
    if (current != null && current.isNotEmpty) {
      polygons.add(current);
    }
    return polygons;
  }

  /// Screen-space [Path] of the given ayah, mapping the viewBox onto [size]
  /// the same way `BoxFit.fill` renders the SVG.
  Path pathFor(int surah, int ayah, Size size) {
    final path = Path();
    final ayahGeo = findAyah(surah, ayah);
    if (ayahGeo == null || size.width <= 0 || size.height <= 0) {
      return path;
    }
    for (final polygon in ayahGeo.polygons) {
      path.addPolygon(
        polygon
            .map((p) => Offset(
                  (p.dx - viewBox.left) / viewBox.width * size.width,
                  (p.dy - viewBox.top) / viewBox.height * size.height,
                ))
            .toList(),
        true,
      );
    }
    return path;
  }
}

/// Fill + outline overlay used to highlight a bookmarked ayah on the page.
class AyahHighlightPainter extends CustomPainter {
  final AyahPageGeometry geometry;
  final int surah;
  final int ayah;

  const AyahHighlightPainter({
    required this.geometry,
    required this.surah,
    required this.ayah,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = geometry.pathFor(surah, ayah, size);
    if (path.computeMetrics().isEmpty) return;
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x40FBC02D) // translucent amber fill
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xCCF9A825)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(AyahHighlightPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.surah != surah ||
      oldDelegate.ayah != ayah;
}