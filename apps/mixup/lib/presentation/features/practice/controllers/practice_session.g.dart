// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PracticeSession)
final practiceSessionProvider = PracticeSessionFamily._();

final class PracticeSessionProvider
    extends $AsyncNotifierProvider<PracticeSession, PracticeSessionData> {
  PracticeSessionProvider._({
    required PracticeSessionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'practiceSessionProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$practiceSessionHash();

  @override
  String toString() {
    return r'practiceSessionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PracticeSession create() => PracticeSession();

  @override
  bool operator ==(Object other) {
    return other is PracticeSessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$practiceSessionHash() => r'0315beb63fe2abcb94eb085a780b4f7e64f896fd';

final class PracticeSessionFamily extends $Family
    with
        $ClassFamilyOverride<
          PracticeSession,
          AsyncValue<PracticeSessionData>,
          PracticeSessionData,
          FutureOr<PracticeSessionData>,
          String
        > {
  PracticeSessionFamily._()
    : super(
        retry: null,
        name: r'practiceSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PracticeSessionProvider call(String songId) =>
      PracticeSessionProvider._(argument: songId, from: this);

  @override
  String toString() => r'practiceSessionProvider';
}

abstract class _$PracticeSession extends $AsyncNotifier<PracticeSessionData> {
  late final _$args = ref.$arg as String;
  String get songId => _$args;

  FutureOr<PracticeSessionData> build(String songId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PracticeSessionData>, PracticeSessionData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PracticeSessionData>, PracticeSessionData>,
              AsyncValue<PracticeSessionData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
