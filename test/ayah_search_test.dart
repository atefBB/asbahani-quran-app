import 'package:flutter_test/flutter_test.dart';

import 'package:asbahani/data/ayah_search.dart';

void main() {
  final ayahs = <dynamic>[
    <String, dynamic>{
      'id': 1,
      'aya_text_emlaey': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    },
    <String, dynamic>{
      'id': 2,
      'aya_text_emlaey': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    },
  ];

  test('finds ayahs through diacritics and alef variants', () {
    final index = AyahSearchIndex(ayahs);

    expect(
      index.search('بسم الله').map((ayah) => ayah['id']),
      [1],
    );
    expect(
      index.search('الحمد لله').map((ayah) => ayah['id']),
      [2],
    );
  });

  test('empty query has no results', () {
    expect(AyahSearchIndex(ayahs).search('   '), isEmpty);
  });

  test('text is normalized once when the index is built', () {
    final source = <dynamic>[
      <String, dynamic>{'id': 3, 'aya_text_emlaey': 'سُورَةُ'},
    ];
    final index = AyahSearchIndex(source);
    source.first['aya_text_emlaey'] = 'changed afterwards';

    expect(index.search('سوره').single['id'], 3);
  });
}
