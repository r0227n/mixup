import 'package:flutter/material.dart';
import 'package:mixup_media_player/src/controller/mixup_media_controller.dart';
import 'package:mixup_media_player/src/model/media_source.dart';
import 'package:mixup_media_player/src/model/media_state.dart';
import 'package:mixup_media_player/src/player/audio_player_backend.dart';
import 'package:mixup_media_player/src/player/video_player_backend.dart';
import 'package:mixup_media_player/src/player/youtube_player_backend.dart';
import 'package:mixup_media_player/src/viewer/audio_viewer.dart';
import 'package:mixup_media_player/src/viewer/media_surface_stack.dart';
import 'package:mixup_media_player/src/viewer/video_viewer.dart';
import 'package:mixup_media_player/src/viewer/youtube_viewer.dart';

@immutable
/// Localizable text used by [MixupMediaViewer].
final class MixupMediaViewerLabels {
  /// Creates customizable, localizable control labels.
  const MixupMediaViewerLabels({
    this.loading = 'Loading media…',
    this.retry = 'Retry',
    this.play = 'Play',
    this.pause = 'Pause',
    this.stop = 'Stop',
    this.rewind = 'Rewind 10 seconds',
    this.forward = 'Forward 10 seconds',
  });

  /// Loading semantics label.
  final String loading;

  /// Retry button label.
  final String retry;

  /// Play button label.
  final String play;

  /// Pause button label.
  final String pause;

  /// Stop button label.
  final String stop;

  /// Backward skip tooltip.
  final String rewind;

  /// Forward skip tooltip.
  final String forward;
}

/// The only viewer callers need to render for all supported source types.
final class MixupMediaViewer extends StatelessWidget {
  /// Creates the unified viewer for [controller].
  const MixupMediaViewer({
    required this.controller,
    this.labels = const MixupMediaViewerLabels(),
    super.key,
  });

  /// Canonical source, state, and operation owner.
  final MixupMediaController controller;

  /// Localizable viewer labels.
  final MixupMediaViewerLabels labels;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: _buildSurface(state)),
            if (state.status == MediaPlaybackStatus.error)
              _ErrorView(controller: controller, labels: labels)
            else
              _Controls(controller: controller, labels: labels),
          ],
        );
      },
    );
  }

  Widget _buildSurface(MediaState state) {
    final surface = switch ((controller.source, controller.backend)) {
      (VideoMediaSource(), final VideoPlayerBackend backend) => VideoViewer(
        backend: backend,
      ),
      (AudioMediaSource(), AudioPlayerBackend()) => const AudioViewer(),
      (YouTubeMediaSource(), final YouTubePlayerBackend backend)
          when backend.hasController =>
        YouTubeViewer(
          backend: backend,
        ),
      _ => const ColoredBox(color: Colors.black),
    };

    return MediaSurfaceStack(
      surface: surface,
      isLoading: state.status == MediaPlaybackStatus.loading,
      loadingLabel: labels.loading,
    );
  }
}

final class _Controls extends StatelessWidget {
  const _Controls({required this.controller, required this.labels});

  final MixupMediaController controller;
  final MixupMediaViewerLabels labels;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final max = state.duration.inMilliseconds.toDouble();
    final value = state.position.inMilliseconds.clamp(0, max > 0 ? max : 1);

    return Column(
      children: [
        Slider(
          value: value.toDouble(),
          max: max > 0 ? max : 1,
          onChanged: state.isReady
              ? (milliseconds) => controller
                    .seek(Duration(milliseconds: milliseconds.round()))
                    .ignore()
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: labels.rewind,
              onPressed: () =>
                  controller.skipBackward(const Duration(seconds: 10)).ignore(),
              icon: const Icon(Icons.replay_10),
            ),
            IconButton(
              tooltip: state.isPlaying ? labels.pause : labels.play,
              onPressed: () =>
                  (state.isPlaying ? controller.pause() : controller.play())
                      .ignore(),
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              tooltip: labels.stop,
              onPressed: () => controller.stop().ignore(),
              icon: const Icon(Icons.stop),
            ),
            IconButton(
              tooltip: labels.forward,
              onPressed: () =>
                  controller.skipForward(const Duration(seconds: 10)).ignore(),
              icon: const Icon(Icons.forward_10),
            ),
            Text('${_format(state.position)} / ${_format(state.duration)}'),
          ],
        ),
      ],
    );
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return value.inHours > 0
        ? '${value.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

final class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.controller, required this.labels});

  final MixupMediaController controller;
  final MixupMediaViewerLabels labels;

  @override
  Widget build(BuildContext context) {
    final failure = controller.state.failure!;

    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Text(failure.message),
          if (failure.recoveryAction == MediaRecoveryAction.retry)
            TextButton(
              onPressed: () => controller.retry().ignore(),
              child: Text(labels.retry),
            ),
        ],
      ),
    );
  }
}
