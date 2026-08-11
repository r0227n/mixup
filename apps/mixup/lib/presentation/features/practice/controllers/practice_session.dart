// The app-internal feature API is documented at its state and controller.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:mixup/domain/mixes/mix.dart';
import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup/domain/songs/song.dart';
import 'package:mixup/presentation/dependencies/content_repositories.dart';
import 'package:mixup_media_player/mixup_media_player.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'practice_session.g.dart';

enum PracticeSaveStatus { saved, dirty, saving, failed }

enum PracticeEditError {
  selectLyric,
  selectMix,
  noData,
  mediaNotReady,
  invalidInterval,
}

final class PracticeSessionData {
  const PracticeSessionData({
    required this.song,
    required this.lyricLines,
    required this.mixes,
    required this.timeline,
    required this.audioPath,
    this.saveStatus = PracticeSaveStatus.saved,
    this.saveError,
    this.selectedLyricLine,
    this.autoPauseAtMix = false,
    this.revision = 0,
  });

  final Song song;
  final List<String> lyricLines;
  final List<Mix> mixes;
  final PracticeTimeline timeline;
  final String audioPath;
  final PracticeSaveStatus saveStatus;
  final String? saveError;
  final int? selectedLyricLine;
  final bool autoPauseAtMix;
  final int revision;

  PracticeSessionData copyWith({
    PracticeTimeline? timeline,
    PracticeSaveStatus? saveStatus,
    String? saveError,
    bool clearSaveError = false,
    int? selectedLyricLine,
    bool clearSelectedLyricLine = false,
    bool? autoPauseAtMix,
    int? revision,
  }) => PracticeSessionData(
    song: song,
    lyricLines: lyricLines,
    mixes: mixes,
    timeline: timeline ?? this.timeline,
    audioPath: audioPath,
    saveStatus: saveStatus ?? this.saveStatus,
    saveError: clearSaveError ? null : saveError ?? this.saveError,
    selectedLyricLine: clearSelectedLyricLine
        ? null
        : selectedLyricLine ?? this.selectedLyricLine,
    autoPauseAtMix: autoPauseAtMix ?? this.autoPauseAtMix,
    revision: revision ?? this.revision,
  );

  PracticeSessionData afterSuccessfulSave({
    required int startedRevision,
    required PracticeTimeline persistedTimeline,
  }) {
    final unchanged = revision == startedRevision;
    return copyWith(
      timeline: unchanged ? persistedTimeline : timeline,
      saveStatus: unchanged
          ? PracticeSaveStatus.saved
          : PracticeSaveStatus.dirty,
      clearSaveError: true,
    );
  }
}

@Riverpod(keepAlive: true)
class PracticeSession extends _$PracticeSession {
  MixupMediaController? _mediaController;
  final List<PracticeTimeline> _undo = [];
  final List<PracticeTimeline> _redo = [];
  Duration _previousPosition = Duration.zero;
  bool _autoPausePending = false;
  PracticeTimeline? _dragOrigin;
  bool _dragChanged = false;

  MixupMediaController? get mediaController => _mediaController;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  List<LyricInterval> get unresolvedLyrics {
    final value = state.value;
    return value == null
        ? const []
        : unresolvedLyricIntervals(value.timeline.lyrics, value.lyricLines);
  }

  @override
  Future<PracticeSessionData> build(String songId) async {
    ref.onDispose(() => _mediaController?.dispose());
    final songs = await ref.watch(songRepositoryProvider).findAll();
    final song = songs.where((item) => _songId(item) == songId).firstOrNull;
    if (song == null) throw StateError('Song "$songId" was not found.');
    final lyricLines = song.lyrics
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    final store = ref.watch(practiceTimelineRepositoryProvider);
    final timeline = await store.load(song: song, lyricLines: lyricLines);
    final audioPath = await store.resolveAudioPath(song);
    final controller = MixupMediaController(
      source: AudioMediaSource(data: FileAudioData(audioPath)),
    );
    _mediaController = controller;
    controller.addListener(_handlePlaybackChange);
    return PracticeSessionData(
      song: song,
      lyricLines: lyricLines,
      mixes: await ref.watch(mixRepositoryProvider).findAll(),
      timeline: timeline,
      audioPath: audioPath,
    );
  }

  void selectLyricLine(int index) {
    final value = state.value;
    if (value == null) return;
    state = AsyncData(value.copyWith(selectedLyricLine: index));
  }

  void setAutoPauseAtMix({required bool enabled}) {
    final value = state.value;
    if (value == null) return;
    state = AsyncData(value.copyWith(autoPauseAtMix: enabled));
  }

  PracticeEditError? addSelectedLyric(PracticeInterval interval) {
    final value = state.value;
    final index = value?.selectedLyricLine;
    if (value == null || index == null) return PracticeEditError.selectLyric;
    final error = _validateInterval(interval);
    if (error != null) return error;
    final lineId = lyricLineId(index);
    final next = LyricInterval(
      id: _newId('lyric'),
      lyricLineId: lineId,
      text: value.lyricLines[index],
      interval: interval,
    );
    _commit(value.timeline.copyWith(lyrics: [...value.timeline.lyrics, next]));
    return null;
  }

  PracticeEditError? addInterlude(PracticeInterval interval, String label) {
    final value = state.value;
    if (value == null) return PracticeEditError.noData;
    final error = _validateInterval(interval);
    if (error != null) return error;
    final next = InterludeInterval(
      id: _newId('interlude'),
      label: label.trim(),
      interval: interval,
    );
    _commit(
      value.timeline.copyWith(interludes: [...value.timeline.interludes, next]),
    );
    return null;
  }

  PracticeEditError? addMix(
    PracticeInterval interval,
    String mixId, {
    String? note,
  }) {
    final value = state.value;
    if (value == null) return PracticeEditError.noData;
    final error = _validateInterval(interval);
    if (error != null) return error;
    final next = MixInterval(
      id: _newId('mix'),
      mixId: mixId,
      interval: interval,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
    );
    _commit(value.timeline.copyWith(mixes: [...value.timeline.mixes, next]));
    return null;
  }

  void deleteLyric(String id) {
    final value = state.value;
    if (value == null) return;
    _commit(
      value.timeline.copyWith(
        lyrics: value.timeline.lyrics.where((item) => item.id != id).toList(),
      ),
    );
  }

  void deleteInterlude(String id) {
    final value = state.value;
    if (value == null) return;
    _commit(
      value.timeline.copyWith(
        interludes: value.timeline.interludes
            .where((item) => item.id != id)
            .toList(),
      ),
    );
  }

  void deleteMix(String id) {
    final value = state.value;
    if (value == null) return;
    _commit(
      value.timeline.copyWith(
        mixes: value.timeline.mixes.where((item) => item.id != id).toList(),
      ),
    );
  }

  /// Rebinds one retained interval after an explicit user choice.
  void relinkLyricInterval(String id, int targetIndex) {
    final value = state.value;
    if (value == null ||
        targetIndex < 0 ||
        targetIndex >= value.lyricLines.length) {
      return;
    }
    final lyrics = [...value.timeline.lyrics];
    final index = lyrics.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final source = lyrics[index];
    lyrics[index] = LyricInterval(
      id: source.id,
      lyricLineId: lyricLineId(targetIndex),
      text: value.lyricLines[targetIndex],
      interval: source.interval,
    );
    final unresolved = unresolvedLyricIntervals(lyrics, value.lyricLines);
    _commit(
      value.timeline.copyWith(
        lyrics: lyrics,
        lyricsFingerprint: unresolved.isEmpty
            ? lyricsFingerprint(value.lyricLines)
            : value.timeline.lyricsFingerprint,
        lyricsNeedReview: unresolved.isNotEmpty,
      ),
    );
  }

  /// Confirms a source update when no saved lyric interval needs remapping.
  void confirmLyricsWithoutIntervals() {
    final value = state.value;
    if (value == null ||
        unresolvedLyricIntervals(
          value.timeline.lyrics,
          value.lyricLines,
        ).isNotEmpty) {
      return;
    }
    _commit(
      value.timeline.copyWith(
        lyricsFingerprint: lyricsFingerprint(value.lyricLines),
        lyricsNeedReview: false,
      ),
    );
  }

  /// Creates another lyric interval with the same source line and timing.
  void duplicateLyric(String id) {
    final value = state.value;
    if (value == null) return;
    final source = value.timeline.lyrics
        .where((item) => item.id == id)
        .firstOrNull;
    if (source == null) return;
    _commit(
      value.timeline.copyWith(
        lyrics: [
          ...value.timeline.lyrics,
          LyricInterval(
            id: _newId('lyric'),
            lyricLineId: source.lyricLineId,
            text: source.text,
            interval: source.interval,
          ),
        ],
      ),
    );
  }

  /// Creates another MIX interval referencing the same canonical MIX.
  void duplicateMix(String id) {
    final value = state.value;
    if (value == null) return;
    final source = value.timeline.mixes
        .where((item) => item.id == id)
        .firstOrNull;
    if (source == null) return;
    _commit(
      value.timeline.copyWith(
        mixes: [
          ...value.timeline.mixes,
          MixInterval(
            id: _newId('mix'),
            mixId: source.mixId,
            interval: source.interval,
            note: source.note,
          ),
        ],
      ),
    );
  }

  /// Creates another interlude with the same label and timing.
  void duplicateInterlude(String id) {
    final value = state.value;
    if (value == null) return;
    final source = value.timeline.interludes
        .where((item) => item.id == id)
        .firstOrNull;
    if (source == null) return;
    _commit(
      value.timeline.copyWith(
        interludes: [
          ...value.timeline.interludes,
          InterludeInterval(
            id: _newId('interlude'),
            label: source.label,
            interval: source.interval,
          ),
        ],
      ),
    );
  }

  /// Begins one undoable timeline drag transaction.
  void beginTimelineDrag() {
    final value = state.value;
    if (value == null || _dragOrigin != null) return;
    _dragOrigin = value.timeline;
    _dragChanged = false;
  }

  /// Completes the current drag as a single undo history entry.
  void endTimelineDrag() {
    final origin = _dragOrigin;
    _dragOrigin = null;
    if (origin == null || !_dragChanged) return;
    _undo.add(origin);
    _redo.clear();
    _dragChanged = false;
    final value = state.value;
    if (value != null) state = AsyncData(value.copyWith());
  }

  /// Moves a lyric interval while preserving its duration.
  PracticeEditError? nudgeLyric(String id, Duration offset) {
    final value = state.value;
    if (value == null) return null;
    final items = [...value.timeline.lyrics];
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return null;
    final moved = _shift(items[index].interval, offset);
    final error = _validateInterval(moved);
    if (error != null) return error;
    items[index] = items[index].copyWith(interval: moved);
    _applyTimeline(value.timeline.copyWith(lyrics: items));
    return null;
  }

  /// Moves a MIX interval while preserving its duration.
  PracticeEditError? nudgeMix(String id, Duration offset) {
    final value = state.value;
    if (value == null) return null;
    final items = [...value.timeline.mixes];
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return null;
    final moved = _shift(items[index].interval, offset);
    final error = _validateInterval(moved);
    if (error != null) return error;
    items[index] = items[index].copyWith(interval: moved);
    _applyTimeline(value.timeline.copyWith(mixes: items));
    return null;
  }

  /// Moves an interlude while preserving its duration.
  PracticeEditError? nudgeInterlude(String id, Duration offset) {
    final value = state.value;
    if (value == null) return null;
    final items = [...value.timeline.interludes];
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return null;
    final moved = _shift(items[index].interval, offset);
    final error = _validateInterval(moved);
    if (error != null) return error;
    items[index] = items[index].copyWith(interval: moved);
    _applyTimeline(value.timeline.copyWith(interludes: items));
    return null;
  }

  void undo() {
    final value = state.value;
    if (value == null || _undo.isEmpty) return;
    _redo.add(value.timeline);
    final timeline = _undo.removeLast();
    state = AsyncData(
      value.copyWith(
        timeline: timeline,
        saveStatus: PracticeSaveStatus.dirty,
        revision: value.revision + 1,
      ),
    );
  }

  void redo() {
    final value = state.value;
    if (value == null || _redo.isEmpty) return;
    _undo.add(value.timeline);
    final timeline = _redo.removeLast();
    state = AsyncData(
      value.copyWith(
        timeline: timeline,
        saveStatus: PracticeSaveStatus.dirty,
        revision: value.revision + 1,
      ),
    );
  }

  Future<void> save() async {
    final value = state.value;
    final controller = _mediaController;
    if (value == null || controller == null) return;
    state = AsyncData(
      value.copyWith(
        saveStatus: PracticeSaveStatus.saving,
        clearSaveError: true,
      ),
    );
    final timeline = value.timeline.copyWith(
      audioDuration: controller.state.duration,
      editedAt: DateTime.now().toUtc(),
    );
    try {
      await ref.read(practiceTimelineRepositoryProvider).save(timeline);
      final current = state.value;
      if (current == null) return;
      state = AsyncData(
        current.afterSuccessfulSave(
          startedRevision: value.revision,
          persistedTimeline: timeline,
        ),
      );
    } on Object catch (error) {
      final current = state.value;
      if (current == null) return;
      state = AsyncData(
        current.copyWith(
          saveStatus: PracticeSaveStatus.failed,
          saveError: error.toString(),
        ),
      );
    }
  }

  PracticeEditError? _validateInterval(PracticeInterval interval) {
    final duration = _mediaController?.state.duration ?? Duration.zero;
    if (duration <= Duration.zero) return PracticeEditError.mediaNotReady;
    if (!interval.isWithin(duration)) {
      return PracticeEditError.invalidInterval;
    }
    return null;
  }

  void _commit(PracticeTimeline timeline) {
    final value = state.value;
    if (value == null) return;
    _undo.add(value.timeline);
    _redo.clear();
    state = AsyncData(
      value.copyWith(
        timeline: timeline,
        saveStatus: PracticeSaveStatus.dirty,
        clearSaveError: true,
        revision: value.revision + 1,
      ),
    );
  }

  void _applyTimeline(PracticeTimeline timeline) {
    final value = state.value;
    if (value == null) return;
    if (_dragOrigin == null) {
      _commit(timeline);
      return;
    }
    _dragChanged = true;
    state = AsyncData(
      value.copyWith(
        timeline: timeline,
        saveStatus: PracticeSaveStatus.dirty,
        clearSaveError: true,
        revision: value.revision + 1,
      ),
    );
  }

  void _handlePlaybackChange() {
    final controller = _mediaController;
    final value = state.value;
    if (controller == null || value == null) return;
    final playback = controller.state;
    final position = playback.position;
    if (value.autoPauseAtMix && playback.isPlaying && !_autoPausePending) {
      final entered = value.timeline.mixes.any(
        (item) =>
            _previousPosition < item.interval.start &&
            position >= item.interval.start &&
            position < item.interval.end,
      );
      if (entered) {
        _autoPausePending = true;
        unawaited(
          controller.pause().whenComplete(() => _autoPausePending = false),
        );
      }
    }
    _previousPosition = position;
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  PracticeInterval _shift(PracticeInterval interval, Duration offset) =>
      PracticeInterval(
        start: interval.start + offset,
        end: interval.end + offset,
      );

  String _songId(Song song) =>
      song.sourcePath.replaceAll(r'\', '/').split('/').reversed.skip(1).first;
}
