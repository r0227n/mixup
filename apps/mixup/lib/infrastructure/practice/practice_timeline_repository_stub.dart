// The browser fallback is an app-internal conditional implementation.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:mixup/application/ports/practice_timeline_repository.dart';
import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup/domain/songs/song.dart';

/// Browser fallback until a user-selected writable bundle is available.
final class JsonPracticeTimelineRepository
    implements PracticeTimelineRepository {
  JsonPracticeTimelineRepository(FutureOr<String> _);

  Never _unsupported() => throw UnsupportedError(
    'Local song bundles are unavailable on Web. Open this editor on desktop.',
  );

  @override
  Future<PracticeTimeline> load({
    required Song song,
    required List<String> lyricLines,
  }) async => _unsupported();

  @override
  Future<String> resolveAudioPath(Song song) async => _unsupported();

  @override
  Future<void> save(PracticeTimeline timeline) async => _unsupported();
}
