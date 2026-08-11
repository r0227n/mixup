// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_repositories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads the configured content paths from the bundled settings asset.

@ProviderFor(contentSettings)
final contentSettingsProvider = ContentSettingsProvider._();

/// Loads the configured content paths from the bundled settings asset.

final class ContentSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContentSettings>,
          ContentSettings,
          FutureOr<ContentSettings>
        >
    with $FutureModifier<ContentSettings>, $FutureProvider<ContentSettings> {
  /// Loads the configured content paths from the bundled settings asset.
  ContentSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentSettingsHash();

  @$internal
  @override
  $FutureProviderElement<ContentSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ContentSettings> create(Ref ref) {
    return contentSettings(ref);
  }
}

String _$contentSettingsHash() => r'06d703bc4d6e57b96e15c89a66cd4b0f96e6cc5a';

/// Creates the OKF reader shared by the content repositories.

@ProviderFor(okfRepository)
final okfRepositoryProvider = OkfRepositoryProvider._();

/// Creates the OKF reader shared by the content repositories.

final class OkfRepositoryProvider
    extends $FunctionalProvider<OkfRepository, OkfRepository, OkfRepository>
    with $Provider<OkfRepository> {
  /// Creates the OKF reader shared by the content repositories.
  OkfRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'okfRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$okfRepositoryHash();

  @$internal
  @override
  $ProviderElement<OkfRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OkfRepository create(Ref ref) {
    return okfRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OkfRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OkfRepository>(value),
    );
  }
}

String _$okfRepositoryHash() => r'19937f8e63322729c40e77a9e35d9229f184e5b1';

/// Creates the repository that reads configured song content.

@ProviderFor(songRepository)
final songRepositoryProvider = SongRepositoryProvider._();

/// Creates the repository that reads configured song content.

final class SongRepositoryProvider
    extends $FunctionalProvider<SongRepository, SongRepository, SongRepository>
    with $Provider<SongRepository> {
  /// Creates the repository that reads configured song content.
  SongRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songRepositoryHash();

  @$internal
  @override
  $ProviderElement<SongRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SongRepository create(Ref ref) {
    return songRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SongRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SongRepository>(value),
    );
  }
}

String _$songRepositoryHash() => r'a4495eabbe0def32a2835c3fce375af2c506a918';

/// Creates the repository that reads configured MIX content.

@ProviderFor(mixRepository)
final mixRepositoryProvider = MixRepositoryProvider._();

/// Creates the repository that reads configured MIX content.

final class MixRepositoryProvider
    extends $FunctionalProvider<MixRepository, MixRepository, MixRepository>
    with $Provider<MixRepository> {
  /// Creates the repository that reads configured MIX content.
  MixRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mixRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mixRepositoryHash();

  @$internal
  @override
  $ProviderElement<MixRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MixRepository create(Ref ref) {
    return mixRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MixRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MixRepository>(value),
    );
  }
}

String _$mixRepositoryHash() => r'd667d8adb1d9e80a52c3bb0abe2399762f46f170';

/// Creates the atomic JSON store used by the practice editor.

@ProviderFor(practiceTimelineRepository)
final practiceTimelineRepositoryProvider =
    PracticeTimelineRepositoryProvider._();

/// Creates the atomic JSON store used by the practice editor.

final class PracticeTimelineRepositoryProvider
    extends
        $FunctionalProvider<
          PracticeTimelineRepository,
          PracticeTimelineRepository,
          PracticeTimelineRepository
        >
    with $Provider<PracticeTimelineRepository> {
  /// Creates the atomic JSON store used by the practice editor.
  PracticeTimelineRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'practiceTimelineRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$practiceTimelineRepositoryHash();

  @$internal
  @override
  $ProviderElement<PracticeTimelineRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PracticeTimelineRepository create(Ref ref) {
    return practiceTimelineRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PracticeTimelineRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PracticeTimelineRepository>(value),
    );
  }
}

String _$practiceTimelineRepositoryHash() =>
    r'c103e08c6d72ff4c8f5178843ddbe2773276eabf';
