import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup/domain/songs/song.dart';
import 'package:mixup/infrastructure/practice/practice_timeline_repository.dart';

void main() {
  late Directory temporaryDirectory;
  late JsonPracticeTimelineRepository repository;
  const song = Song(
    title: 'Song',
    lyrics: 'first\n\nsecond',
    sourcePath: 'song/lyrics.md',
    audioPath: 'audio/reference.mp3',
  );

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync('timeline_');
    repository = JsonPracticeTimelineRepository(temporaryDirectory.path);
  });

  tearDown(() => temporaryDirectory.deleteSync(recursive: true));

  test('atomically saves and loads all practice interval kinds', () async {
    final timeline = PracticeTimeline(
      songId: 'song',
      audioRelativePath: 'audio/reference.mp3',
      audioDuration: const Duration(seconds: 20),
      lyricsFingerprint: lyricsFingerprint(const ['first', 'second']),
      editedAt: DateTime.utc(2026, 8, 11),
      lyrics: const [
        LyricInterval(
          id: 'lyric-1',
          lyricLineId: 'line-0001',
          text: 'first',
          interval: PracticeInterval(
            start: Duration(seconds: 1),
            end: Duration(seconds: 3),
          ),
        ),
      ],
      interludes: const [
        InterludeInterval(
          id: 'interlude-1',
          label: '間奏',
          interval: PracticeInterval(
            start: Duration(seconds: 4),
            end: Duration(seconds: 8),
          ),
        ),
      ],
      mixes: const [
        MixInterval(
          id: 'mix-1',
          mixId: '8/example.md',
          note: 'compare',
          interval: PracticeInterval(
            start: Duration(seconds: 2),
            end: Duration(seconds: 7),
          ),
        ),
      ],
    );

    await repository.save(timeline);
    final loaded = await repository.load(
      song: song,
      lyricLines: const ['first', 'second'],
    );

    expect(loaded.lyrics.single.text, 'first');
    expect(loaded.interludes.single.label, '間奏');
    expect(loaded.mixes.single.mixId, '8/example.md');
    expect(loaded.lyricsNeedReview, isFalse);
    expect(
      File(
        '${temporaryDirectory.path}/song/practice-timeline.json.tmp',
      ).existsSync(),
      isFalse,
    );
  });

  test('retains intervals and requests review after lyrics change', () async {
    final timeline = PracticeTimeline(
      songId: 'song',
      audioRelativePath: 'audio/reference.mp3',
      audioDuration: const Duration(seconds: 10),
      lyricsFingerprint: lyricsFingerprint(const ['old']),
      editedAt: DateTime.utc(2026, 8, 11),
      lyrics: const [
        LyricInterval(
          id: 'lyric-1',
          lyricLineId: 'line-0001',
          text: 'old',
          interval: PracticeInterval(
            start: Duration(seconds: 1),
            end: Duration(seconds: 2),
          ),
        ),
      ],
    );
    await repository.save(timeline);

    final loaded = await repository.load(
      song: song,
      lyricLines: const ['new'],
    );

    expect(loaded.lyricsNeedReview, isTrue);
    expect(loaded.lyrics.single.text, 'old');
  });

  test('rejects intervals outside the audio duration', () async {
    final timeline = PracticeTimeline(
      songId: 'song',
      audioRelativePath: 'audio/reference.mp3',
      audioDuration: const Duration(seconds: 2),
      lyricsFingerprint: 'fingerprint',
      editedAt: DateTime.utc(2026, 8, 11),
      interludes: const [
        InterludeInterval(
          id: 'bad',
          label: 'bad',
          interval: PracticeInterval(
            start: Duration(seconds: 1),
            end: Duration(seconds: 3),
          ),
        ),
      ],
    );

    await expectLater(repository.save(timeline), throwsFormatException);
    expect(
      File(
        '${temporaryDirectory.path}/song/practice-timeline.json',
      ).existsSync(),
      isFalse,
    );
  });
}
