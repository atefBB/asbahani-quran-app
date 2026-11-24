import 'package:asbahani/data/bookmark_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookmarkTransfer', () {
    test('export includes page and ayah bookmarks in one document', () {
      final json = BookmarkTransfer.encode(
        const BookmarkData(
          pages: [300, 1],
          ayahs: ['2:255', '1:1'],
        ),
        exportedAt: DateTime.utc(2026, 11, 24),
      );

      final result = BookmarkTransfer.decode(json);
      expect(result.bookmarks.pages, [1, 300]);
      expect(result.bookmarks.ayahs, ['1:1', '2:255']);
      expect(result.skipped, 0);
      expect(json, contains('"version": 1'));
      expect(json, contains('2026-11-24T00:00:00.000Z'));
    });

    test('accepts SharedPreferences key names and numeric page strings', () {
      final result = BookmarkTransfer.decode(
        '{"bookmarks":["7","12"],"ayahBookmarks":["12:5"]}',
      );
      expect(result.bookmarks.pages, [7, 12]);
      expect(result.bookmarks.ayahs, ['12:5']);
    });

    test('skips invalid entries while keeping valid ones', () {
      final result = BookmarkTransfer.decode(
        '{"pages":[0,605,42,"x"],"ayahs":["1:1","2:287","3","4:0"]}',
      );
      expect(result.bookmarks.pages, [42]);
      expect(result.bookmarks.ayahs, ['1:1']);
      expect(result.skipped, 6);
    });

    test('accepts an empty export', () {
      final result = BookmarkTransfer.decode(BookmarkTransfer.encode(
        const BookmarkData(),
      ));
      expect(result.bookmarks.isEmpty, isTrue);
      expect(result.skipped, 0);
    });

    test('merge keeps existing bookmarks and deduplicates', () {
      final merged = BookmarkTransfer.merge(
        const BookmarkData(pages: [1, 300], ayahs: ['1:1']),
        const BookmarkData(pages: [300, 42], ayahs: ['1:1', '2:255']),
      );
      expect(merged.bookmarks.pages, [1, 42, 300]);
      expect(merged.bookmarks.ayahs, ['1:1', '2:255']);
      expect(merged.addedPages, 1);
      expect(merged.addedAyahs, 1);
      expect(merged.isEmpty, isFalse);
    });

    test('merge reports nothing new for an identical set', () {
      final merged = BookmarkTransfer.merge(
        const BookmarkData(pages: [7], ayahs: ['2:255']),
        const BookmarkData(pages: [7], ayahs: ['2:255']),
      );
      expect(merged.isEmpty, isTrue);
    });

    test('rejects malformed files', () {
      expect(() => BookmarkTransfer.decode('not json'),
          throwsA(isA<FormatException>()));
      expect(() => BookmarkTransfer.decode('[]'),
          throwsA(isA<FormatException>()));
      expect(() => BookmarkTransfer.decode('{"other":1}'),
          throwsA(isA<FormatException>()));
      expect(() => BookmarkTransfer.decode('{"pages":{}}'),
          throwsA(isA<FormatException>()));
    });
  });
}
