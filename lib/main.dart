import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'screens/quran_screen.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const QuranScreen());
}
