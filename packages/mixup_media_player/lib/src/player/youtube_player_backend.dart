import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mixup_media_player/src/model/media_source.dart';
import 'package:mixup_media_player/src/model/media_state.dart';
import 'package:mixup_media_player/src/player/async_update_revision.dart';
import 'package:mixup_media_player/src/player/media_player_backend.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

@internal
final class YouTubePlayerBackend implements MediaPlayerBackend {
  YouTubePlayerBackend(this.videoId, this.onChanged);

  final VideoId videoId;
  final PlaybackChanged onChanged;
  YoutubePlayerController? _controller;

  bool get hasController => _controller != null;

  YoutubePlayerController get controller => _controller!;
  StreamSubscription<YoutubePlayerValue>? _subscription;
  final AsyncUpdateRevision _updateRevision = AsyncUpdateRevision();
  bool _refreshingTime = false;
  bool _stopped = false;
  Duration _duration = Duration.zero;

  @override
  Future<void> initialize() async {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId.value,
      params: const YoutubePlayerParams(showControls: false),
    );
    _controller = controller;
    _subscription = controller.stream.listen(_notify);
  }

  Future<void> _notify(YoutubePlayerValue value) async {
    if (_refreshingTime) return;
    final revision = _updateRevision.capture();
    _refreshingTime = true;
    try {
      final times = await Future.wait([
        controller.currentTime,
        controller.duration,
      ]);
      if (!_updateRevision.isCurrent(revision) || _controller == null) return;
      _duration = Duration(milliseconds: (times[1] * 1000).round());
      final status = value.hasError
          ? MediaPlaybackStatus.error
          : _stopped
          ? MediaPlaybackStatus.stopped
          : switch (value.playerState) {
              PlayerState.playing => MediaPlaybackStatus.playing,
              PlayerState.paused => MediaPlaybackStatus.paused,
              PlayerState.ended => MediaPlaybackStatus.completed,
              PlayerState.buffering ||
              PlayerState.unknown => MediaPlaybackStatus.loading,
              PlayerState.unStarted ||
              PlayerState.cued => MediaPlaybackStatus.stopped,
            };
      onChanged(
        PlaybackSnapshot(
          status: status,
          position: Duration(milliseconds: (times[0] * 1000).round()),
          duration: _duration,
          error: value.hasError ? value.error : null,
        ),
      );
    } finally {
      _refreshingTime = false;
    }
  }

  @override
  Future<void> play() async {
    _updateRevision.invalidate();
    _stopped = false;
    await controller.playVideo();
  }

  @override
  Future<void> pause() {
    _updateRevision.invalidate();
    return controller.pauseVideo();
  }

  @override
  Future<void> stop() async {
    _updateRevision.invalidate();
    _stopped = true;
    await controller.cueVideoById(videoId: videoId.value, startSeconds: 0);
    onChanged(
      PlaybackSnapshot(
        status: MediaPlaybackStatus.stopped,
        position: Duration.zero,
        duration: _duration,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) {
    _updateRevision.invalidate();
    return controller.seekTo(
      seconds: position.inMilliseconds / Duration.millisecondsPerSecond,
      allowSeekAhead: true,
    );
  }

  @override
  Future<void> dispose() async {
    _updateRevision.invalidate();
    await _subscription?.cancel();
    await _controller?.close();
    _controller = null;
  }
}
