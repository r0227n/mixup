import 'package:flutter/foundation.dart';
import 'package:mixup_media_player/src/model/media_player_exception.dart';

/// Lifecycle states exposed by [MediaState].
enum MediaPlaybackStatus {
  /// A backend is being prepared.
  loading,

  /// Media is actively playing.
  playing,

  /// Media is paused at its current position.
  paused,

  /// Media is stopped at the beginning.
  stopped,

  /// Playback reached the end.
  completed,

  /// Loading or playback failed.
  error,
}

/// Stable failure categories independent from playback plugins.
enum MediaFailureKind {
  /// Source data is invalid.
  invalidSource,

  /// A source could not be prepared.
  loadFailed,

  /// An operation failed after preparation.
  playbackFailed,
}

/// Suggested caller recovery for a failure.
enum MediaRecoveryAction {
  /// Retry the current source.
  retry,

  /// Ask the user to choose a different source.
  chooseAnotherSource,
}

/// Failure information attached to an error [MediaState].
@immutable
final class MediaFailure {
  /// Creates failure information from a typed [exception].
  const MediaFailure({
    required this.kind,
    required this.exception,
    required this.recoveryAction,
  });

  /// Stable failure category.
  final MediaFailureKind kind;

  /// Typed exception available to caller-side error handling.
  final MediaPlayerException exception;

  /// User-presentable fallback message.
  String get message => exception.message;

  /// Suggested recovery action.
  final MediaRecoveryAction recoveryAction;
}

/// Immutable canonical playback state.
@immutable
final class MediaState {
  /// Creates a state snapshot.
  const MediaState({
    required this.status,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.failure,
  });

  /// Creates the initial loading state.
  const MediaState.loading() : this(status: MediaPlaybackStatus.loading);

  /// Current playback lifecycle status.
  final MediaPlaybackStatus status;

  /// Current playback position.
  final Duration position;

  /// Playable duration when known.
  final Duration duration;

  /// Typed failure for [MediaPlaybackStatus.error].
  final MediaFailure? failure;

  /// Whether playback operations are currently accepted.
  bool get isReady =>
      status != MediaPlaybackStatus.loading &&
      status != MediaPlaybackStatus.error;

  /// Whether media is actively playing.
  bool get isPlaying => status == MediaPlaybackStatus.playing;

  /// Returns a state with selected values replaced.
  MediaState copyWith({
    MediaPlaybackStatus? status,
    Duration? position,
    Duration? duration,
    MediaFailure? failure,
    bool clearFailure = false,
  }) => MediaState(
    status: status ?? this.status,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
