import 'package:flutter_test/flutter_test.dart';
import 'package:mixup_media_player/mixup_media_player.dart';

void main() {
  test('failure retains the typed exception for caller-side handling', () {
    const exception = MediaLoadException(cause: 'platform failure');
    const failure = MediaFailure(
      kind: MediaFailureKind.loadFailed,
      exception: exception,
      recoveryAction: MediaRecoveryAction.retry,
    );

    expect(failure.exception, same(exception));
    expect(failure.message, exception.message);
    expect(failure.exception.cause, 'platform failure');
  });
}
