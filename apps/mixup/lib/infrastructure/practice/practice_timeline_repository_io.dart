// Async filesystem calls keep timeline persistence off the UI isolate.
// ignore_for_file: avoid_slow_async_io, public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mixup/application/ports/practice_timeline_repository.dart';
import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup/domain/songs/song.dart';

/// Stores practice edits beside a song's immutable `lyrics.md`.
final class JsonPracticeTimelineRepository
    implements PracticeTimelineRepository {
  JsonPracticeTimelineRepository(FutureOr<String> songsRoot)
    : _songsRoot = Future.value(songsRoot);

  final Future<String> _songsRoot;

  @override
  Future<PracticeTimeline> load({
    required Song song,
    required List<String> lyricLines,
  }) async {
    final songId = _songId(song);
    final fingerprint = lyricsFingerprint(lyricLines);
    final file = File(await _timelinePath(songId));
    if (!await file.exists()) {
      return PracticeTimeline(
        songId: songId,
        audioRelativePath: _audioRelativePath(song),
        audioDuration: Duration.zero,
        lyricsFingerprint: fingerprint,
        editedAt: DateTime.now().toUtc(),
      );
    }
    final json = jsonDecode(await file.readAsString());
    if (json is! Map<String, Object?>) {
      throw const FormatException('practice-timeline.json must be an object.');
    }
    final timeline = _decode(json);
    return timeline.copyWith(
      lyricsNeedReview: timeline.lyricsFingerprint != fingerprint,
    );
  }

  @override
  Future<void> save(PracticeTimeline timeline) async {
    _validate(timeline);
    final target = File(await _timelinePath(timeline.songId));
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(_encode(timeline))}\n',
        flush: true,
      );
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  Future<String> resolveAudioPath(Song song) async {
    final root = await _songsRoot;
    return '$root/${_songId(song)}/${_audioRelativePath(song)}';
  }

  Future<String> _timelinePath(String songId) async =>
      '${await _songsRoot}/$songId/practice-timeline.json';

  String _songId(Song song) {
    final parts = song.sourcePath.replaceAll(r'\', '/').split('/');
    if (parts.length < 2 || parts.last != 'lyrics.md') {
      throw FormatException('Invalid song source path: ${song.sourcePath}');
    }
    return parts[parts.length - 2];
  }

  String _audioRelativePath(Song song) {
    final path = song.audioPath;
    if (path == null ||
        path.isEmpty ||
        path.startsWith('/') ||
        path.contains('..')) {
      throw FormatException('Invalid audio path in ${song.sourcePath}.');
    }
    return path.replaceAll(r'\', '/');
  }

  Map<String, Object?> _encode(PracticeTimeline value) => {
    'version': value.formatVersion,
    'songId': value.songId,
    'audio': {
      'path': value.audioRelativePath,
      'durationMs': value.audioDuration.inMilliseconds,
    },
    'lyricsFingerprint': value.lyricsFingerprint,
    'editedAt': value.editedAt.toUtc().toIso8601String(),
    'lyricIntervals': [
      for (final item in value.lyrics)
        {
          'id': item.id,
          'lyricId': item.lyricLineId,
          'text': item.text,
          ..._encodeInterval(item.interval),
        },
    ],
    'interludes': [
      for (final item in value.interludes)
        {
          'id': item.id,
          'label': item.label,
          ..._encodeInterval(item.interval),
        },
    ],
    'mixIntervals': [
      for (final item in value.mixes)
        {
          'id': item.id,
          'mixId': item.mixId,
          'note': ?item.note,
          ..._encodeInterval(item.interval),
        },
    ],
  };

  Map<String, int> _encodeInterval(PracticeInterval value) => {
    'startMs': value.start.inMilliseconds,
    'endMs': value.end.inMilliseconds,
  };

  PracticeTimeline _decode(Map<String, Object?> json) {
    final version = _integer(json, 'version');
    if (version != practiceTimelineFormatVersion) {
      throw FormatException('Unsupported practice timeline version: $version');
    }
    final audio = _map(json, 'audio');
    return PracticeTimeline(
      formatVersion: version,
      songId: _string(json, 'songId'),
      audioRelativePath: _string(audio, 'path'),
      audioDuration: Duration(milliseconds: _integer(audio, 'durationMs')),
      lyricsFingerprint: _string(json, 'lyricsFingerprint'),
      editedAt: DateTime.parse(_string(json, 'editedAt')),
      lyrics: [
        for (final value in _list(json, 'lyricIntervals'))
          LyricInterval(
            id: _string(value, 'id'),
            lyricLineId: _string(value, 'lyricId'),
            text: _string(value, 'text'),
            interval: _decodeInterval(value),
          ),
      ],
      interludes: [
        for (final value in _list(json, 'interludes'))
          InterludeInterval(
            id: _string(value, 'id'),
            label: _string(value, 'label'),
            interval: _decodeInterval(value),
          ),
      ],
      mixes: [
        for (final value in _list(json, 'mixIntervals'))
          MixInterval(
            id: _string(value, 'id'),
            mixId: _string(value, 'mixId'),
            note: value['note'] as String?,
            interval: _decodeInterval(value),
          ),
      ],
    );
  }

  PracticeInterval _decodeInterval(Map<String, Object?> value) =>
      PracticeInterval(
        start: Duration(milliseconds: _integer(value, 'startMs')),
        end: Duration(milliseconds: _integer(value, 'endMs')),
      );

  void _validate(PracticeTimeline timeline) {
    if (timeline.audioDuration <= Duration.zero) {
      throw const FormatException(
        'Audio duration must be known before saving.',
      );
    }
    final intervals = <PracticeInterval>[
      ...timeline.lyrics.map((item) => item.interval),
      ...timeline.interludes.map((item) => item.interval),
      ...timeline.mixes.map((item) => item.interval),
    ];
    if (intervals.any((item) => !item.isWithin(timeline.audioDuration))) {
      throw const FormatException('Every interval must be within the audio.');
    }
  }

  Map<String, Object?> _map(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is Map<String, Object?>) return value;
    throw FormatException('$key must be an object.');
  }

  List<Map<String, Object?>> _list(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List<Object?>) throw FormatException('$key must be a list.');
    return [
      for (final item in value)
        if (item is Map<String, Object?>)
          item
        else
          throw FormatException('$key contains a non-object value.'),
    ];
  }

  String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('$key must be a string.');
  }

  int _integer(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('$key must be an integer.');
  }
}
