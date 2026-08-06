import 'package:flutter/foundation.dart';

import 'package:mixup_media_player/src/model/media_state.dart';

@internal
typedef PlaybackChanged = void Function(PlaybackSnapshot snapshot);

@immutable
@internal
final class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.status,
    required this.position,
    required this.duration,
    this.error,
  });

  final MediaPlaybackStatus status;
  final Duration position;
  final Duration duration;
  final Object? error;
}

@internal
abstract interface class MediaPlayerBackend {
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}
