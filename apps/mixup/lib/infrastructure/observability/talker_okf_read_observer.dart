import 'package:okf_repository/okf_repository.dart';
import 'package:talker/talker.dart';

/// Sends package-owned OKF read events to the app's Talker instance.
class TalkerOkfReadObserver {
  /// Creates a Talker adapter.
  const TalkerOkfReadObserver(this.talker);

  /// Application-wide logger.
  final Talker talker;

  /// Handles one OKF read lifecycle event.
  void call(OkfReadEvent event) {
    switch (event.phase) {
      case OkfReadPhase.started:
        talker.debug('Content read started: ${event.documentLabel}');
      case OkfReadPhase.completed:
        talker.debug(
          'Content read completed: ${event.documentLabel} '
          '(${event.characterCount} chars, '
          '${event.elapsedMilliseconds} ms)',
        );
      case OkfReadPhase.failed:
        talker.error(
          'Content read failed: ${event.documentLabel} '
          '(${event.failureType ?? 'unknown failure'})',
        );
    }
  }
}
