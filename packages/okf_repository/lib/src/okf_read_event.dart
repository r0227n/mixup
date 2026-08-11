/// Stage of one OKF document read.
enum OkfReadPhase {
  /// File loading has started.
  started,

  /// File loading and parsing completed.
  completed,

  /// File loading or parsing failed.
  failed,
}

/// Observable information about one repository read.
class OkfReadEvent {
  /// Creates a read event without exposing the absolute bundle path.
  const OkfReadEvent({
    required this.phase,
    required this.relativePath,
    required this.bundleLabel,
    this.characterCount,
    this.elapsedMilliseconds,
    this.failureType,
  });

  /// Current read stage.
  final OkfReadPhase phase;

  /// Optional non-sensitive name supplied by the consumer.
  final String? bundleLabel;

  /// Path relative to the bundle root.
  final String relativePath;

  /// Number of source characters read on completion.
  final int? characterCount;

  /// Elapsed read and parse time on completion.
  final int? elapsedMilliseconds;

  /// Runtime type of a failure, without paths or exception details.
  final String? failureType;

  /// Privacy-safe document label for logs.
  String get documentLabel =>
      bundleLabel == null ? relativePath : '$bundleLabel/$relativePath';
}

/// Receives repository read lifecycle events.
typedef OkfReadObserver = void Function(OkfReadEvent event);
