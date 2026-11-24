import 'package:dartarabic/dartarabic.dart';

import 'package:asbahani/data/page_data.dart';

/// The single menu now covers surahs, juz and hizb in one place.
///
/// [QuranMenuSection.all] is only a filter value; entries always belong to one
/// of the three concrete sections.
enum QuranMenuSection { all, surah, juz, hizb }

extension QuranMenuSectionLabel on QuranMenuSection {
  String get label => switch (this) {
        QuranMenuSection.all => 'الكل',
        QuranMenuSection.surah => 'سور',
        QuranMenuSection.juz => 'أجزاء',
        QuranMenuSection.hizb => 'أحزاب',
      };

  String get headerLabel => switch (this) {
        QuranMenuSection.all => '',
        QuranMenuSection.surah => 'السور',
        QuranMenuSection.juz => 'الأجزاء',
        QuranMenuSection.hizb => 'الأحزاب',
      };

  String get singular => switch (this) {
        QuranMenuSection.all => '',
        QuranMenuSection.surah => 'سورة',
        QuranMenuSection.juz => 'جزء',
        QuranMenuSection.hizb => 'حزب',
      };
}

class QuranMenuEntry {
  final QuranMenuSection section;
  final int number;
  final int page;
  final String title;
  final String searchText;

  const QuranMenuEntry({
    required this.section,
    required this.number,
    required this.page,
    required this.title,
    required this.searchText,
  });
}

/// Builds and searches the combined surah/juz/hizb navigation entries.
class QuranMenuIndex {
  QuranMenuIndex({required List<dynamic> chapters})
      : _entries = _buildEntries(chapters);

  final List<QuranMenuEntry> _entries;

  List<QuranMenuEntry> get entries => List.unmodifiable(_entries);

  /// Filters the combined list by [query] and optionally by [section].
  ///
  /// Arabic diacritics, alef/yaa variants and Arabic-Indic digits are
  /// normalized, so e.g. "البقره", "البَقَرَةِ" and "٢" all find their targets.
  /// A section word in the query ("سورة", "جزء" or "حزب") also narrows the
  /// search when no explicit [section] is selected.
  List<QuranMenuEntry> search(QuranMenuSection section, String query) {
    final normalizedQuery = normalize(query);
    final requestedSection = section == QuranMenuSection.all
        ? _sectionFromQuery(normalizedQuery)
        : section;
    final numbers = RegExp(r'\d+')
        .allMatches(normalizedQuery)
        .map((match) => int.parse(match.group(0)!))
        .toList();
    final nonNumericQuery = normalizedQuery
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return _entries.where((entry) {
      if (requestedSection != QuranMenuSection.all &&
          entry.section != requestedSection) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final searchText = normalize(entry.searchText);
      if (numbers.isEmpty) return searchText.contains(normalizedQuery);

      // With digits, match the exact number instead of substrings such as
      // "جزء 2" also matching "جزء 20". The non-numeric part still has to
      // agree ("جزء", "حزب", "صفحة", or a surah name).
      final matchesNumber = numbers.contains(entry.number);
      final matchesPage = nonNumericQuery.isNotEmpty &&
          numbers.contains(entry.page);
      final matchesWords = nonNumericQuery.isEmpty ||
          searchText.contains(nonNumericQuery);
      return (matchesNumber || matchesPage) && matchesWords;
    }).toList();
  }

  static String normalize(String value) {
    final stripped = DartArabic.stripTashkeel(value);
    return stripped
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ـ', '')
        .replaceAllMapped(RegExp(r'[٠-٩]'), _westernDigit)
        .replaceAllMapped(RegExp(r'[۰-۹]'), _westernDigit)
        .toLowerCase()
        .trim();
  }

  static QuranMenuSection _sectionFromQuery(String query) {
    if (query.contains('جزء') || query.contains('اجزاء')) {
      return QuranMenuSection.juz;
    }
    if (query.contains('حزب') || query.contains('احزاب')) {
      return QuranMenuSection.hizb;
    }
    if (query.contains('سور')) return QuranMenuSection.surah;
    return QuranMenuSection.all;
  }

  static String _westernDigit(Match match) {
    final digit = match.group(0)!;
    final codeUnit = digit.codeUnitAt(0);
    final zero = codeUnit >= 0x06F0 ? 0x06F0 : 0x0660;
    return String.fromCharCode(codeUnit - zero + 0x30);
  }

  static List<QuranMenuEntry> _buildEntries(List<dynamic> chapters) {
    final entries = <QuranMenuEntry>[];

    for (final raw in chapters) {
      final chapter = raw as Map<String, dynamic>;
      final id = chapter['id'] as int;
      final page = chapter['page'] as int;
      final name = DartArabic.stripTashkeel(chapter['name_ar'] as String);
      entries.add(QuranMenuEntry(
        section: QuranMenuSection.surah,
        number: id,
        page: page,
        title: name,
        searchText: '$name $id صفحة $page سورة',
      ));
    }

    final juzStarts = <int, int>{};
    final hizbStarts = <int, int>{};
    for (var i = 0; i < quranPages.length; i++) {
      final pageNumber = i + 1;
      juzStarts.putIfAbsent(quranPages[i].juz, () => pageNumber);
      hizbStarts.putIfAbsent(quranPages[i].hizb, () => pageNumber);
    }

    for (final number in juzStarts.keys.toList()..sort()) {
      final page = juzStarts[number]!;
      entries.add(QuranMenuEntry(
        section: QuranMenuSection.juz,
        number: number,
        page: page,
        title: '$number',
        searchText: 'جزء $number صفحة $page',
      ));
    }

    for (final number in hizbStarts.keys.toList()..sort()) {
      final page = hizbStarts[number]!;
      entries.add(QuranMenuEntry(
        section: QuranMenuSection.hizb,
        number: number,
        page: page,
        title: '$number',
        searchText: 'حزب $number الحزب $number صفحة $page',
      ));
    }

    return entries;
  }
}
