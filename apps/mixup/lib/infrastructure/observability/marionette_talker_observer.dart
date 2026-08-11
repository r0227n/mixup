import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:talker/talker.dart';

/// Forwards Talker events to Marionette's debug-only log collector.
class MarionetteTalkerObserver extends TalkerObserver {
  /// Creates an observer backed by [collector].
  const MarionetteTalkerObserver(this.collector);

  /// Collector exposed through Marionette's `get_logs` tool.
  final PrintLogCollector collector;

  @override
  void onLog(TalkerData log) {
    collector.addLog(log.generateTextMessage());
  }
}
