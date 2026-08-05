import 'dart:io';

import 'package:mixup_ffi/mixup_ffi.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath = Platform.environment['MIXUP_FFI_TEST_LIBRARY'];

  test(
    'loads the Rust engine and preserves its structured error',
    () async {
      final temporary = await Directory.systemTemp.createTemp('mixup_ffi_test');
      addTearDown(() => temporary.delete(recursive: true));
      final mixup = await MixupFfi.load(libraryPath: libraryPath!);

      await expectLater(
        mixup.analyze(
          '${temporary.path}/missing.wav',
          modelsDirectory: '${temporary.path}/models',
        ),
        throwsA(
          predicate((error) => error.toString().contains('failed to load')),
        ),
      );
    },
    skip: libraryPath == null
        ? 'Set MIXUP_FFI_TEST_LIBRARY to a built mixup_ffi dynamic library.'
        : false,
  );
}
