import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart'
    show ExternalLibrary;

import 'rust/api.dart';
import 'rust/api.dart' as rust_api;
import 'rust/frb_generated.dart';

/// Injectable boundary for clients that need deterministic engine tests.
abstract interface class MixupBackend {
  Future<List<String>> install({MixupModel? model, required String path});

  Future<TrackAnalysis> analyze({
    required String input,
    required String models,
  });
}

final class _FlutterRustBridgeBackend implements MixupBackend {
  const _FlutterRustBridgeBackend();

  @override
  Future<List<String>> install({MixupModel? model, required String path}) =>
      rust_api.install(model: model, path: path);

  @override
  Future<TrackAnalysis> analyze({
    required String input,
    required String models,
  }) => rust_api.analyze(input: input, models: models);
}

/// Dart API for the Mixup Rust engine's CLI-equivalent operations.
final class MixupFfi {
  MixupFfi._(this._backend);

  /// Loads the generated `flutter_rust_bridge` bindings from [libraryPath].
  static Future<MixupFfi> load({required String libraryPath}) async {
    await MixupRustLib.init(externalLibrary: ExternalLibrary.open(libraryPath));
    return MixupFfi._(const _FlutterRustBridgeBackend());
  }

  /// Creates a client backed by a test implementation without loading Rust.
  factory MixupFfi.withBackend(MixupBackend backend) => MixupFfi._(backend);

  final MixupBackend _backend;

  /// Downloads and checksum-verifies one model, or all required models when [model] is omitted.
  ///
  /// Returns the installed model paths in the same order as the CLI prints them.
  Future<List<String>> install({
    MixupModel? model,
    String modelsDirectory = 'models',
  }) => _backend.install(model: model, path: modelsDirectory);

  /// Analyzes tempo, four-beat bars, and per-bar vocal activity in [inputPath].
  Future<TrackAnalysis> analyze(
    String inputPath, {
    String modelsDirectory = 'models',
  }) => _backend.analyze(input: inputPath, models: modelsDirectory);
}
