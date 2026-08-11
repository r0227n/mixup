import 'package:flutter_test/flutter_test.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:mixup/infrastructure/observability/marionette_talker_observer.dart';
import 'package:talker/talker.dart';

void main() {
  test('forwards Talker messages to the Marionette collector', () {
    final logs = <String>[];
    final collector = PrintLogCollector()..start(logs.add);
    final talker = Talker(
      observer: MarionetteTalkerObserver(collector),
      settings: TalkerSettings(useConsoleLogs: false),
    )..debug('Content read completed: songs/index.md');

    expect(talker.history, hasLength(1));
    expect(logs, hasLength(1));
    expect(logs.single, contains('Content read completed: songs/index.md'));
  });
}
