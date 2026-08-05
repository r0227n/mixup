import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:mixup_ffi/mixup_ffi.dart';

/// Loads the Mixup client used by the example CLI.
typedef MixupLoader = Future<MixupFfi> Function(String libraryPath);

/// Builds and places the native library used by the example CLI.
typedef NativeBuilder =
    Future<int> Function({
      required String repositoryRoot,
      required String outputPath,
      required StringSink output,
      required StringSink errorOutput,
    });

/// Runs the example CLI and returns its process exit code.
Future<int> runCli(
  List<String> arguments, {
  required StringSink output,
  required StringSink errorOutput,
  Map<String, String> environment = const {},
  String defaultLibraryPath = 'libmixup_ffi.dylib',
  String repositoryRoot = '.',
  MixupLoader loader = _loadMixup,
  NativeBuilder nativeBuilder = _buildNative,
}) async {
  final libraryPath = environment['MIXUP_FFI_LIBRARY'] ?? defaultLibraryPath;
  final parser = _createParser(libraryPath);
  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on ArgParserException catch (error) {
    errorOutput.writeln('Error: ${error.message}');
    errorOutput.writeln(_usage(parser));
    return 64;
  }

  if (results.flag('help') || results.command == null) {
    output.writeln(_usage(parser));
    return 0;
  }

  final command = results.command!;
  if (command.flag('help')) {
    output.writeln(_commandUsage(parser, command.name!));
    return 0;
  }

  if (command.name == 'build-native') {
    return nativeBuilder(
      repositoryRoot: repositoryRoot,
      outputPath: defaultLibraryPath,
      output: output,
      errorOutput: errorOutput,
    );
  }

  try {
    final mixup = await loader(results.option('library')!);
    return switch (command.name) {
      'install' => await _install(mixup, command, output, errorOutput),
      'analyze' => await _analyze(mixup, command, output, errorOutput),
      _ => 64,
    };
  } on Object catch (error) {
    errorOutput.writeln('Error: $error');
    return 1;
  }
}

Future<int> _install(
  MixupFfi mixup,
  ArgResults command,
  StringSink output,
  StringSink errorOutput,
) async {
  if (command.rest.length > 1) {
    errorOutput.writeln('Error: install accepts at most one model name.');
    return 64;
  }
  final model = switch (command.rest.firstOrNull) {
    null => null,
    'mel-spectrogram' => MixupModel.melSpectrogram,
    'beat-this-small' => MixupModel.beatThisSmall,
    final value => throw FormatException('unknown model: $value'),
  };
  final installed = await mixup.install(
    model: model,
    modelsDirectory: command.option('path')!,
  );
  for (final path in installed) {
    output.writeln(path);
  }
  return 0;
}

Future<int> _analyze(
  MixupFfi mixup,
  ArgResults command,
  StringSink output,
  StringSink errorOutput,
) async {
  if (command.rest.length != 1) {
    errorOutput.writeln('Error: analyze requires exactly one audio file.');
    return 64;
  }
  final input = command.rest.single;
  errorOutput.writeln('Analyzing $input');
  final result = await mixup.analyze(
    input,
    modelsDirectory: command.option('models')!,
  );
  final json = const JsonEncoder.withIndent(
    '  ',
  ).convert(_analysisJson(result));
  final outputPath = command.option('output');
  if (outputPath == null) {
    output.writeln(json);
  } else {
    await File(outputPath).writeAsString('$json\n');
  }
  return 0;
}

Map<String, Object?> _analysisJson(TrackAnalysis value) => {
  'analyzer_version': value.analyzerVersion,
  'tempo_bpm': value.tempoBpm,
  'bars': value.bars
      .map(
        (bar) => {
          'number': bar.number.toInt(),
          'start_seconds': bar.startSeconds,
          'end_seconds': bar.endSeconds,
          'beats_seconds': bar.beatsSeconds.toList(growable: false),
          'beat_confidence': bar.beatConfidence,
          'vocal_probability': bar.vocalProbability,
          'acoustic_vocal_probability': bar.acousticVocalProbability,
          'vocal_state': bar.vocalState.name,
        },
      )
      .toList(growable: false),
  'beat_confidence': value.beatConfidence,
  'warnings': value.warnings,
};

ArgParser _createParser(String? defaultLibraryPath) {
  final buildNative = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show command help.');
  final install = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      defaultsTo: 'models',
      valueHelp: 'DIR',
      help: 'Directory in which to install model files.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show command help.');
  final analyze = ArgParser()
    ..addOption(
      'models',
      defaultsTo: 'models',
      valueHelp: 'DIR',
      help: 'Directory containing the analysis models.',
    )
    ..addOption(
      'output',
      valueHelp: 'FILE',
      help: 'Write analysis JSON to a file instead of standard output.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show command help.');

  return ArgParser()
    ..addOption(
      'library',
      abbr: 'l',
      defaultsTo: defaultLibraryPath,
      valueHelp: 'FILE',
      help: 'Path to the built mixup_ffi dynamic library.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.')
    ..addCommand('build-native', buildNative)
    ..addCommand('install', install)
    ..addCommand('analyze', analyze);
}

String _usage(ArgParser parser) =>
    '''
Run the Mixup analysis engine through the Dart mixup_ffi package.

Usage: dart run bin/mixup_cli.dart [OPTIONS] <COMMAND>

${parser.usage}

Commands:
  build-native          Build release Rust library into this app directory.
  install [MODEL]       Install all models or one selected model.
  analyze <INPUT>       Analyze an audio file and print JSON.
''';

String _commandUsage(ArgParser parser, String name) {
  final command = parser.commands[name]!;
  final arguments = switch (name) {
    'install' => '[MODEL]',
    'analyze' => '<INPUT>',
    _ => '',
  };
  return 'Usage: dart run bin/mixup_cli.dart [OPTIONS] $name '
      '$arguments\n\n${command.usage}';
}

Future<MixupFfi> _loadMixup(String libraryPath) =>
    MixupFfi.load(libraryPath: libraryPath);

Future<int> _buildNative({
  required String repositoryRoot,
  required String outputPath,
  required StringSink output,
  required StringSink errorOutput,
}) async {
  final result = await Process.run('cargo', [
    'build',
    '--release',
    '--manifest-path',
    'engine/Cargo.toml',
    '--package',
    'mixup-ffi',
  ], workingDirectory: repositoryRoot);
  output.write(result.stdout);
  errorOutput.write(result.stderr);
  if (result.exitCode != 0) return result.exitCode;

  final builtLibrary = File(
    '$repositoryRoot/engine/target/release/libmixup_ffi.dylib',
  );
  if (!builtLibrary.existsSync()) {
    errorOutput.writeln(
      'Error: release build succeeded but ${builtLibrary.path} was not found.',
    );
    return 1;
  }
  await builtLibrary.copy(outputPath);
  output.writeln('Created $outputPath');
  return 0;
}
