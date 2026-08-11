// This feature-private widget is documented by its constructor contract.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:mixup/core/gen/slang.g.dart';
import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup/presentation/features/practice/controllers/practice_session.dart';
import 'package:mixup/presentation/features/practice/widgets/practice_error_text.dart';
import 'package:mixup_media_player/mixup_media_player.dart';

class IntervalForm extends StatefulWidget {
  const IntervalForm({
    required this.controller,
    required this.onSubmit,
    required this.submitLabel,
    this.initialStart,
    this.initialEnd,
    this.extra,
    super.key,
  });

  final MixupMediaController controller;
  final PracticeEditError? Function(PracticeInterval interval) onSubmit;
  final String submitLabel;
  final Duration? initialStart;
  final Duration? initialEnd;
  final Widget? extra;

  @override
  State<IntervalForm> createState() => _IntervalFormState();
}

class _IntervalFormState extends State<IntervalForm> {
  late final TextEditingController _start = TextEditingController(
    text: _seconds(widget.initialStart ?? Duration.zero),
  );
  late final TextEditingController _end = TextEditingController(
    text: _seconds(widget.initialEnd ?? Duration.zero),
  );

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: _timeField(_start, t.practice.intervalForm.startSeconds),
          ),
          IconButton(
            tooltip: t.practice.intervalForm.setCurrentStart,
            onPressed: () =>
                _start.text = _seconds(widget.controller.state.position),
            icon: const Icon(Icons.my_location),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _timeField(_end, t.practice.intervalForm.endSeconds),
          ),
          IconButton(
            tooltip: t.practice.intervalForm.setCurrentEnd,
            onPressed: () =>
                _end.text = _seconds(widget.controller.state.position),
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      if (widget.extra case final extra?) ...[
        const SizedBox(height: 12),
        extra,
      ],
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.add),
        label: Text(widget.submitLabel),
      ),
    ],
  );

  Widget _timeField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );

  void _submit() {
    final start = double.tryParse(_start.text);
    final end = double.tryParse(_end.text);
    final error = start == null || end == null
        ? null
        : widget.onSubmit(
            PracticeInterval(
              start: Duration(milliseconds: (start * 1000).round()),
              end: Duration(milliseconds: (end * 1000).round()),
            ),
          );
    final message = start == null || end == null
        ? t.practice.errors.invalidTime
        : error == null
        ? null
        : practiceEditErrorText(error);
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _seconds(Duration value) =>
      (value.inMilliseconds / 1000).toStringAsFixed(2);
}
