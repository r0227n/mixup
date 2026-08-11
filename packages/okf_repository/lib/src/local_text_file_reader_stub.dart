/// Returns an empty working directory on unsupported platforms.
String currentWorkingDirectory() => '';

/// Fails because local OKF bundles are unavailable on this platform.
Future<String> readLocalTextFile({
  required String bundleRoot,
  required String relativePath,
}) => Future.error(
  UnsupportedError('Local OKF bundles are unavailable on this platform.'),
);
