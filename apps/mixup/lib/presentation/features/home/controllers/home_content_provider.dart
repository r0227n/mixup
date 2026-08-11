import 'package:mixup/domain/mixes/mix.dart';
import 'package:mixup/domain/songs/song.dart';
import 'package:mixup/presentation/dependencies/content_repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_content_provider.g.dart';

/// Debug content shown on the temporary home screen.
class HomeContent {
  /// Creates home content.
  const HomeContent({required this.songs, required this.mixes});

  /// Repository-backed songs.
  final List<Song> songs;

  /// Repository-backed MIX calls.
  final List<Mix> mixes;
}

/// Loads both debug lists outside the widget build method.
@riverpod
Future<HomeContent> homeContent(Ref ref) async {
  final songRepository = ref.watch(songRepositoryProvider);
  final mixRepository = ref.watch(mixRepositoryProvider);
  final songs = songRepository.findAll();
  final mixes = mixRepository.findAll();
  return HomeContent(
    songs: await songs,
    mixes: await mixes,
  );
}
