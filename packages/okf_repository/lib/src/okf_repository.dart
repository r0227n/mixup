import 'package:okf_repository/src/okf_document.dart';

/// Reads parsed documents from an OKF bundle.
// The interface is the package boundary for replaceable bundle storage.
// ignore: one_member_abstracts
abstract interface class OkfRepository {
  /// Reads [relativePath] below [bundleRoot].
  Future<OkfDocument> readDocument({
    required String bundleRoot,
    required String relativePath,
    String? bundleLabel,
  });
}
