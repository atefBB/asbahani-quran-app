import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/chapter_provider.dart';
import 'screens/quran_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

//  SystemChrome.setEnabledSystemUIMode(
  //     SystemUiMode.immersiveSticky); // Enables full-screen mode
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ChapterProvider()),
  ], child: const QuranScreen()));
}
