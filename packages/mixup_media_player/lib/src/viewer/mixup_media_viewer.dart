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

/// The only viewer callers need to render for all supported source types.
final class MixupMediaViewer extends StatelessWidget {
  /// Creates the unified viewer for [controller].
  const MixupMediaViewer({
    required this.controller,
    this.loadingLabel = 'Loading media…',
    super.key,
  });

  /// Canonical source, state, and operation owner.
  final MixupMediaController controller;

  /// Semantics label shown while the media surface is loading.
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildSurface(controller.state),
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
      loadingLabel: loadingLabel,
    );
  }
}
