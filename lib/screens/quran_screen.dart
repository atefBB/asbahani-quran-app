import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';

import 'quran_page.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اﻷصبهاني',
      theme: ThemeData(
        fontFamily: ArabicThemeData.font(arabicFont: ArabicFont.avenirArabic),
        package: ArabicThemeData.package,
      ),
      home: const QuranPage(),
    );
  }
}
