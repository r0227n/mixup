import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mixup_ffi/mixup_ffi.dart';
import 'package:mixup_cli/cli.dart';
import 'package:test/test.dart';

void main() {
  test('install uses CLI-compatible defaults', () async {
    final backend = _FakeBackend();
    final output = StringBuffer();
    final errors = StringBuffer();

    final exitCode = await runCli(
      ['install'],
      output: output,
      errorOutput: errors,
      defaultLibraryPath: '/apps/mixup_cli/libmixup_ffi.dylib',
      loader: (path) async {
        expect(path, '/apps/mixup_cli/libmixup_ffi.dylib');
        return MixupFfi.withBackend(backend);
      },
    );

    expect(exitCode, 0);
    expect(backend.model, isNull);
    expect(backend.modelsDirectory, 'models');
    expect(output.toString(), '/models/mel.onnx\n/models/beat.onnx\n');
    expect(errors.toString(), isEmpty);
  });

  test('install accepts the selected model and destination', () async {
    final backend = _FakeBackend();

    final exitCode = await runCli(
      [
        '--library',
        '/native/library',
        'install',
        'beat-this-small',
        '--path',
        '/custom',
      ],
      output: StringBuffer(),
      errorOutput: StringBuffer(),
      loader: (_) async => MixupFfi.withBackend(backend),
    );

    expect(exitCode, 0);
    expect(backend.model, MixupModel.beatThisSmall);
    expect(backend.modelsDirectory, '/custom');
  });

  test('analyze prints the Rust result as CLI-compatible JSON', () async {
    final backend = _FakeBackend();
    final output = StringBuffer();
    final errors = StringBuffer();

    final exitCode = await runCli(
      ['--library', '/native/library', 'analyze', 'song.wav'],
      output: output,
      errorOutput: errors,
      loader: (_) async => MixupFfi.withBackend(backend),
    );

    expect(exitCode, 0);
    expect(backend.input, 'song.wav');
    expect(backend.modelsDirectory, 'models');
    expect(errors.toString(), 'Analyzing song.wav\n');
    final json = jsonDecode(output.toString()) as Map<String, Object?>;
    expect(json['tempo_bpm'], 120.0);
    expect(json['warnings'], ['automatic result']);
    expect(
      (json['bars']! as List<Object?>).single,
      containsPair('vocal_state', 'vocal'),
    );
  });

  test('analyze writes JSON to the requested output file', () async {
    final backend = _FakeBackend();
    final output = StringBuffer();
    final errors = StringBuffer();
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'mixup-cli-test-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final outputFile = File('${temporaryDirectory.path}/analysis.json');

    final exitCode = await runCli(
      [
        '--library',
        '/native/library',
        'analyze',
        'song.wav',
        '--output',
        outputFile.path,
      ],
      output: output,
      errorOutput: errors,
      loader: (_) async => MixupFfi.withBackend(backend),
    );

    expect(exitCode, 0);
    expect(output.toString(), isEmpty);
    expect(errors.toString(), 'Analyzing song.wav\n');
    final json = jsonDecode(await outputFile.readAsString());
    expect(json, isA<Map<String, Object?>>());
    expect((json as Map<String, Object?>)['tempo_bpm'], 120.0);
  });

  test('build-native uses the release manifest and app destination', () async {
    String? receivedRoot;
    String? receivedOutput;

    final exitCode = await runCli(
      ['build-native'],
      output: StringBuffer(),
      errorOutput: StringBuffer(),
      defaultLibraryPath: '/apps/mixup_cli/libmixup_ffi.dylib',
      repositoryRoot: '/repository',
      nativeBuilder:
          ({
            required repositoryRoot,
            required outputPath,
            required output,
            required errorOutput,
          }) async {
            receivedRoot = repositoryRoot;
            receivedOutput = outputPath;
            return 0;
          },
    );

    expect(exitCode, 0);
    expect(receivedRoot, '/repository');
    expect(receivedOutput, '/apps/mixup_cli/libmixup_ffi.dylib');
  });
}

final class _FakeBackend implements MixupBackend {
  MixupModel? model;
  String? input;
  String? modelsDirectory;

  @override
  Future<List<String>> install({
    MixupModel? model,
    required String path,
  }) async {
    this.model = model;
    modelsDirectory = path;
    return ['/models/mel.onnx', '/models/beat.onnx'];
  }

  @override
  Future<TrackAnalysis> analyze({
    required String input,
    required String models,
  }) async {
    this.input = input;
    modelsDirectory = models;
    return TrackAnalysis(
      analyzerVersion: '0.1.0',
      tempoBpm: 120,
      bars: [
        BarAnalysis(
          number: BigInt.one,
          startSeconds: 0,
          endSeconds: 2,
          beatsSeconds: Float32List.fromList([0, 0.5, 1, 1.5]),
          beatConfidence: 0.95,
          vocalProbability: 0.8,
          acousticVocalProbability: 0.75,
          vocalState: VocalState.vocal,
        ),
      ],
      beatConfidence: 0.95,
      warnings: ['automatic result'],
    );
  }
}
