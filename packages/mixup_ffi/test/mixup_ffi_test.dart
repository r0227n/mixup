import 'dart:typed_data';

import 'package:mixup_ffi/mixup_ffi.dart';
import 'package:test/test.dart';

void main() {
  group('install', () {
    test('requests all models with the CLI defaults', () async {
      final backend = _FakeBackend();
      final mixup = MixupFfi.withBackend(backend);

      final paths = await mixup.install();

      expect(paths, ['/tmp/models/a.onnx', '/tmp/models/b.onnx']);
      expect(backend.installedModel, isNull);
      expect(backend.modelsPath, 'models');
    });

    test('passes a selected model and destination', () async {
      final backend = _FakeBackend();
      final mixup = MixupFfi.withBackend(backend);

      await mixup.install(
        model: MixupModel.beatThisSmall,
        modelsDirectory: '/custom',
      );

      expect(backend.installedModel, MixupModel.beatThisSmall);
      expect(backend.modelsPath, '/custom');
    });
  });

  test('analyze returns the generated flutter_rust_bridge type', () async {
    final backend = _FakeBackend();
    final mixup = MixupFfi.withBackend(backend);

    final result = await mixup.analyze(
      '/music/song.wav',
      modelsDirectory: '/models',
    );

    expect(backend.inputPath, '/music/song.wav');
    expect(backend.modelsPath, '/models');
    expect(result.tempoBpm, 120);
    expect(result.bars.single.vocalState, VocalState.vocal);
    expect(
      result.bars.single.beatsSeconds,
      Float32List.fromList([0, 0.5, 1, 1.5]),
    );
    expect(result.warnings, ['review automatic result']);
  });
}

final class _FakeBackend implements MixupBackend {
  MixupModel? installedModel;
  String? inputPath;
  String? modelsPath;

  @override
  Future<List<String>> install({
    MixupModel? model,
    required String path,
  }) async {
    installedModel = model;
    modelsPath = path;
    return ['/tmp/models/a.onnx', '/tmp/models/b.onnx'];
  }

  @override
  Future<TrackAnalysis> analyze({
    required String input,
    required String models,
  }) async {
    inputPath = input;
    modelsPath = models;
    return TrackAnalysis(
      analyzerVersion: '0.1.0',
      tempoBpm: 120,
      bars: [
        BarAnalysis(
          number: BigInt.one,
          startSeconds: 0,
          endSeconds: 2,
          beatsSeconds: Float32List.fromList([0, 0.5, 1, 1.5]),
          beatConfidence: 0.96,
          vocalProbability: 0.82,
          acousticVocalProbability: 0.78,
          vocalState: VocalState.vocal,
        ),
      ],
      beatConfidence: 0.95,
      warnings: ['review automatic result'],
    );
  }
}
