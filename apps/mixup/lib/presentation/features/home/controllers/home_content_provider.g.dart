// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_content_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads both debug lists outside the widget build method.

@ProviderFor(homeContent)
final homeContentProvider = HomeContentProvider._();

/// Loads both debug lists outside the widget build method.

final class HomeContentProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomeContent>,
          HomeContent,
          FutureOr<HomeContent>
        >
    with $FutureModifier<HomeContent>, $FutureProvider<HomeContent> {
  /// Loads both debug lists outside the widget build method.
  HomeContentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeContentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeContentHash();

  @$internal
  @override
  $FutureProviderElement<HomeContent> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomeContent> create(Ref ref) {
    return homeContent(ref);
  }
}

String _$homeContentHash() => r'1d6dfaa3c605f8e9e6b6d482a4d3169f762bd702';
