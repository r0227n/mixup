import 'package:okf_repository/src/local_text_file_reader_stub.dart'
    if (dart.library.io) 'local_text_file_reader_io.dart';
import 'package:okf_repository/src/okf_document.dart';
import 'package:okf_repository/src/okf_read_event.dart';
import 'package:okf_repository/src/okf_repository.dart';

/// Reads and parses OKF documents from local bundle directories.
class LocalOkfRepository implements OkfRepository {
  /// Creates a local repository resolved from [workingDirectory].
  LocalOkfRepository({this.observer, String? workingDirectory})
    : _workingDirectory = workingDirectory ?? currentWorkingDirectory();

  /// Optional observer for privacy-safe file tracking.
  final OkfReadObserver? observer;
  final String _workingDirectory;

  @override
  Future<OkfDocument> readDocument({
    required String bundleRoot,
    required String relativePath,
    String? bundleLabel,
  }) async {
    final normalizedRelativePath = _normalizeRelativePath(relativePath);
    final resolvedBundleRoot = _isAbsolutePath(bundleRoot)
        ? bundleRoot
        : '$_workingDirectory/$bundleRoot';
    final stopwatch = Stopwatch()..start();
    observer?.call(
      OkfReadEvent(
        phase: OkfReadPhase.started,
        relativePath: normalizedRelativePath,
        bundleLabel: bundleLabel,
      ),
    );
    try {
      final source = await readLocalTextFile(
        bundleRoot: resolvedBundleRoot,
        relativePath: normalizedRelativePath,
      );
      final document = OkfDocument.parse(
        relativePath: normalizedRelativePath,
        source: source,
      );
      observer?.call(
        OkfReadEvent(
          phase: OkfReadPhase.completed,
          relativePath: normalizedRelativePath,
          bundleLabel: bundleLabel,
          characterCount: source.length,
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
        ),
      );
      return document;
    } catch (error) {
      observer?.call(
        OkfReadEvent(
          phase: OkfReadPhase.failed,
          relativePath: normalizedRelativePath,
          bundleLabel: bundleLabel,
          failureType: error.runtimeType.toString(),
        ),
      );
      rethrow;
    }
  }

  String _normalizeRelativePath(String path) {
    final slashSeparatedPath = path.replaceAll(r'\', '/');
    final segments = slashSeparatedPath.split('/');
    if (path.isEmpty ||
        slashSeparatedPath.startsWith('/') ||
        RegExp('^[A-Za-z]:/').hasMatch(slashSeparatedPath) ||
        segments.contains('..')) {
      throw ArgumentError.value(
        path,
        'relativePath',
        'must stay within its bundle root',
      );
    }
    final normalized = segments
        .where((segment) => segment.isNotEmpty && segment != '.')
        .join('/');
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        path,
        'relativePath',
        'must identify a document below its bundle root',
      );
    }
    return normalized;
  }

  bool _isAbsolutePath(String path) =>
      path.startsWith('/') || RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path);
}
