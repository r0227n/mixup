import 'package:flutter_test/flutter_test.dart';
import 'package:mixup_media_player/src/player/async_update_revision.dart';

void main() {
  test('invalidates an asynchronous update captured before an operation', () {
    final revision = AsyncUpdateRevision();
    final pendingUpdate = revision.capture();

    revision.invalidate();

    expect(revision.isCurrent(pendingUpdate), isFalse);
    expect(revision.isCurrent(revision.capture()), isTrue);
  });
}
