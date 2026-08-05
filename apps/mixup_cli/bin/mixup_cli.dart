import 'dart:io';
import 'dart:isolate';

import 'package:mixup_cli/cli.dart';

Future<void> main(List<String> arguments) async {
  final cliLibrary = await Isolate.resolvePackageUri(
    Uri.parse('package:mixup_cli/cli.dart'),
  );
  if (cliLibrary == null) {
    stderr.writeln('Error: could not resolve the example package directory.');
    exitCode = 1;
    return;
  }
  final appDirectory = File.fromUri(cliLibrary).parent.parent.absolute;
  final repositoryRoot = appDirectory.parent.parent.absolute.path;
  exitCode = await runCli(
    arguments,
    output: stdout,
    errorOutput: stderr,
    environment: Platform.environment,
    defaultLibraryPath: '${appDirectory.path}/libmixup_ffi.dylib',
    repositoryRoot: repositoryRoot,
  );
}
