import 'package:yaml/yaml.dart';

/// Kind of Markdown document defined by OKF v0.2.
enum OkfDocumentKind {
  /// A knowledge concept with required `type` frontmatter.
  concept,

  /// Reserved progressive-disclosure index.
  indexFile,

  /// Reserved chronological update log.
  logFile,
}

/// Parsed Open Knowledge Format Markdown document.
class OkfDocument {
  OkfDocument._({
    required this.relativePath,
    required this.kind,
    required this.metadata,
    required this.body,
  });

  /// Parses one OKF v0.2 Markdown document.
  factory OkfDocument.parse({
    required String relativePath,
    required String source,
  }) {
    final normalized = source.replaceAll('\r\n', '\n');
    final fileName = relativePath.replaceAll(r'\', '/').split('/').last;
    final kind = switch (fileName) {
      'index.md' => OkfDocumentKind.indexFile,
      'log.md' => OkfDocumentKind.logFile,
      _ => OkfDocumentKind.concept,
    };
    final parsed = _parseFrontmatter(normalized);
    final metadata = parsed.metadata;

    if (kind == OkfDocumentKind.concept) {
      final type = metadata['type'];
      if (type is! String || type.trim().isEmpty) {
        throw FormatException(
          'OKF concept $relativePath must have a non-empty type.',
        );
      }
    } else if (metadata.isNotEmpty &&
        !(kind == OkfDocumentKind.indexFile && relativePath == 'index.md')) {
      throw FormatException(
        'Reserved OKF document $relativePath must not have frontmatter.',
      );
    }
    if (kind == OkfDocumentKind.indexFile &&
        relativePath == 'index.md' &&
        metadata.keys.any((key) => key != 'okf_version')) {
      throw const FormatException(
        'An OKF bundle-root index may only declare okf_version.',
      );
    }

    return OkfDocument._(
      relativePath: relativePath,
      kind: kind,
      metadata: Map.unmodifiable(metadata),
      body: parsed.body,
    );
  }

  /// Path relative to the bundle root.
  final String relativePath;

  /// Role assigned by the reserved filename rules.
  final OkfDocumentKind kind;

  /// YAML frontmatter converted to plain Dart collections.
  final Map<String, Object?> metadata;

  /// Markdown content after frontmatter.
  final String body;

  /// Returns a scalar string metadata value.
  String? stringMetadata(String key) {
    final value = metadata[key];
    return value is String ? value : null;
  }

  /// Returns an integer metadata value, accepting YAML integers and strings.
  int? intMetadata(String key) {
    final value = metadata[key];
    return switch (value) {
      int() => value,
      String() => int.tryParse(value),
      _ => null,
    };
  }

  /// Returns Markdown link targets from bullet-list entries.
  List<String> get markdownLinks {
    final pattern = RegExp(r'^[*-]\s+\[[^\]]+\]\(([^)]+)\)', multiLine: true);
    return [for (final match in pattern.allMatches(body)) match.group(1)!];
  }

  /// Extracts the first section named [heading].
  String section(String heading) {
    final startPattern = RegExp(
      '^#+ ${RegExp.escape(heading)}\\s*\$',
      multiLine: true,
    );
    final match = startPattern.firstMatch(body);
    if (match == null) return '';
    final afterHeading = body.substring(match.end).trim();
    final nextHeading = RegExp('^#', multiLine: true).firstMatch(afterHeading);
    return (nextHeading == null
            ? afterHeading
            : afterHeading.substring(0, nextHeading.start))
        .trim()
        .replaceFirst(RegExp(r'^```text\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }
}

({Map<String, Object?> metadata, String body}) _parseFrontmatter(
  String source,
) {
  if (!source.startsWith('---\n')) {
    return (metadata: const {}, body: source);
  }
  final closingMatches = RegExp(
    r'^---(?:\n|$)',
    multiLine: true,
  ).allMatches(source, 4).iterator;
  final closingDelimiter = closingMatches.moveNext()
      ? closingMatches.current
      : null;
  final end = closingDelimiter?.start ?? -1;
  if (end < 0) {
    throw const FormatException('Unclosed OKF frontmatter.');
  }
  final yaml = loadYaml(source.substring(4, end));
  if (yaml != null && yaml is! YamlMap) {
    throw const FormatException('OKF frontmatter must be a YAML mapping.');
  }
  final metadata = yaml == null
      ? <String, Object?>{}
      : _plainMap(yaml as YamlMap);
  return (metadata: metadata, body: source.substring(closingDelimiter!.end));
}

Map<String, Object?> _plainMap(YamlMap source) => {
  for (final entry in source.entries)
    entry.key.toString(): _plainValue(entry.value),
};

Object? _plainValue(Object? value) => switch (value) {
  YamlMap() => _plainMap(value),
  YamlList() => [for (final item in value) _plainValue(item)],
  _ => value,
};
