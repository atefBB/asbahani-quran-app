import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../models/chapter.dart';

class ChapterProvider with ChangeNotifier {
  List<Chapter> _chapters = [];

  List<Chapter> get chapters => _chapters;

  Future<void> loadChapters() async {
    final String response = await rootBundle.loadString('assets/chapters.json');
    final data = await jsonDecode(response) as List;

    _chapters =
        data.map((chapterJson) => Chapter.fromJson(chapterJson)).toList();
    notifyListeners();
  }
}
