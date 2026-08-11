import 'package:flutter/foundation.dart';
import 'package:mixup_media_player/src/model/media_source.dart';
import 'package:mixup_media_player/src/model/media_state.dart';
import 'package:mixup_media_player/src/player/media_player_backend.dart';
import 'package:video_player/video_player.dart';

@internal
final class VideoPlayerBackend implements MediaPlayerBackend {
  VideoPlayerBackend(this.data, this.onChanged);

  final VideoData data;
  final PlaybackChanged onChanged;
  late final VideoPlayerController controller;

  @override
  Future<void> initialize() async {
    controller = switch (data) {
      NetworkVideoData(:final url) => VideoPlayerController.networkUrl(url),
      AssetVideoData(:final asset, :final package) =>
        VideoPlayerController.asset(asset, package: package),
    };
    controller.addListener(_notify);
    await controller.initialize();
    _notify();
  }

  void _notify() {
    final value = controller.value;
    final status = value.hasError
        ? MediaPlaybackStatus.error
        : value.isCompleted
        ? MediaPlaybackStatus.completed
        : value.isPlaying
        ? MediaPlaybackStatus.playing
        : value.position == Duration.zero
        ? MediaPlaybackStatus.stopped
        : MediaPlaybackStatus.paused;
    onChanged(
      PlaybackSnapshot(
        status: status,
        position: value.position,
        duration: value.duration,
        error: value.errorDescription,
      ),
    );
  }

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> stop() async {
    await controller.pause();
    await controller.seekTo(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) => controller.seekTo(position);

  @override
  Future<void> dispose() async {
    controller.removeListener(_notify);
    await controller.dispose();
  }
}
