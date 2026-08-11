import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'debug build can read configured repository paths outside app sandbox',
    () {
      final entitlements = File(
        'macos/Runner/DebugProfile.entitlements',
      ).readAsStringSync();

      expect(
        entitlements,
        contains(
          '<key>com.apple.security.app-sandbox</key>\n\t<false/>',
        ),
      );
    },
  );
}
