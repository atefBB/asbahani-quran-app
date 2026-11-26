import 'package:flutter_test/flutter_test.dart';

import 'package:asbahani/data/page_prefetch.dart';

void main() {
  test('prefetches the bounded neighbours of the open page', () {
    final controller = PagePrefetchController();
    addTearDown(controller.dispose);

    controller.update(1, azrak: true);
    expect(controller.neighbors, [2]);

    controller.update(300, azrak: true);
    expect(controller.neighbors, [299, 301]);

    controller.update(604, azrak: true);
    expect(controller.neighbors, [603]);
  });

  test('page changes are announced to the overlay only', () {
    final controller = PagePrefetchController();
    addTearDown(controller.dispose);

    final targets = <({int page, bool azrak})>[];
    controller.target.addListener(() => targets.add(controller.target.value));

    controller.update(10, azrak: false);
    controller.update(10, azrak: true);
    controller.update(11, azrak: true);

    expect(targets, [
      (page: 10, azrak: false),
      (page: 10, azrak: true),
      (page: 11, azrak: true),
    ]);
  });
}
