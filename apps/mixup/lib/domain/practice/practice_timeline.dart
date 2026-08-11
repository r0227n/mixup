// App-internal domain members are documented at their aggregate boundaries.
// ignore_for_file: public_member_api_docs

/// Current JSON format written to `practice-timeline.json`.
const practiceTimelineFormatVersion = 1;

/// A half-open playable interval where start is strictly before end.
final class PracticeInterval {
  const PracticeInterval({required this.start, required this.end});

  final Duration start;
  final Duration end;

  bool get isValid => !start.isNegative && start < end;

  bool isWithin(Duration duration) =>
      isValid && duration > Duration.zero && end <= duration;

  bool contains(Duration position) => position >= start && position < end;

  bool overlaps(PracticeInterval other) =>
      start < other.end && other.start < end;
}

/// A lyric line synchronized to the reference audio.
final class LyricInterval {
  const LyricInterval({
    required this.id,
    required this.lyricLineId,
    required this.text,
    required this.interval,
  });

  final String id;
  final String lyricLineId;
  final String text;
  final PracticeInterval interval;

  LyricInterval copyWith({PracticeInterval? interval}) => LyricInterval(
    id: id,
    lyricLineId: lyricLineId,
    text: text,
    interval: interval ?? this.interval,
  );
}

/// A timed instrumental or other lyric-free practice interval.
final class InterludeInterval {
  const InterludeInterval({
    required this.id,
    required this.label,
    required this.interval,
  });

  final String id;
  final String label;
  final PracticeInterval interval;

  InterludeInterval copyWith({String? label, PracticeInterval? interval}) =>
      InterludeInterval(
        id: id,
        label: label ?? this.label,
        interval: interval ?? this.interval,
      );
}

/// A MIX reference placed on an arbitrary playable interval.
final class MixInterval {
  const MixInterval({
    required this.id,
    required this.mixId,
    required this.interval,
    this.note,
  });

  final String id;
  final String mixId;
  final PracticeInterval interval;
  final String? note;

  MixInterval copyWith({PracticeInterval? interval, String? note}) =>
      MixInterval(
        id: id,
        mixId: mixId,
        interval: interval ?? this.interval,
        note: note ?? this.note,
      );
}

/// Editable and persistable practice data for one song bundle.
final class PracticeTimeline {
  const PracticeTimeline({
    required this.songId,
    required this.audioRelativePath,
    required this.audioDuration,
    required this.lyricsFingerprint,
    required this.editedAt,
    this.formatVersion = practiceTimelineFormatVersion,
    this.lyricsNeedReview = false,
    this.lyrics = const [],
    this.interludes = const [],
    this.mixes = const [],
  });

  final int formatVersion;
  final String songId;
  final String audioRelativePath;
  final Duration audioDuration;
  final String lyricsFingerprint;
  final DateTime editedAt;
  final bool lyricsNeedReview;
  final List<LyricInterval> lyrics;
  final List<InterludeInterval> interludes;
  final List<MixInterval> mixes;

  PracticeTimeline copyWith({
    Duration? audioDuration,
    String? lyricsFingerprint,
    DateTime? editedAt,
    bool? lyricsNeedReview,
    List<LyricInterval>? lyrics,
    List<InterludeInterval>? interludes,
    List<MixInterval>? mixes,
  }) => PracticeTimeline(
    formatVersion: formatVersion,
    songId: songId,
    audioRelativePath: audioRelativePath,
    audioDuration: audioDuration ?? this.audioDuration,
    lyricsFingerprint: lyricsFingerprint ?? this.lyricsFingerprint,
    editedAt: editedAt ?? this.editedAt,
    lyricsNeedReview: lyricsNeedReview ?? this.lyricsNeedReview,
    lyrics: lyrics ?? this.lyrics,
    interludes: interludes ?? this.interludes,
    mixes: mixes ?? this.mixes,
  );
}

/// Stable source ID based on the Markdown lyric-line order.
String lyricLineId(int zeroBasedIndex) =>
    'line-${(zeroBasedIndex + 1).toString().padLeft(4, '0')}';

int? lyricLineIndex(String id) {
  final value = int.tryParse(id.replaceFirst('line-', ''));
  return value == null ? null : value - 1;
}

bool lyricIntervalMatchesSource(LyricInterval interval, List<String> lines) {
  final index = lyricLineIndex(interval.lyricLineId);
  return index != null &&
      index >= 0 &&
      index < lines.length &&
      lines[index] == interval.text;
}

List<LyricInterval> unresolvedLyricIntervals(
  List<LyricInterval> intervals,
  List<String> lines,
) => intervals
    .where((interval) => !lyricIntervalMatchesSource(interval, lines))
    .toList(growable: false);

/// A deterministic fingerprint used to detect source lyric changes.
String lyricsFingerprint(Iterable<String> lines) {
  var hash = 0x811c9dc5;
  for (final unit in lines.join('\n').codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
