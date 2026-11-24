import 'dart:convert';

import 'package:asbahani/data/page_data.dart';

/// Serializable form of both bookmark lists used by the app.
class BookmarkData {
  final List<int> pages;
  final List<String> ayahs;

  const BookmarkData({this.pages = const [], this.ayahs = const []});

  bool get isEmpty => pages.isEmpty && ayahs.isEmpty;
}

/// Result of reading a bookmark file. Entries outside the mushaf range or with
/// an invalid `surah:ayah` shape are skipped and counted for user feedback.
class BookmarkImportResult {
  final BookmarkData bookmarks;
  final int skipped;

  const BookmarkImportResult({required this.bookmarks, required this.skipped});
}

/// Result of merging imported bookmarks into the current ones.
class BookmarkMergeResult {
  final BookmarkData bookmarks;
  final int addedPages;
  final int addedAyahs;

  const BookmarkMergeResult({
    required this.bookmarks,
    required this.addedPages,
    required this.addedAyahs,
  });

  bool get isEmpty => addedPages == 0 && addedAyahs == 0;
}

/// Reads and writes the bookmark file format.
///
/// Both page bookmarks and ayah bookmarks travel in one JSON document so a
/// single export/import round trip preserves everything.
class BookmarkTransfer {
  static const int version = 1;

  /// Exports the current bookmark lists as pretty-printed JSON.
  static String encode(BookmarkData data, {DateTime? exportedAt}) {
    final payload = <String, dynamic>{
      'version': version,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'pages': List<int>.from(data.pages)..sort(),
      'ayahs': List<String>.from(data.ayahs)..sort(_compareAyahKeys),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Parses a bookmark file. Accepts the `pages`/`ayahs` keys written by
  /// [encode] as well as the `bookmarks`/`ayahBookmarks` preference names.
  ///
  /// Throws [FormatException] when the text is not JSON or the root is not a
  /// map with at least one of those keys.
  static BookmarkImportResult decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('الملف ليس ملف محفوظات صالح');
    }
    if (decoded is! Map) {
      throw const FormatException('صيغة الملف غير صحيحة');
    }

    final rawPages = decoded['pages'] ?? decoded['bookmarks'];
    final rawAyahs = decoded['ayahs'] ?? decoded['ayahBookmarks'];
    if (rawPages == null && rawAyahs == null) {
      throw const FormatException('الملف لا يحتوي على محفوظات');
    }
    if (rawPages is! List && rawPages != null ||
        rawAyahs is! List && rawAyahs != null) {
      throw const FormatException('صيغة الملف غير صحيحة');
    }

    final pages = <int>{};
    var skipped = 0;
    for (final entry in rawPages ?? const <dynamic>[]) {
      final page = entry is int
          ? entry
          : entry is String
              ? int.tryParse(entry)
              : null;
      if (page != null && page >= 1 && page <= quranPages.length) {
        pages.add(page);
      } else {
        skipped++;
      }
    }

    final ayahs = <String>{};
    for (final entry in rawAyahs ?? const <dynamic>[]) {
      final key = entry is String ? _validAyahKey(entry) : null;
      if (key != null) {
        ayahs.add(key);
      } else {
        skipped++;
      }
    }

    return BookmarkImportResult(
      bookmarks: BookmarkData(
        pages: pages.toList()..sort(),
        ayahs: ayahs.toList()..sort(_compareAyahKeys),
      ),
      skipped: skipped,
    );
  }

  /// Merges two bookmark sets without duplicates, reporting how many entries
  /// were actually new. Existing bookmarks are preserved.
  static BookmarkMergeResult merge(BookmarkData current, BookmarkData imported) {
    final currentPages = current.pages.toSet();
    final currentAyahs = current.ayahs.toSet();
    final addedPages =
        imported.pages.where((page) => !currentPages.contains(page)).length;
    final addedAyahs =
        imported.ayahs.where((key) => !currentAyahs.contains(key)).length;

    return BookmarkMergeResult(
      bookmarks: BookmarkData(
        pages: <int>{...currentPages, ...imported.pages}.toList()..sort(),
        ayahs: <String>{...currentAyahs, ...imported.ayahs}.toList()
          ..sort(_compareAyahKeys),
      ),
      addedPages: addedPages,
      addedAyahs: addedAyahs,
    );
  }

  static String? _validAyahKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) return null;
    if (surah < 1 || surah > 114 || ayah < 1 || ayah > 286) return null;
    return '$surah:$ayah';
  }

  static int _compareAyahKeys(String a, String b) {
    final aParts = a.split(':').map(int.parse).toList();
    final bParts = b.split(':').map(int.parse).toList();
    final bySurah = aParts[0].compareTo(bParts[0]);
    return bySurah != 0 ? bySurah : aParts[1].compareTo(bParts[1]);
  }
}
