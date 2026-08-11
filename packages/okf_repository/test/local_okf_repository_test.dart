import 'dart:io';

import 'package:okf_repository/okf_repository.dart';
import 'package:test/test.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() => temporaryDirectory = Directory.systemTemp.createTempSync('okf_'));
  tearDown(() => temporaryDirectory.deleteSync(recursive: true));

  test('reads, parses, and traces a document below its bundle root', () async {
    final bundle = Directory('${temporaryDirectory.path}/bundle')..createSync();
    File(
      '${bundle.path}/concept.md',
    ).writeAsStringSync('---\ntype: Reference\ntitle: Example\n---\nbody');
    final events = <OkfReadEvent>[];
    final repository = LocalOkfRepository(
      workingDirectory: temporaryDirectory.path,
      observer: events.add,
    );

    final document = await repository.readDocument(
      bundleRoot: 'bundle',
      relativePath: 'concept.md',
      bundleLabel: 'test',
    );

    expect(document.stringMetadata('title'), 'Example');
    expect(events.map((event) => event.phase), [
      OkfReadPhase.started,
      OkfReadPhase.completed,
    ]);
    expect(events.last.documentLabel, 'test/concept.md');
    expect(events.last.characterCount, greaterThan(0));
  });

  test('rejects paths escaping the bundle root', () async {
    final repository = LocalOkfRepository(
      workingDirectory: temporaryDirectory.path,
    );

    await expectLater(
      repository.readDocument(
        bundleRoot: 'bundle',
        relativePath: '../secret.md',
      ),
      throwsArgumentError,
    );
  });

  test('rejects paths escaping through a symbolic link', () async {
    final bundle = Directory('${temporaryDirectory.path}/bundle')..createSync();
    final outside = File('${temporaryDirectory.path}/secret.md')
      ..writeAsStringSync('---\ntype: Reference\n---\nsecret');
    Link('${bundle.path}/linked.md').createSync(outside.path);
    final repository = LocalOkfRepository(
      workingDirectory: temporaryDirectory.path,
    );

    await expectLater(
      repository.readDocument(
        bundleRoot: 'bundle',
        relativePath: 'linked.md',
      ),
      throwsArgumentError,
    );
  });

  test('normalizes a root index path before parsing and tracing', () async {
    final bundle = Directory('${temporaryDirectory.path}/bundle')..createSync();
    File('${bundle.path}/index.md').writeAsStringSync(
      '---\nokf_version: "0.2"\n---\n# Contents',
    );
    final events = <OkfReadEvent>[];
    final repository = LocalOkfRepository(
      workingDirectory: temporaryDirectory.path,
      observer: events.add,
    );

    final document = await repository.readDocument(
      bundleRoot: 'bundle',
      relativePath: r'.\index.md',
    );

    expect(document.kind, OkfDocumentKind.indexFile);
    expect(document.stringMetadata('okf_version'), '0.2');
    expect(events.last.relativePath, 'index.md');
  });

  test('reports failed reads without exposing the absolute root', () async {
    final events = <OkfReadEvent>[];
    final repository = LocalOkfRepository(
      workingDirectory: temporaryDirectory.path,
      observer: events.add,
    );

    await expectLater(
      repository.readDocument(
        bundleRoot: 'bundle',
        relativePath: 'missing.md',
        bundleLabel: 'test',
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(events.last.phase, OkfReadPhase.failed);
    expect(events.last.documentLabel, 'test/missing.md');
    expect(events.last.failureType, 'PathNotFoundException');
    expect(events.last.toString(), isNot(contains(temporaryDirectory.path)));
  });
}
