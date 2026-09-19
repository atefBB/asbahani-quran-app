import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Geometry of a single ayah on a page: one or more polygons (subpaths)
/// describing the visible/clickable area of that ayah.
class AyahGeometry {
  final int surah;
  final int ayah;
  List<List<Offset>> polygons;

  AyahGeometry({
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
    _applySurahStartRepair(ayahs);
    return AyahPageGeometry(viewBox: viewBox, ayahs: ayahs);
  }

  /// The azrak SVG data chops the first ayah of a surah-start page down to
  /// just the right part of its first line and gives the leftover of that line
  /// (and the rows below) to the following ayah. This repair gives the first
  /// ayah the whole top line and removes that split segment from the next
  /// ayah, so long-pressing anywhere on the first line of such a page
  /// bookmarks/highlights the first ayah correctly.
  static void _applySurahStartRepair(List<AyahGeometry> ayahs) {
    if (ayahs.length < 2) return;
    final first = ayahs[0];
    final second = ayahs[1];

    double minX = double.infinity, maxX = -double.infinity;
    for (final a in ayahs) {
      for (final p in a.polygons) {
        for (final o in p) {
          if (o.dx < minX) minX = o.dx;
          if (o.dx > maxX) maxX = o.dx;
        }
      }
    }
    final fullWidth = maxX - minX;
    if (fullWidth <= 0) return;

    final firstTopY = _minRowTop(first);
    double fmin = double.infinity, fmax = -double.infinity;
    for (final p in first.polygons) {
      if (!_onRow(p, firstTopY)) continue;
      for (final o in p) {
        if (o.dx < fmin) fmin = o.dx;
        if (o.dx > fmax) fmax = o.dx;
      }
    }
    if (fmax - fmin >= 0.9 * fullWidth) return; // first ayah is already full-width

    final secondRowTops = <double>{};
    for (final p in second.polygons) {
      var top = double.infinity;
      for (final o in p) {
        if (o.dy < top) top = o.dy;
      }
      secondRowTops.add(top);
    }
    if (secondRowTops.length < 2) return; // short-ayah pages must stay untouched
    final secondTopY = secondRowTops.reduce(math.min);
    if ((secondTopY - firstTopY).abs() > 1e-6) return; // doesn't share the top row

    final topRowBottom = second.polygons
        .where((p) => _onRow(p, secondTopY))
        .expand((p) => p)
        .map((o) => o.dy)
        .where((y) => y - secondTopY > 1e-6)
        .reduce(math.min);

    first.polygons.add([
      Offset(minX, firstTopY),
      Offset(maxX, firstTopY),
      Offset(maxX, topRowBottom),
      Offset(minX, topRowBottom),
    ]);

    second.polygons =
        second.polygons.where((p) => !_onRow(p, secondTopY)).toList();
  }

  static bool _onRow(List<Offset> polygon, double rowTop) =>
      polygon.any((o) => (o.dy - rowTop).abs() < 1e-6);

  static double _minRowTop(AyahGeometry ayah) {
    var top = double.infinity;
    for (final p in ayah.polygons) {
      for (final o in p) {
        if (o.dy < top) top = o.dy;
      }
    }
    return top;
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

/// Rounds every corner of a polygon by replacing each vertex with a smooth
/// quadratic fillet of [radius] px, giving a "border-radius" look on the
/// irregular ayah shapes.
Path roundedPolygonPath(List<Offset> pts, double radius) {
  final path = Path();
  final n = pts.length;
  if (n < 3 || radius <= 0) {
    path.addPolygon(pts, true);
    return path;
  }

  Offset unitIn(int i) {
    final prev = pts[(i - 1 + n) % n];
    final cur = pts[i];
    final d = (cur - prev).distance;
    return d <= 0 ? Offset.zero : (cur - prev) / d;
  }

  Offset unitOut(int i) {
    final cur = pts[i];
    final next = pts[(i + 1) % n];
    final d = (next - cur).distance;
    return d <= 0 ? Offset.zero : (next - cur) / d;
  }

  final startPoints = <Offset>[];
  final endPoints = <Offset>[];
  for (var i = 0; i < n; i++) {
    final inLen = (pts[i] - pts[(i - 1 + n) % n]).distance;
    final outLen = (pts[(i + 1) % n] - pts[i]).distance;
    final r = radius.clamp(0.0, inLen / 2).clamp(0.0, outLen / 2);
    startPoints.add(pts[i] - unitIn(i) * r);
    endPoints.add(pts[i] + unitOut(i) * r);
  }

  path.moveTo(startPoints[0].dx, startPoints[0].dy);
  for (var i = 0; i < n; i++) {
    path.lineTo(endPoints[i].dx, endPoints[i].dy);
    final next = (i + 1) % n;
    path.quadraticBezierTo(
      pts[next].dx,
      pts[next].dy,
      startPoints[next].dx,
      startPoints[next].dy,
    );
  }
  path.close();
  return path;
}

/// Fill + (border-free) rounded overlay used to highlight a bookmarked ayah.
class AyahHighlightPainter extends CustomPainter {
  final AyahPageGeometry geometry;
  final int surah;
  final int ayah;
  final double cornerRadius;

  const AyahHighlightPainter({
    required this.geometry,
    required this.surah,
    required this.ayah,
    this.cornerRadius = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ayahGeo = geometry.findAyah(surah, ayah);
    if (ayahGeo == null || size.width <= 0 || size.height <= 0) return;
    final paint = Paint()
      ..color = const Color(0x40FBC02D)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final polygon in ayahGeo.polygons) {
      final screen = polygon
          .map((p) => Offset(
                (p.dx - geometry.viewBox.left) / geometry.viewBox.width *
                    size.width,
                (p.dy - geometry.viewBox.top) / geometry.viewBox.height *
                    size.height,
              ))
          .toList();
      canvas.drawPath(Path()..addPolygon(screen, true), paint);
    }
  }

  @override
  bool shouldRepaint(AyahHighlightPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.surah != surah ||
      oldDelegate.ayah != ayah ||
      oldDelegate.cornerRadius != cornerRadius;
}