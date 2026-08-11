import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mixup/infrastructure/content/content_settings.dart';
import 'package:mixup/infrastructure/mixes/markdown_mix_repository.dart';
import 'package:mixup/infrastructure/observability/talker_okf_read_observer.dart';
import 'package:mixup/infrastructure/songs/markdown_song_repository.dart';
import 'package:okf_repository/okf_repository.dart';
import 'package:talker/talker.dart';

void main() {
  test('loads repository Markdown and logs every completed read', () async {
    final settings = ContentSettings.fromJson(
      File('assets/settings.json').readAsStringSync(),
    );
    final talker = Talker(
      settings: TalkerSettings(useConsoleLogs: false),
    );
    final content = LocalOkfRepository(
      observer: TalkerOkfReadObserver(talker).call,
    );

    final songs = await MarkdownSongRepository(
      content,
      settings.songsPath,
    ).findAll();
    final mixes = await MarkdownMixRepository(
      content,
      settings.mixesPath,
    ).findAll();

    expect(songs, isNotEmpty);
    expect(songs.every((song) => song.lyrics.isNotEmpty), isTrue);
    expect(mixes, isNotEmpty);
    expect(mixes.every((mix) => mix.bars > 0), isTrue);

    final messages = talker.history
        .map((event) => event.message ?? '')
        .toList();
    final startedReads = messages
        .where((message) => message.startsWith('Content read started:'))
        .length;
    final completedReads = messages
        .where((message) => message.startsWith('Content read completed:'))
        .length;
    expect(startedReads, greaterThanOrEqualTo(2 + songs.length + mixes.length));
    expect(completedReads, startedReads);
    expect(
      messages.where((message) => message.startsWith('Content read failed:')),
      isEmpty,
    );
  });
}
