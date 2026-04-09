import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class DownloadManager {
  static const String _baseUrl = 'https://your-cdn-url.com';
  static const int _initialPages = 10;
  static const int _precacheCount = 5;

  static Future<Directory> _getImagesDir(String mushafType) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/$mushafType');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  static Future<String> getImagePath(String mushafType, int pageNumber) async {
    final imagesDir = await _getImagesDir(mushafType);
    return '${imagesDir.path}/$pageNumber.png';
  }

  static Future<bool> isImageDownloaded(String mushafType, int pageNumber) async {
    final path = await getImagePath(mushafType, pageNumber);
    return File(path).existsSync();
  }

  static Future<bool> downloadImage(String mushafType, int pageNumber) async {
    try {
      final path = await getImagePath(mushafType, pageNumber);
      final file = File(path);
      if (await file.exists()) return true;

      final url = '$_baseUrl/$mushafType/$pageNumber.png';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to download page $pageNumber: $e');
      return false;
    }
  }

  static Future<bool> isInitialDownloadComplete(String mushafType) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('downloaded_$mushafType') ?? false;
  }

  static Future<void> markInitialDownloadComplete(String mushafType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloaded_$mushafType', true);
  }

  static Future<void> downloadInitialPages(
    String mushafType,
    void Function(int current, int total, String pageName) onProgress,
  ) async {
    for (int i = 1; i <= _initialPages; i++) {
      await downloadImage(mushafType, i);
      onProgress(i, _initialPages, mushafType == 'asbahani' ? 'مصحف الأصبهاني' : 'مصحف الأزرق');
    }
    await markInitialDownloadComplete(mushafType);
  }

  static Future<void> precacheNextPages(
    String mushafType,
    int currentPage,
  ) async {
    for (int i = currentPage + 1; i <= currentPage + _precacheCount; i++) {
      if (i > 604) break;
      await downloadImage(mushafType, i);
    }
  }

  static Future<void> downloadAllPages(
    String mushafType,
    void Function(int current, int total, String pageName) onProgress,
  ) async {
    for (int i = 1; i <= 604; i++) {
      await downloadImage(mushafType, i);
      onProgress(i, 604, mushafType == 'asbahani' ? 'مصحف الأصبهاني' : 'مصحف الأزرق');
    }
    await markInitialDownloadComplete(mushafType);
  }
}
