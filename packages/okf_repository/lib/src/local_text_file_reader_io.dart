import 'dart:io';

/// Returns the process working directory on IO platforms.
String currentWorkingDirectory() => Directory.current.path;

/// Reads a UTF-8 text file after resolving it below [bundleRoot].
Future<String> readLocalTextFile({
  required String bundleRoot,
  required String relativePath,
}) async {
  final resolvedRoot = await Directory(bundleRoot).resolveSymbolicLinks();
  final resolvedPath = await File(
    '$resolvedRoot${Platform.pathSeparator}$relativePath',
  ).resolveSymbolicLinks();
  final rootPrefix = resolvedRoot.endsWith(Platform.pathSeparator)
      ? resolvedRoot
      : '$resolvedRoot${Platform.pathSeparator}';
  final comparablePath = Platform.isWindows
      ? resolvedPath.toLowerCase()
      : resolvedPath;
  final comparableRootPrefix = Platform.isWindows
      ? rootPrefix.toLowerCase()
      : rootPrefix;
  if (!comparablePath.startsWith(comparableRootPrefix)) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      'must stay within its bundle root',
    );
  }
  return File(resolvedPath).readAsString();
}
