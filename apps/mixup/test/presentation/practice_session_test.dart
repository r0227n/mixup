import 'package:flutter_test/flutter_test.dart';
import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup/domain/songs/song.dart';
import 'package:mixup/presentation/features/practice/controllers/practice_session.dart';

void main() {
  final original = PracticeTimeline(
    songId: 'song',
    audioRelativePath: 'audio/reference.mp3',
    audioDuration: const Duration(seconds: 20),
    lyricsFingerprint: 'old',
    editedAt: DateTime.utc(2026, 8, 11),
  );
  const song = Song(
    title: 'Song',
    lyrics: 'A\nB',
    sourcePath: 'song/lyrics.md',
    audioPath: 'audio/reference.mp3',
  );

  test('save completion retains edits made after the save started', () {
    final edited = original.copyWith(
      interludes: const [
        InterludeInterval(
          id: 'new',
          label: 'interlude',
          interval: PracticeInterval(
            start: Duration(seconds: 1),
            end: Duration(seconds: 2),
          ),
        ),
      ],
    );
    final current = PracticeSessionData(
      song: song,
      lyricLines: const ['A', 'B'],
      mixes: const [],
      timeline: edited,
      audioPath: '/audio/reference.mp3',
      saveStatus: PracticeSaveStatus.saving,
      revision: 2,
    );

    final completed = current.afterSuccessfulSave(
      startedRevision: 1,
      persistedTimeline: original,
    );

    expect(identical(completed.timeline, edited), isTrue);
    expect(completed.saveStatus, PracticeSaveStatus.dirty);
  });

  test('save completion marks an unchanged draft as saved', () {
    final current = PracticeSessionData(
      song: song,
      lyricLines: const ['A', 'B'],
      mixes: const [],
      timeline: original,
      audioPath: '/audio/reference.mp3',
      saveStatus: PracticeSaveStatus.saving,
      revision: 1,
    );
    final persisted = original.copyWith(editedAt: DateTime.utc(2026, 8, 12));

    final completed = current.afterSuccessfulSave(
      startedRevision: 1,
      persistedTimeline: persisted,
    );

    expect(identical(completed.timeline, persisted), isTrue);
    expect(completed.saveStatus, PracticeSaveStatus.saved);
  });

  test('line insertion leaves old index-based lyric binding unresolved', () {
    const interval = LyricInterval(
      id: 'lyric-1',
      lyricLineId: 'line-0002',
      text: 'B',
      interval: PracticeInterval(
        start: Duration(seconds: 1),
        end: Duration(seconds: 2),
      ),
    );

    expect(
      unresolvedLyricIntervals(const [interval], const ['X', 'A', 'B']),
      const [interval],
    );
    expect(
      unresolvedLyricIntervals(
        const [
          LyricInterval(
            id: 'lyric-1',
            lyricLineId: 'line-0003',
            text: 'B',
            interval: PracticeInterval(
              start: Duration(seconds: 1),
              end: Duration(seconds: 2),
            ),
          ),
        ],
        const ['X', 'A', 'B'],
      ),
      isEmpty,
    );
  });
}
