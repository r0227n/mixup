import 'package:mixup/domain/mixes/mix.dart';

/// Provides MIX calls without exposing their storage format.
// The interface keeps presentation independent of the Markdown adapter.
// ignore: one_member_abstracts
abstract interface class MixRepository {
  /// Returns every MIX declared by the configured bar indexes.
  Future<List<Mix>> findAll();
}
