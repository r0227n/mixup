// Feature-private UI favors readable Japanese strings over member API docs.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixup/core/gen/slang.g.dart';
import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup/presentation/features/practice/controllers/practice_session.dart';
import 'package:mixup/presentation/features/practice/widgets/interval_form.dart';
import 'package:mixup/presentation/features/practice/widgets/practice_player.dart';
import 'package:mixup/presentation/features/practice/widgets/practice_scaffold.dart';
import 'package:mixup/presentation/features/practice/widgets/practice_timeline_view.dart';
import 'package:mixup_media_player/mixup_media_player.dart';

class LyricsTimingScreen extends ConsumerWidget {
  const LyricsTimingScreen({required this.songId, super.key});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(practiceSessionProvider(songId));
    return sessionState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _LoadFailure(
        error: error,
        onRetry: () => ref.invalidate(practiceSessionProvider(songId)),
      ),
      data: (data) {
        final session = ref.read(practiceSessionProvider(songId).notifier);
        final media = session.mediaController!;
        final content = _TimingContent(
          data: data,
          session: session,
          media: media,
        );
        return PracticeScaffold(
          songId: songId,
          data: data,
          session: session,
          currentStep: 0,
          body: content,
        );
      },
    );
  }
}

class _TimingContent extends StatelessWidget {
  const _TimingContent({
    required this.data,
    required this.session,
    required this.media,
  });

  final PracticeSessionData data;
  final PracticeSession session;
  final MixupMediaController media;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final header = Column(
        children: [
          PracticePlayer(controller: media),
          PracticeTimelineView(
            timeline: data.timeline,
            controller: media,
            onMoveLyric: session.nudgeLyric,
            onMoveInterlude: session.nudgeInterlude,
            onMoveMix: session.nudgeMix,
            onDragStart: session.beginTimelineDrag,
            onDragEnd: session.endTimelineDrag,
          ),
        ],
      );
      final lyrics = _LyricsList(data: data, session: session, media: media);
      final editor = _TimingEditor(data: data, session: session, media: media);
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            header,
            const SizedBox(height: 8),
            Expanded(
              child: constraints.maxWidth >= 900
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: lyrics),
                        const SizedBox(width: 12),
                        SizedBox(width: 380, child: editor),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: lyrics),
                        const Divider(),
                        SizedBox(height: 260, child: editor),
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class _LyricsList extends StatelessWidget {
  const _LyricsList({
    required this.data,
    required this.session,
    required this.media,
  });
  final PracticeSessionData data;
  final PracticeSession session;
  final MixupMediaController media;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: media,
    builder: (context, _) {
      final position = media.state.position;
      return Card(
        clipBehavior: Clip.antiAlias,
        child: ListView.builder(
          itemCount: data.lyricLines.length,
          itemBuilder: (context, index) {
            final id = lyricLineId(index);
            final intervals = data.timeline.lyrics
                .where((item) => item.lyricLineId == id)
                .toList();
            final active = intervals.any(
              (item) => item.interval.contains(position),
            );
            if (intervals.isEmpty) {
              return ListTile(
                selected: data.selectedLyricLine == index,
                leading: const Icon(Icons.schedule),
                title: Text(data.lyricLines[index]),
                subtitle: Text(t.practice.lyrics.unsynced),
                onTap: () => session.selectLyricLine(index),
              );
            }
            return ExpansionTile(
              key: ValueKey(id),
              initiallyExpanded: active,
              backgroundColor: active
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : null,
              collapsedBackgroundColor: active
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : null,
              leading: Icon(
                active ? Icons.play_circle_fill : Icons.check_circle,
              ),
              title: Text(data.lyricLines[index]),
              subtitle: Text(
                t.practice.lyrics.intervalCount(count: intervals.length),
              ),
              onExpansionChanged: (expanded) {
                if (expanded) session.selectLyricLine(index);
              },
              children: [
                for (final interval in intervals)
                  ListTile(
                    dense: true,
                    selected: interval.interval.contains(position),
                    leading: const Icon(Icons.drag_indicator),
                    title: Text(
                      '${formatTime(interval.interval.start)}–${formatTime(interval.interval.end)}',
                    ),
                    onTap: () => media.seek(interval.interval.start),
                    trailing: _lyricIntervalMenu(session, interval.id),
                  ),
              ],
            );
          },
        ),
      );
    },
  );

  Widget _lyricIntervalMenu(PracticeSession session, String id) =>
      PopupMenuButton<String>(
        tooltip: t.practice.common.editInterval,
        onSelected: (action) {
          switch (action) {
            case 'back':
              session.nudgeLyric(id, const Duration(milliseconds: -100));
            case 'forward':
              session.nudgeLyric(id, const Duration(milliseconds: 100));
            case 'duplicate':
              session.duplicateLyric(id);
            case 'delete':
              session.deleteLyric(id);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'back',
            child: Text(t.practice.common.moveBack),
          ),
          PopupMenuItem(
            value: 'forward',
            child: Text(t.practice.common.moveForward),
          ),
          PopupMenuItem(
            value: 'duplicate',
            child: Text(t.practice.common.duplicate),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(t.practice.common.delete),
          ),
        ],
      );
}

class _TimingEditor extends StatefulWidget {
  const _TimingEditor({
    required this.data,
    required this.session,
    required this.media,
  });
  final PracticeSessionData data;
  final PracticeSession session;
  final MixupMediaController media;

  @override
  State<_TimingEditor> createState() => _TimingEditorState();
}

class _TimingEditorState extends State<_TimingEditor> {
  final _interludeLabel = TextEditingController(
    text: t.practice.lyrics.interlude,
  );

  @override
  void dispose() {
    _interludeLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.data.selectedLyricLine;
    return Card(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.practice.lyrics.editorTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (widget.data.timeline.lyricsNeedReview) ...[
            Text(t.practice.lyrics.relinkRequired),
            if (widget.session.unresolvedLyrics.isEmpty)
              FilledButton.tonal(
                onPressed: widget.session.confirmLyricsWithoutIntervals,
                child: Text(t.practice.lyrics.confirmNoIntervals),
              )
            else
              for (final interval in widget.session.unresolvedLyrics)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(interval.text),
                  subtitle: Text(
                    '${formatTime(interval.interval.start)}–${formatTime(interval.interval.end)}',
                  ),
                  trailing: DropdownButton<int>(
                    hint: Text(t.practice.lyrics.relinkTarget),
                    items: [
                      for (
                        var index = 0;
                        index < widget.data.lyricLines.length;
                        index++
                      )
                        DropdownMenuItem(
                          value: index,
                          child: SizedBox(
                            width: 220,
                            child: Text(
                              widget.data.lyricLines[index],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (index) {
                      if (index != null) {
                        widget.session.relinkLyricInterval(interval.id, index);
                      }
                    },
                  ),
                ),
            const Divider(height: 28),
          ],
          Text(
            selected == null
                ? t.practice.lyrics.selectLine
                : widget.data.lyricLines[selected],
          ),
          const SizedBox(height: 12),
          IntervalForm(
            controller: widget.media,
            submitLabel: t.practice.lyrics.addInterval,
            onSubmit: widget.session.addSelectedLyric,
          ),
          const Divider(height: 28),
          TextField(
            controller: _interludeLabel,
            decoration: InputDecoration(
              labelText: t.practice.lyrics.interludeLabel,
            ),
          ),
          const SizedBox(height: 8),
          IntervalForm(
            controller: widget.media,
            submitLabel: t.practice.lyrics.addInterlude,
            onSubmit: (interval) => widget.session.addInterlude(
              interval,
              _interludeLabel.text.trim().isEmpty
                  ? t.practice.lyrics.interlude
                  : _interludeLabel.text,
            ),
          ),
          if (widget.data.timeline.interludes.isNotEmpty) ...[
            const Divider(height: 28),
            Text(t.practice.lyrics.savedInterludes),
            for (final interlude in widget.data.timeline.interludes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(interlude.label),
                subtitle: Text(
                  '${formatTime(interlude.interval.start)}–${formatTime(interlude.interval.end)}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'duplicate':
                        widget.session.duplicateInterlude(interlude.id);
                      case 'delete':
                        widget.session.deleteInterlude(interlude.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Text(t.practice.common.duplicate),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(t.practice.common.delete),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(t.practice.lyrics.loadFailure(error: error)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(t.practice.common.retry),
            ),
          ],
        ),
      ),
    ),
  );
}
