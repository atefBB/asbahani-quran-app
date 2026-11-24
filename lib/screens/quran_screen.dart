import 'package:flutter/material.dart';

import 'quran_page.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اﻷصبهاني',
      theme: ThemeData(
        fontFamily: 'Avenir Arabic',
      ),
      home: const QuranPage(),
    );
  }
}
