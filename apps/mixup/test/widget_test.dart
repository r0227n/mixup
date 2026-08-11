import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixup/application/ports/mix_repository.dart';
import 'package:mixup/application/ports/song_repository.dart';
import 'package:mixup/core/logger/talker.dart';
import 'package:mixup/domain/mixes/mix.dart';
import 'package:mixup/domain/songs/song.dart';
import 'package:mixup/main.dart';
import 'package:mixup/presentation/dependencies/content_repositories.dart';

void main() {
  testWidgets('shows repository-backed songs and MIX calls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          talkerProvider.overrideWithValue(createTalker()),
          songRepositoryProvider.overrideWith((ref) => _SongRepository()),
          mixRepositoryProvider.overrideWith((ref) => _MixRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('楽曲 (1)'), findsOneWidget);
    expect(find.text('Test song'), findsOneWidget);
    expect(find.text('MIX (1)'), findsOneWidget);
    expect(find.text('Test mix'), findsOneWidget);
  });

  testWidgets('shows the practice entry point for a repository song', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          talkerProvider.overrideWithValue(createTalker()),
          songRepositoryProvider.overrideWith((ref) => _SongRepository()),
          mixRepositoryProvider.overrideWith((ref) => _MixRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test song'), findsOneWidget);
    expect(find.text('utage/lyrics.md'), findsOneWidget);
  });
}

class _SongRepository implements SongRepository {
  @override
  Future<List<Song>> findAll() async => const [
    Song(
      title: 'Test song',
      lyrics: 'UtaGe! test lyrics',
      sourcePath: 'utage/lyrics.md',
    ),
  ];
}

class _MixRepository implements MixRepository {
  @override
  Future<List<Mix>> findAll() async => const [
    Mix(title: 'Test mix', bars: 8, call: 'call', sourcePath: 'mix.md'),
  ];
}
