import 'dart:async';

import 'package:mixup/application/ports/mix_repository.dart';
import 'package:mixup/domain/mixes/mix.dart';
import 'package:okf_repository/okf_repository.dart';

/// Loads MIX calls declared by the indexes below the MIX root index.
class MarkdownMixRepository implements MixRepository {
  /// Creates a MIX repository backed by the supplied content repository.
  MarkdownMixRepository(
    this._okfRepository,
    FutureOr<String> bundleRoot,
  ) : _bundleRoot = Future.value(bundleRoot);

  final OkfRepository _okfRepository;
  final Future<String> _bundleRoot;

  @override
  Future<List<Mix>> findAll() async {
    final bundleRoot = await _bundleRoot;
    final rootIndex = await _okfRepository.readDocument(
      bundleRoot: bundleRoot,
      relativePath: 'index.md',
      bundleLabel: 'mixes',
    );
    final barDirectories = rootIndex.markdownLinks
        .where((path) => path.endsWith('/'))
        .map((path) => path.substring(0, path.length - 1));
    final mixes = <Mix>[];
    for (final directory in barDirectories) {
      final indexPath = '$directory/index.md';
      final index = await _okfRepository.readDocument(
        bundleRoot: bundleRoot,
        relativePath: indexPath,
        bundleLabel: 'mixes',
      );
      for (final fileName in index.markdownLinks.where(
        (path) => path.endsWith('.md'),
      )) {
        final path = '$directory/$fileName';
        final document = await _okfRepository.readDocument(
          bundleRoot: bundleRoot,
          relativePath: path,
          bundleLabel: 'mixes',
        );
        mixes.add(_mixFromDocument(document));
      }
    }
    return List.unmodifiable(mixes);
  }

  Mix _mixFromDocument(OkfDocument document) {
    final title = document.stringMetadata('title');
    final bars = document.intMetadata('bars');
    if (title == null || title.isEmpty || bars == null) {
      throw FormatException(
        'MIX ${document.relativePath} has invalid title or bars metadata.',
      );
    }
    return Mix(
      title: title,
      bars: bars,
      call: document.section('コール'),
      sourcePath: document.relativePath,
    );
  }
}
