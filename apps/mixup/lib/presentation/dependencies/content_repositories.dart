import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mixup/application/ports/mix_repository.dart';
import 'package:mixup/application/ports/song_repository.dart';
import 'package:mixup/core/logger/talker.dart';
import 'package:mixup/infrastructure/content/content_settings.dart';
import 'package:mixup/infrastructure/mixes/markdown_mix_repository.dart';
import 'package:mixup/infrastructure/observability/talker_okf_read_observer.dart';
import 'package:mixup/infrastructure/songs/markdown_song_repository.dart';
import 'package:okf_repository/okf_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_repositories.g.dart';

/// Loads the configured content paths from the bundled settings asset.
@Riverpod(keepAlive: true)
Future<ContentSettings> contentSettings(Ref ref) async =>
    ContentSettings.fromJson(
      await rootBundle.loadString('assets/settings.json'),
    );

/// Creates the OKF reader shared by the content repositories.
@Riverpod(keepAlive: true)
OkfRepository okfRepository(Ref ref) {
  if (kIsWeb) {
    throw UnsupportedError(
      'Repository content stored in local files is unavailable on Web.',
    );
  }
  return LocalOkfRepository(
    observer: TalkerOkfReadObserver(ref.watch(talkerProvider)).call,
  );
}

/// Creates the repository that reads configured song content.
@Riverpod(keepAlive: true)
SongRepository songRepository(Ref ref) => MarkdownSongRepository(
  ref.watch(okfRepositoryProvider),
  ref.watch(contentSettingsProvider.future).then((value) => value.songsPath),
);

/// Creates the repository that reads configured MIX content.
@Riverpod(keepAlive: true)
MixRepository mixRepository(Ref ref) => MarkdownMixRepository(
  ref.watch(okfRepositoryProvider),
  ref.watch(contentSettingsProvider.future).then((value) => value.mixesPath),
);
