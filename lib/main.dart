import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'providers/chapter_provider.dart';
import 'screens/quran_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ChapterProvider()),
  ], child: const QuranScreen()));
}
