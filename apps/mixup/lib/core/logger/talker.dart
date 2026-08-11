import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'talker.g.dart';

/// Creates the application-wide Talker instance.
Talker createTalker({TalkerObserver? observer}) =>
    TalkerFlutter.init(observer: observer);

/// The application-wide Talker instance supplied by the composition root.
@Riverpod(keepAlive: true)
Talker talker(Ref ref) => throw UnimplementedError('Talker must be injected.');

/// Records an exception that escaped the application zone.
void handleUncaughtAppException(
  Talker talker,
  Object error,
  StackTrace stackTrace,
) {
  talker.handle(error, stackTrace, 'Uncaught app exception');
}
