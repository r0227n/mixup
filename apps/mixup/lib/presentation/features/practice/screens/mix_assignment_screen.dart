// Feature-private UI favors readable Japanese strings over member API docs.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixup/core/gen/slang.g.dart';
import 'package:mixup/domain/mixes/mix.dart';
import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup/presentation/features/practice/controllers/practice_session.dart';
import 'package:mixup/presentation/features/practice/widgets/interval_form.dart';
import 'package:mixup/presentation/features/practice/widgets/practice_player.dart';
import 'package:mixup/presentation/features/practice/widgets/practice_scaffold.dart';
import 'package:mixup/presentation/features/practice/widgets/practice_timeline_view.dart';
import 'package:mixup_media_player/mixup_media_player.dart';

class MixAssignmentScreen extends ConsumerWidget {
  const MixAssignmentScreen({required this.songId, super.key});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(practiceSessionProvider(songId));
    return sessionState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(practiceSessionProvider(songId)),
            child: Text(t.practice.mix.loadFailure(error: error)),
          ),
        ),
      ),
      data: (data) {
        final session = ref.read(practiceSessionProvider(songId).notifier);
        return PracticeScaffold(
          songId: songId,
          data: data,
          session: session,
          currentStep: 1,
          body: _MixContent(
            data: data,
            session: session,
            media: session.mediaController!,
          ),
        );
      },
    );
  }
}

class _MixContent extends StatefulWidget {
  const _MixContent({
    required this.data,
    required this.session,
    required this.media,
  });
  final PracticeSessionData data;
  final PracticeSession session;
  final MixupMediaController media;

  @override
  State<_MixContent> createState() => _MixContentState();
}

class _MixContentState extends State<_MixContent> {
  String _query = '';
  Mix? _selectedMix;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.data.mixes.where((mix) {
      final query = _query.toLowerCase();
      return mix.title.toLowerCase().contains(query) ||
          mix.call.toLowerCase().contains(query) ||
          mix.bars.toString() == query;
    }).toList();
    final list = Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: t.practice.mix.search,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final mix = filtered[index];
                return ListTile(
                  selected: _selectedMix?.sourcePath == mix.sourcePath,
                  title: Text(mix.title),
                  subtitle: Text(
                    t.practice.mix.barsAndCall(
                      bars: mix.bars,
                      call: mix.call,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => setState(() => _selectedMix = mix),
                );
              },
            ),
          ),
        ],
      ),
    );
    final editor = Card(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.practice.mix.editorTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_selectedMix case final mix?) ...[
            Text(mix.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            SelectableText(mix.call),
          ] else
            Text(t.practice.mix.selectFromList),
          const SizedBox(height: 12),
          IntervalForm(
            controller: widget.media,
            submitLabel: t.practice.mix.assign,
            extra: TextField(
              controller: _note,
              decoration: InputDecoration(labelText: t.practice.mix.note),
              maxLines: 2,
            ),
            onSubmit: (interval) {
              final mix = _selectedMix;
              if (mix == null) return PracticeEditError.selectMix;
              return widget.session.addMix(
                interval,
                mix.sourcePath,
                note: _note.text,
              );
            },
          ),
          const Divider(height: 28),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.practice.mix.autoPause),
            value: widget.data.autoPauseAtMix,
            onChanged: (enabled) =>
                widget.session.setAutoPauseAtMix(enabled: enabled),
          ),
          Text(
            t.practice.mix.assignedCount(
              count: widget.data.timeline.mixes.length,
            ),
          ),
          for (final item in widget.data.timeline.mixes)
            _AssignedMixTile(
              item: item,
              data: widget.data,
              session: widget.session,
            ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          PracticePlayer(controller: widget.media),
          PracticeTimelineView(
            timeline: widget.data.timeline,
            controller: widget.media,
            onMoveLyric: widget.session.nudgeLyric,
            onMoveInterlude: widget.session.nudgeInterlude,
            onMoveMix: widget.session.nudgeMix,
            onDragStart: widget.session.beginTimelineDrag,
            onDragEnd: widget.session.endTimelineDrag,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 900
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: list),
                        const SizedBox(width: 12),
                        SizedBox(width: 400, child: editor),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: list),
                        const Divider(),
                        SizedBox(height: 330, child: editor),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedMixTile extends StatelessWidget {
  const _AssignedMixTile({
    required this.item,
    required this.data,
    required this.session,
  });
  final MixInterval item;
  final PracticeSessionData data;
  final PracticeSession session;

  @override
  Widget build(BuildContext context) {
    final mix = data.mixes
        .where((candidate) => candidate.sourcePath == item.mixId)
        .firstOrNull;
    final overlaps = data.timeline.lyrics
        .where((lyric) => lyric.interval.overlaps(item.interval))
        .map((lyric) => lyric.text)
        .join(' / ');
    final label = overlaps.isEmpty
        ? t.practice.mix.betweenLyrics
        : t.practice.mix.duringLyrics(lyrics: overlaps);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        mix?.title ?? t.practice.mix.missingReference(mixId: item.mixId),
      ),
      subtitle: Text(
        '${_time(item.interval.start)}–${_time(item.interval.end)} · $label${item.note == null ? '' : '\n${item.note}'}',
      ),
      isThreeLine: item.note != null,
      trailing: PopupMenuButton<String>(
        tooltip: t.practice.common.editInterval,
        onSelected: (action) {
          switch (action) {
            case 'back':
              session.nudgeMix(item.id, const Duration(milliseconds: -100));
            case 'forward':
              session.nudgeMix(item.id, const Duration(milliseconds: 100));
            case 'duplicate':
              session.duplicateMix(item.id);
            case 'delete':
              session.deleteMix(item.id);
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
      ),
    );
  }

  String _time(Duration value) =>
      (value.inMilliseconds / 1000).toStringAsFixed(2);
}
