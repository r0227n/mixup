import 'package:flutter_test/flutter_test.dart';
import 'package:mixup/infrastructure/mixes/markdown_mix_repository.dart';
import 'package:mixup/infrastructure/songs/markdown_song_repository.dart';
import 'package:okf_repository/okf_repository.dart';

void main() {
  test('song repository follows the song index and parses lyrics', () async {
    final content = _MemoryOkfRepository({
      'index.md': '- [Song](one/lyrics.md)',
      'one/lyrics.md': '''
---
type: Song Lyrics
title: "Song One"
audio: audio/one.mp3
---

# 歌詞

la la la
''',
    });

    final songs = await MarkdownSongRepository(content, 'songs').findAll();

    expect(songs, hasLength(1));
    expect(songs.single.title, 'Song One');
    expect(songs.single.lyrics, 'la la la');
    expect(songs.single.audioPath, 'audio/one.mp3');
  });

  test('mix repository follows bar indexes and parses call text', () async {
    final content = _MemoryOkfRepository({
      'index.md': '- [8小節](8/) - one',
      '8/index.md': '- [混沌](8_konton.md)',
      '8/8_konton.md': '''
---
type: Idol Live MIX
title: "混沌mix"
bars: 8
---

# コール

```text
ワールドカオス！
```
''',
    });

    final mixes = await MarkdownMixRepository(content, 'mixs').findAll();

    expect(mixes, hasLength(1));
    expect(mixes.single.title, '混沌mix');
    expect(mixes.single.bars, 8);
    expect(mixes.single.call, 'ワールドカオス！');
  });

  test('mix repository rejects invalid metadata', () async {
    final content = _MemoryOkfRepository({
      'index.md': '- [8小節](8/)',
      '8/index.md': '- [broken](broken.md)',
      '8/broken.md': '# コール\nbroken',
    });

    expect(
      MarkdownMixRepository(content, 'mixs').findAll,
      throwsA(isA<FormatException>()),
    );
  });
}

class _MemoryOkfRepository implements OkfRepository {
  _MemoryOkfRepository(this.documents);

  final Map<String, String> documents;

  @override
  Future<OkfDocument> readDocument({
    required String bundleRoot,
    required String relativePath,
    String? bundleLabel,
  }) async => OkfDocument.parse(
    relativePath: relativePath,
    source: documents[relativePath]!,
  );
}
