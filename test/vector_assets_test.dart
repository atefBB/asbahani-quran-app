import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_graphics_codec/vector_graphics_codec.dart';

/// Collects just enough codec output to prove a compiled page is drawable.
/// The codec owns the binary format, so a successful decode here means the
/// app's `AssetBytesLoader` path will find real paths and a real viewBox.
class _DecodeStats extends VectorGraphicsCodecListener {
  double width = 0;
  double height = 0;
  int paths = 0;
  int draws = 0;

  @override
  void onSize(double width, double height) {
    this.width = width;
    this.height = height;
  }

  @override
  void onPaintObject({
    required int color,
    required int? strokeCap,
    required int? strokeJoin,
    required int blendMode,
    required double? strokeMiterLimit,
    required double? strokeWidth,
    required int paintStyle,
    required int id,
    required int? shaderId,
  }) {}

  @override
  void onPathStart(int id, int fillType) {}

  @override
  void onPathMoveTo(double x, double y) {}

  @override
  void onPathLineTo(double x, double y) {}

  @override
  void onPathCubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {}

  @override
  void onPathClose() {}

  @override
  void onPathFinished() => paths++;

  @override
  void onDrawPath(int pathId, int? paintId, int? patternId) => draws++;

  @override
  void onDrawVertices(
    Float32List vertices,
    Uint16List? indices,
    int? paintId,
  ) {}

  @override
  void onSaveLayer(int paintId) {}

  @override
  void onClipPath(int pathId) {}

  @override
  void onRestoreLayer() {}

  @override
  void onMask() {}

  @override
  void onRadialGradient(
    double centerX,
    double centerY,
    double radius,
    double? focalX,
    double? focalY,
    Int32List colors,
    Float32List? offsets,
    Float64List? transform,
    int tileMode,
    int id,
  ) {}

  @override
  void onLinearGradient(
    double fromX,
    double fromY,
    double toX,
    double toY,
    Int32List colors,
    Float32List? offsets,
    int tileMode,
    int id,
  ) {}

  @override
  void onTextConfig(
    String text,
    String? fontFamily,
    double xAnchorMultiplier,
    int fontWeight,
    double fontSize,
    int decoration,
    int decorationStyle,
    int decorationColor,
    int id,
  ) {}

  @override
  void onDrawText(
    int textId,
    int? fillId,
    int? strokeId,
    int? patternId,
  ) {}

  @override
  void onImage(
    int imageId,
    int format,
    Uint8List data, {
    VectorGraphicsErrorListener? onError,
  }) {}

  @override
  void onDrawImage(
    int imageId,
    double x,
    double y,
    double width,
    double height,
    Float64List? transform,
  ) {}

  @override
  void onPatternStart(
    int patternId,
    double x,
    double y,
    double width,
    double height,
    Float64List transform,
  ) {}

  @override
  void onTextPosition(
    int textPositionId,
    double? x,
    double? y,
    double? dx,
    double? dy,
    bool reset,
    Float64List? transform,
  ) {}

  @override
  void onUpdateTextPosition(int textPositionId) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 604 compiled azrak pages decode with the vector graphics codec',
      () {
    const codec = VectorGraphicsCodec();

    for (var page = 1; page <= 604; page++) {
      final file = File('assets/azrak/$page.svg.vec');
      expect(file.existsSync(), isTrue,
          reason: 'missing compiled display asset for page $page');

      final stats = _DecodeStats();
      final response = codec.decode(
        ByteData.sublistView(file.readAsBytesSync()),
        stats,
      );

      expect(response.complete, isTrue,
          reason: 'page $page did not decode completely');
      expect(stats.width, greaterThan(0),
          reason: 'page $page decoded without a width');
      expect(stats.height, greaterThan(0),
          reason: 'page $page decoded without a height');
      expect(stats.paths, greaterThan(0),
          reason: 'page $page decoded without paths');
      expect(stats.draws, greaterThan(0),
          reason: 'page $page decoded without draw commands');
    }
  });
}
