// The app-internal port contract is documented at the interface boundary.
// ignore_for_file: public_member_api_docs

import 'package:mixup/domain/practice/practice_timeline.dart';
import 'package:mixup/domain/songs/song.dart';

/// Persistence and bundle-path operations needed by practice editing.
abstract interface class PracticeTimelineRepository {
  Future<PracticeTimeline> load({
    required Song song,
    required List<String> lyricLines,
  });

  Future<void> save(PracticeTimeline timeline);

  Future<String> resolveAudioPath(Song song);
}
