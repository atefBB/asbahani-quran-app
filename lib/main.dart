import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'data/app_preferences.dart';
import 'screens/quran_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Wakelock is a reader preference, not a permanent requirement. Unsupported
  // platforms (e.g. web) simply keep their default behaviour.
  try {
    final keepAwake = await AppPreferences.keepAwake();
    if (keepAwake) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  } catch (_) {
    // Ignored: the Quran stays usable without a wakelock plugin.
  }

  runApp(const QuranScreen());
}
