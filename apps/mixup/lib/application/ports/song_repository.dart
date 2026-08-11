import 'package:mixup/domain/songs/song.dart';

/// Provides songs without exposing their storage format.
// The interface keeps presentation independent of the Markdown adapter.
// ignore: one_member_abstracts
abstract interface class SongRepository {
  /// Returns every song declared by the configured song index.
  Future<List<Song>> findAll();
}
