// This feature-private widget is documented by its constructor contract.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:mixup/core/gen/slang.g.dart';
import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup_media_player/mixup_media_player.dart';

class PracticeTimelineView extends StatelessWidget {
  const PracticeTimelineView({
    required this.timeline,
    required this.controller,
    required this.onPlaySegment,
    this.onMoveLyric,
    this.onMoveInterlude,
    this.onMoveMix,
    this.onDragStart,
    this.onDragEnd,
    super.key,
  });

  final PracticeTimeline timeline;
  final MixupMediaController controller;
  final ValueChanged<PracticeInterval> onPlaySegment;
  final void Function(String id, Duration offset)? onMoveLyric;
  final void Function(String id, Duration offset)? onMoveInterlude;
  final void Function(String id, Duration offset)? onMoveMix;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final duration = controller.state.duration;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.practice.timeline.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _Track(
                label: t.practice.timeline.lyricsTrack,
                duration: duration,
                position: controller.state.position,
                segments: [
                  for (final item in timeline.lyrics)
                    _Segment(
                      item.interval,
                      Colors.blue,
                      item.text,
                      () => onPlaySegment(item.interval),
                      (offset) => onMoveLyric?.call(item.id, offset),
                      onDragStart,
                      onDragEnd,
                    ),
                  for (final item in timeline.interludes)
                    _Segment(
                      item.interval,
                      Colors.teal,
                      item.label,
                      () => onPlaySegment(item.interval),
                      (offset) => onMoveInterlude?.call(item.id, offset),
                      onDragStart,
                      onDragEnd,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _Track(
                label: t.practice.timeline.mixTrack,
                duration: duration,
                position: controller.state.position,
                segments: [
                  for (final item in timeline.mixes)
                    _Segment(
                      item.interval,
                      Colors.deepOrange,
                      item.mixId,
                      () => onPlaySegment(item.interval),
                      (offset) => onMoveMix?.call(item.id, offset),
                      onDragStart,
                      onDragEnd,
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

final class _Segment {
  const _Segment(
    this.interval,
    this.color,
    this.label,
    this.onTap,
    this.onNudge,
    this.onDragStart,
    this.onDragEnd,
  );
  final PracticeInterval interval;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final ValueChanged<Duration> onNudge;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
}

class _Track extends StatelessWidget {
  const _Track({
    required this.label,
    required this.duration,
    required this.position,
    required this.segments,
  });

  final String label;
  final Duration duration;
  final Duration position;
  final List<_Segment> segments;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 48, child: Text(label)),
      Expanded(
        child: SizedBox(
          height: 36,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final total = duration.inMicroseconds;
              double x(Duration value) => total <= 0
                  ? 0
                  : constraints.maxWidth * value.inMicroseconds / total;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  children: [
                    for (final segment in segments)
                      Positioned(
                        left: x(segment.interval.start),
                        width:
                            (x(segment.interval.end) -
                                    x(segment.interval.start))
                                .clamp(2, constraints.maxWidth),
                        top: 4,
                        bottom: 4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: segment.onTap,
                          onHorizontalDragStart: (_) =>
                              segment.onDragStart?.call(),
                          onHorizontalDragUpdate: (details) {
                            if (constraints.maxWidth <= 0 || total <= 0) return;
                            segment.onNudge(
                              Duration(
                                microseconds:
                                    (total *
                                            details.delta.dx /
                                            constraints.maxWidth)
                                        .round(),
                              ),
                            );
                          },
                          onHorizontalDragEnd: (_) => segment.onDragEnd?.call(),
                          onHorizontalDragCancel: segment.onDragEnd,
                          child: Tooltip(
                            message: t.practice.timeline.dragHint(
                              label: segment.label,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: segment.color.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: x(position).clamp(0, constraints.maxWidth - 2),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}
