# okf_repository

Pure Dart support for reading Open Knowledge Format bundles from local
repositories. The package targets OKF v0.2 and owns:

- local UTF-8 Markdown file reads with bundle-root path protection;
- YAML frontmatter parsing into plain Dart collections;
- `index.md`, `log.md`, and concept-document classification;
- concept `type` validation, Markdown links, and section extraction;
- privacy-safe read lifecycle events for application logging adapters.

```dart
final repository = LocalOkfRepository(observer: logReadEvent);
final document = await repository.readDocument(
  bundleRoot: '/path/to/bundle',
  relativePath: 'concepts/example.md',
  bundleLabel: 'examples',
);
```

Local file access is available on `dart:io` platforms. Other platforms expose
the same API but report `UnsupportedError` when a local read is attempted.
