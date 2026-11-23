import 'dart:convert';

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

  static const String _jsonDir = 'assets/warsh_json';
  static const String _viewBoxesAsset = '$_jsonDir/viewboxes.json';
  static Map<String, Rect>? _viewBoxCache;

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

  /// Loads the ayah hit layer from the per-page JSON published alongside the
  /// Warsh/KFQC SVG pages. [viewboxes.json] keeps the exact `viewBox` used by
  /// each local SVG so screen coordinates still line up with the artwork.
  static Future<AyahPageGeometry> load(int page) =>
      loadKey(page.toString().padLeft(3, '0'));

  /// Same as [load], but accepts keys such as `106-surah4` for the
  /// surah-specific page variants shipped upstream.
  static Future<AyahPageGeometry> loadKey(String key) async {
    final viewBox = (await _viewBoxes())[key];
    if (viewBox == null) {
      throw StateError('No viewBox entry for ayah layer "$key".');
    }
    final source = await rootBundle.loadString('$_jsonDir/$key.json');
    return fromJson(source, viewBox: viewBox);
  }

  static AyahPageGeometry fromJson(String source, {required Rect viewBox}) {
    final decoded = jsonDecode(source) as List<dynamic>;
    final ayahs = <AyahGeometry>[];
    for (final entry in decoded) {
      final data = entry as Map<String, dynamic>;
      ayahs.add(AyahGeometry(
        surah: (data['surahNumber'] as num).toInt(),
        ayah: (data['ayahNumber'] as num).toInt(),
        polygons: parsePolygon(data['polygon'] as String),
      ));
    }
    return AyahPageGeometry(viewBox: viewBox, ayahs: ayahs);
  }

  /// Reads a page's `viewBox` values once, instead of parsing the full SVG.
  static Future<Map<String, Rect>> _viewBoxes() async {
    final cached = _viewBoxCache;
    if (cached != null) return cached;
    final decoded = jsonDecode(await rootBundle.loadString(_viewBoxesAsset))
        as Map<String, dynamic>;
    final result = <String, Rect>{};
    decoded.forEach((key, value) {
      final parts = value as List<dynamic>;
      result[key] = Rect.fromLTWH(
        (parts[0] as num).toDouble(),
        (parts[1] as num).toDouble(),
        (parts[2] as num).toDouble(),
        (parts[3] as num).toDouble(),
      );
    });
    return _viewBoxCache = result;
  }

  /// Legacy SVG parser, kept so tests can verify that the JSON layer and the
  /// polygons embedded in the SVGs stay identical.
  static AyahPageGeometry parse(String svg) {
    final vbMatch = RegExp(r'viewBox="([-0-9.eE ]+)"').firstMatch(svg);
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
        polygons: parsePolygon(d),
      ));
    }
    return AyahPageGeometry(viewBox: viewBox, ayahs: ayahs);
  }

  /// Upstream JSON uses two polygon encodings: `M/L/Z` paths, and bare
  /// `x,y x,y ...` point lists on the first two pages.
  static List<List<Offset>> parsePolygon(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const <List<Offset>>[];
    if (trimmed.startsWith('M')) return _parsePath(trimmed);
    return <List<Offset>>[_parseCoordinatePairs(trimmed)];
  }

  static List<Offset> _parseCoordinatePairs(String value) {
    return RegExp(r'(-?\d+(?:\.\d+)?)[,\s]+(-?\d+(?:\.\d+)?)')
        .allMatches(value)
        .map((m) => Offset(
              double.parse(m.group(1)!),
              double.parse(m.group(2)!),
            ))
        .toList();
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