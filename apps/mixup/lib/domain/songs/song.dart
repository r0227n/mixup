import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';

/// A song and its repository-backed lyrics metadata.
@freezed
abstract class Song with _$Song {
  /// Creates a song.
  const factory Song({
    required String title,
    required String lyrics,
    required String sourcePath,
    String? audioPath,
  }) = _Song;
}
