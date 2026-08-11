// Feature-private UI favors readable Japanese strings over member API docs.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs

import 'package:flutter/material.dart';
import 'package:mixup/core/gen/slang.g.dart';
import 'package:mixup_media_player/mixup_media_player.dart';

class PracticePlayer extends StatelessWidget {
  const PracticePlayer({required this.controller, super.key});

  final MixupMediaController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final state = controller.state;
      if (state.status == MediaPlaybackStatus.loading) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(t.practice.player.loading),
              ],
            ),
          ),
        );
      }
      if (state.status == MediaPlaybackStatus.error) {
        return Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.practice.player.failure(
                      error: state.failure?.message ?? '',
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: controller.retry,
                  child: Text(t.practice.common.retry),
                ),
              ],
            ),
          ),
        );
      }
      final durationMs = state.duration.inMilliseconds;
      final positionMs = state.position.inMilliseconds.clamp(0, durationMs);
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      '${formatTime(state.position)} / ${formatTime(state.duration)}',
                    ),
                  ),
                  IconButton(
                    tooltip: t.practice.player.backFive,
                    onPressed: () =>
                        controller.skipBackward(const Duration(seconds: 5)),
                    icon: const Icon(Icons.replay_5),
                  ),
                  IconButton.filled(
                    tooltip: state.isPlaying
                        ? t.practice.player.pause
                        : t.practice.player.play,
                    onPressed: state.isPlaying
                        ? controller.pause
                        : controller.play,
                    icon: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                  ),
                  IconButton(
                    tooltip: t.practice.player.forwardFive,
                    onPressed: () =>
                        controller.skipForward(const Duration(seconds: 5)),
                    icon: const Icon(Icons.forward_5),
                  ),
                  Expanded(
                    child: Slider(
                      value: durationMs == 0 ? 0 : positionMs.toDouble(),
                      max: durationMs <= 0 ? 1 : durationMs.toDouble(),
                      onChanged: (value) => controller.seek(
                        Duration(milliseconds: value.round()),
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  switch (state.status) {
                    MediaPlaybackStatus.playing =>
                      t.practice.player.status.playing,
                    MediaPlaybackStatus.paused =>
                      t.practice.player.status.paused,
                    MediaPlaybackStatus.stopped =>
                      t.practice.player.status.stopped,
                    MediaPlaybackStatus.completed =>
                      t.practice.player.status.completed,
                    _ => '',
                  },
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String formatTime(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60);
  final centiseconds = value.inMilliseconds.remainder(1000) ~/ 10;
  return '$minutes:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
}
