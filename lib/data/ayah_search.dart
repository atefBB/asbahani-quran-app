import 'package:asbahani/data/quran_navigation.dart';

class _IndexedAyah {
  const _IndexedAyah(this.ayah, this.normalizedText);

  final dynamic ayah;
  final String normalizedText;
}

/// Precomputed ayah text search.
///
/// Normalizing every ayah on each keystroke made typing feel slow; the text is
/// normalized once when the Quran JSON loads and each query is normalized the
/// same way as the menu search, so diacritics and alef/yaa variants match too.
class AyahSearchIndex {
  AyahSearchIndex(Iterable<dynamic> ayahs)
      : _entries = ayahs
            .map(
              (ayah) => _IndexedAyah(
                ayah,
                QuranMenuIndex.normalize(
                  ayah['aya_text_emlaey'] as String? ?? '',
                ),
              ),
            )
            .toList(growable: false);

  final List<_IndexedAyah> _entries;

  List<dynamic> search(String query) {
    final normalized = QuranMenuIndex.normalize(query);
    if (normalized.isEmpty) return const <dynamic>[];

    return _entries
        .where((entry) => entry.normalizedText.contains(normalized))
        .map((entry) => entry.ayah)
        .toList(growable: false);
  }
}
