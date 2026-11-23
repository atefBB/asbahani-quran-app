import 'dart:io';

import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';

/// Regenerates the display-only compiled SVG assets from the raw fixtures.
///
/// The raw SVGs live outside `assets/` so they are not bundled into the app;
/// they are kept only for the geometry parity tests in `test/`.
const String _fixtureDir = 'test/fixtures/azrak';
const String _assetDir = 'assets/azrak';

void main() {
  // PathOps is required by the masking/clipping optimizers. Do not initialize
  // the tessellator: despite producing much smaller files, tessellated output
  // rendered nearly blank in the browser parity check for page 300.
  if (!initializePathOpsFromFlutterCache()) {
    stderr.writeln('Could not initialize the PathOps native library.');
    exitCode = 1;
    return;
  }

  final fixtures = Directory(_fixtureDir);
  if (!fixtures.existsSync()) {
    stderr.writeln('Missing $_fixtureDir');
    exitCode = 1;
    return;
  }

  final output = Directory(_assetDir)..createSync(recursive: true);
  final svgs = fixtures
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.svg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final svg in svgs) {
    final name = svg.uri.pathSegments.last.replaceFirst('.svg', '.svg.vec');
    final bytes = encodeSvg(
      xml: svg.readAsStringSync(),
      debugName: svg.path,
      // The overdraw optimizer crashes on these pages with
      // "Infinity or NaN toInt"; the compiled output is pixel-identical
      // without it (verified against page 300 in the browser).
      enableOverdrawOptimizer: false,
    );
    File('${output.path}${Platform.pathSeparator}$name')
        .writeAsBytesSync(bytes, flush: true);
  }

  stdout.writeln('Compiled ${svgs.length} SVGs into $_assetDir');
}
