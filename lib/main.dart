import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'screens/quran_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  runApp(const QuranScreen());
}
