import 'package:freezed_annotation/freezed_annotation.dart';

part 'mix.freezed.dart';

/// An idol-live MIX call associated with a number of musical bars.
@freezed
abstract class Mix with _$Mix {
  /// Creates a MIX.
  const factory Mix({
    required String title,
    required int bars,
    required String call,
    required String sourcePath,
  }) = _Mix;
}
