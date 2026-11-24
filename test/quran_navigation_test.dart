import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asbahani/data/quran_navigation.dart';
import 'package:asbahani/screens/quran_menu_tab.dart';

void main() {
  final chapters = <dynamic>[
    <String, dynamic>{'id': 1, 'name_ar': 'سُورَةُ الفَاتِحَةِ', 'page': 1},
    <String, dynamic>{'id': 2, 'name_ar': 'سُورَةُ البَقَرَةِ', 'page': 2},
    <String, dynamic>{'id': 3, 'name_ar': 'سُورَةُ آلِ عِمرَانَ', 'page': 50},
  ];

  test('normalizes Arabic text and digits for search', () {
    expect(QuranMenuIndex.normalize('سُورَةُ البَقَرَةِ'), 'سوره البقره');
    expect(QuranMenuIndex.normalize('٢'), '2');
    expect(QuranMenuIndex.normalize('۳'), '3');
  });

  test('finds a surah by its simplified name', () {
    final results =
        QuranMenuIndex(chapters: chapters).search(QuranMenuSection.all, 'البقره');

    expect(results.map((entry) => entry.number), contains(2));
    expect(
      results.where((entry) => entry.section == QuranMenuSection.surah),
      hasLength(1),
    );
  });

  test('finds juz and hizb by western or Arabic-Indic numbers', () {
    final index = QuranMenuIndex(chapters: chapters);

    final juz = index.search(QuranMenuSection.juz, '٢');
    expect(juz.map((entry) => entry.number), [2]);

    final hizb = index.search(QuranMenuSection.hizb, 'حزب 3');
    expect(hizb.map((entry) => entry.number), [3]);
  });

  test('section words in the query narrow the results', () {
    final index = QuranMenuIndex(chapters: chapters);

    final juz = index.search(QuranMenuSection.all, 'جزء 2');
    expect(juz, hasLength(1));
    expect(juz.single.section, QuranMenuSection.juz);
    expect(juz.single.number, 2);

    final hizb = index.search(QuranMenuSection.all, 'الحزب 3');
    expect(hizb, hasLength(1));
    expect(hizb.single.section, QuranMenuSection.hizb);
    expect(hizb.single.number, 3);
  });

  test('builds entry points for every juz and hizb', () {
    final entries = QuranMenuIndex(chapters: chapters).entries;

    expect(
      entries.where((entry) => entry.section == QuranMenuSection.juz),
      hasLength(30),
    );
    expect(
      entries.where((entry) => entry.section == QuranMenuSection.hizb),
      hasLength(60),
    );
  });

  testWidgets('surah menu shows juz and hizb in one list', (tester) async {
    final pageController = PageController();
    addTearDown(pageController.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: QuranMenuTab(
            pageController: pageController,
            chapters: chapters,
          ),
        ),
      ),
    ));

    expect(find.text('سور'), findsOneWidget);
    expect(find.text('أجزاء'), findsOneWidget);
    expect(find.text('أحزاب'), findsOneWidget);
    expect(find.text('سورة البقرة'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'البقره');
    await tester.pump();
    expect(find.text('سورة البقرة'), findsOneWidget);
    expect(find.text('جزء'), findsNothing);
    expect(find.text('حزب'), findsNothing);

    await tester.enterText(find.byType(TextField), 'جزء 2');
    await tester.pump();
    expect(find.text('الأجزاء'), findsOneWidget);
    expect(find.text('سورة البقرة'), findsNothing);
    expect(find.text('2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'حزب 3');
    await tester.pump();
    expect(find.text('الأحزاب'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
