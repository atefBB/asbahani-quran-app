import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

/// Warms the pages next to the one being read.
///
/// There is one cache path per page type: Flutter's image cache for the PNG
/// mushaf, and vector_graphics' decoded-picture cache for the compiled Warsh
/// pages. The latter is populated by mounting a tiny invisible [VectorGraphic]
/// with the same loader used by the real page, so the picture decoded here is
/// the one the next page displays.
///
/// Page changes only notify listeners here; they never rebuild QuranPage.
class PagePrefetchController {
  PagePrefetchController({this.totalPages = 604});

  final int totalPages;
  final ValueNotifier<({int page, bool azrak})> _target =
      ValueNotifier((page: 0, azrak: false));

  ValueListenable<({int page, bool azrak})> get target => _target;

  List<int> get neighbors {
    final page = _target.value.page;
    return <int>[
      if (page > 1) page - 1,
      if (page < totalPages) page + 1,
    ];
  }

  void update(
    int page, {
    required bool azrak,
    BuildContext? context,
  }) {
    final next = (page: page, azrak: azrak);
    if (next == _target.value) return;
    _target.value = next;

    if (!azrak && context != null) {
      for (final neighbor in neighbors) {
        precacheImage(
          AssetImage('assets/quran_pages/$neighbor.png'),
          context,
        );
      }
    }
  }

  void dispose() => _target.dispose();
}

/// Mounts the vector prefetch decoys outside the PageView so a page change
/// only rebuilds this small widget.
class PagePrefetchOverlay extends StatelessWidget {
  const PagePrefetchOverlay({
    super.key,
    required this.controller,
  });

  final PagePrefetchController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<({int page, bool azrak})>(
      valueListenable: controller.target,
      builder: (context, target, _) {
        if (!target.azrak) return const SizedBox.shrink();
        return IgnorePointer(
          child: SizedBox(
            width: 1,
            height: 1,
            child: Opacity(
              opacity: 0,
              child: Stack(
                children: [
                  for (final page in controller.neighbors)
                    createCompatVectorGraphic(
                      loader: AssetBytesLoader('assets/azrak/$page.svg.vec'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
