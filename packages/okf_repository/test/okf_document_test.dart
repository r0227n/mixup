import 'package:okf_repository/okf_repository.dart';
import 'package:test/test.dart';

void main() {
  test('parses OKF v0.2 YAML frontmatter and structured body', () {
    final document = OkfDocument.parse(
      relativePath: 'mix.md',
      source: '''
---
type: Idol Live MIX
title: "Example"
bars: 8
tags: [mix, live]
generated:
  by: process:test
  at: 2026-08-11T00:00:00Z
---

# コール

```text
ワールドカオス
```
''',
    );

    expect(document.kind, OkfDocumentKind.concept);
    expect(document.stringMetadata('type'), 'Idol Live MIX');
    expect(document.intMetadata('bars'), 8);
    expect(document.metadata['tags'], ['mix', 'live']);
    expect(document.metadata['generated'], isA<Map<String, Object?>>());
    expect(document.section('コール'), 'ワールドカオス');
  });

  test('supports root index version and both OKF bullet markers', () {
    final document = OkfDocument.parse(
      relativePath: 'index.md',
      source: '''
---
okf_version: "0.2"
---
# Contents
* [One](one.md)
- [Group](group/)
''',
    );

    expect(document.kind, OkfDocumentKind.indexFile);
    expect(document.stringMetadata('okf_version'), '0.2');
    expect(document.markdownLinks, ['one.md', 'group/']);
  });

  test('rejects a concept without required type metadata', () {
    expect(
      () => OkfDocument.parse(
        relativePath: 'broken.md',
        source: '---\ntitle: Broken\n---\nbody',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('accepts frontmatter closed at end of file', () {
    final document = OkfDocument.parse(
      relativePath: 'empty.md',
      source: '---\ntype: Reference\n---',
    );

    expect(document.kind, OkfDocumentKind.concept);
    expect(document.body, isEmpty);
  });

  test('rejects malformed YAML frontmatter', () {
    expect(
      () => OkfDocument.parse(
        relativePath: 'broken.md',
        source: '---\ntype: [broken\n---\nbody',
      ),
      throwsA(anything),
    );
  });

  test('rejects unrelated frontmatter on the bundle-root index', () {
    expect(
      () => OkfDocument.parse(
        relativePath: 'index.md',
        source: '---\ntitle: Not allowed\n---\n# Contents',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
