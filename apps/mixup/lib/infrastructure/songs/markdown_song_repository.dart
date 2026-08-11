import 'dart:async';

import 'package:mixup/application/ports/song_repository.dart';
import 'package:mixup/domain/songs/song.dart';
import 'package:okf_repository/okf_repository.dart';

/// Loads songs declared in the songs root index.
class MarkdownSongRepository implements SongRepository {
  /// Creates a song repository backed by the supplied content repository.
  MarkdownSongRepository(
    this._okfRepository,
    FutureOr<String> bundleRoot,
  ) : _bundleRoot = Future.value(bundleRoot);

  final OkfRepository _okfRepository;
  final Future<String> _bundleRoot;

  @override
  Future<List<Song>> findAll() async {
    final bundleRoot = await _bundleRoot;
    final index = await _okfRepository.readDocument(
      bundleRoot: bundleRoot,
      relativePath: 'index.md',
      bundleLabel: 'songs',
    );
    final paths = index.markdownLinks.where((path) => path.endsWith('.md'));
    return Future.wait(
      paths.map((path) async {
        final document = await _okfRepository.readDocument(
          bundleRoot: bundleRoot,
          relativePath: path,
          bundleLabel: 'songs',
        );
        return _songFromDocument(document);
      }),
    );
  }

  Song _songFromDocument(OkfDocument document) {
    final title = document.stringMetadata('title');
    if (title == null || title.isEmpty) {
      throw FormatException(
        'Song ${document.relativePath} is missing title metadata.',
      );
    }
    return Song(
      title: title,
      lyrics: document.section('歌詞'),
      sourcePath: document.relativePath,
      audioPath: document.stringMetadata('audio'),
    );
  }
}
