// This feature-private widget is documented by its constructor contract.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mixup/core/gen/slang.g.dart';
import 'package:mixup/presentation/features/practice/controllers/practice_session.dart';

class PracticeScaffold extends StatelessWidget {
  const PracticeScaffold({
    required this.songId,
    required this.data,
    required this.session,
    required this.currentStep,
    required this.body,
    super.key,
  });

  final String songId;
  final PracticeSessionData data;
  final PracticeSession session;
  final int currentStep;
  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.song.title),
          Text(
            _saveLabel(data.saveStatus),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: t.practice.scaffold.undo,
          onPressed: session.canUndo ? session.undo : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          tooltip: t.practice.scaffold.redo,
          onPressed: session.canRedo ? session.redo : null,
          icon: const Icon(Icons.redo),
        ),
        FilledButton.tonalIcon(
          onPressed: data.saveStatus == PracticeSaveStatus.saving
              ? null
              : session.save,
          icon: const Icon(Icons.save),
          label: Text(t.practice.scaffold.save),
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _step(
              context,
              0,
              Icons.lyrics,
              t.practice.scaffold.timingStep,
              'timing',
            ),
            const SizedBox(width: 8),
            _step(
              context,
              1,
              Icons.graphic_eq,
              t.practice.scaffold.mixStep,
              'mix',
            ),
          ],
        ),
      ),
    ),
    body: Column(
      children: [
        if (data.timeline.lyricsNeedReview)
          MaterialBanner(
            content: Text(t.practice.scaffold.lyricsChanged),
            leading: const Icon(Icons.warning_amber),
            actions: [
              TextButton(
                onPressed: null,
                child: Text(t.practice.scaffold.relinkInEditor),
              ),
            ],
          ),
        if (data.saveError case final error?)
          MaterialBanner(
            content: Text(t.practice.scaffold.saveFailed(error: error)),
            leading: const Icon(Icons.error_outline),
            actions: [
              TextButton(
                onPressed: session.save,
                child: Text(t.practice.common.retry),
              ),
            ],
          ),
        Expanded(child: body),
      ],
    ),
  );

  Widget _step(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    String path,
  ) => index == currentStep
      ? FilledButton.icon(onPressed: null, icon: Icon(icon), label: Text(label))
      : TextButton.icon(
          onPressed: () => context.go('/songs/$songId/$path'),
          icon: Icon(icon),
          label: Text(label),
        );

  String _saveLabel(PracticeSaveStatus status) => switch (status) {
    PracticeSaveStatus.saved => t.practice.scaffold.status.saved,
    PracticeSaveStatus.dirty => t.practice.scaffold.status.dirty,
    PracticeSaveStatus.saving => t.practice.scaffold.status.saving,
    PracticeSaveStatus.failed => t.practice.scaffold.status.failed,
  };
}
