import 'package:flutter_test/flutter_test.dart';
import 'package:mixup/infrastructure/content/content_settings.dart';

void main() {
  test('parses both configured content paths', () {
    final settings = ContentSettings.fromJson('''
      {"contentPaths":{"songs":"songs","mixes":"mixs"}}
    ''');

    expect(settings.songsPath, 'songs');
    expect(settings.mixesPath, 'mixs');
  });

  test('rejects a missing content path', () {
    expect(
      () => ContentSettings.fromJson('{"contentPaths":{"songs":"songs"}}'),
      throwsFormatException,
    );
  });

  test('rejects malformed JSON', () {
    expect(() => ContentSettings.fromJson('{'), throwsFormatException);
  });
}
