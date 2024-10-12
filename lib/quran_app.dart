import 'package:flutter_quran/flutter_quran.dart';
import 'package:flutter/material.dart';

class FlutterQuranApp extends StatefulWidget {
  const FlutterQuranApp({super.key});

  @override
  State<FlutterQuranApp> createState() => _AppState();
}

class _AppState extends State<FlutterQuranApp> {
  @override
  void initState() {
    FlutterQuran().init();
    FlutterQuran().hafsStyle;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const FlutterQuranScreen();
  }
}
