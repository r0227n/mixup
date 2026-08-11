// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'talker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The application-wide Talker instance supplied by the composition root.

@ProviderFor(talker)
final talkerProvider = TalkerProvider._();

/// The application-wide Talker instance supplied by the composition root.

final class TalkerProvider extends $FunctionalProvider<Talker, Talker, Talker>
    with $Provider<Talker> {
  /// The application-wide Talker instance supplied by the composition root.
  TalkerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'talkerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$talkerHash();

  @$internal
  @override
  $ProviderElement<Talker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Talker create(Ref ref) {
    return talker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Talker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Talker>(value),
    );
  }
}

String _$talkerHash() => r'3f49d592b7a6f216055bf874b3d7d33b342c384c';
