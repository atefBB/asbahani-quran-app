import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asbahani/data/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('wakelock stays on by default', () async {
    expect(await AppPreferences.keepAwake(), isTrue);
  });

  test('readers can turn the wakelock off', () async {
    await AppPreferences.setKeepAwake(false);

    expect(await AppPreferences.keepAwake(), isFalse);
  });
}
