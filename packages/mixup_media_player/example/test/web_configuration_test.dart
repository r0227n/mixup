import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads flutter_soloud web scripts before Flutter bootstrap', () {
    final index = File('web/index.html').readAsStringSync();
    final pluginScript = index.indexOf(
      'assets/packages/flutter_soloud/web/libflutter_soloud_plugin.js',
    );
    final moduleScript = index.indexOf(
      'assets/packages/flutter_soloud/web/init_module.dart.js',
    );
    final flutterBootstrap = index.indexOf('flutter_bootstrap.js');

    expect(pluginScript, isNonNegative);
    expect(moduleScript, isNonNegative);
    expect(flutterBootstrap, isNonNegative);
    expect(pluginScript, lessThan(flutterBootstrap));
    expect(moduleScript, lessThan(flutterBootstrap));
  });
}
