import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:mixup/core/logger/talker.dart';
import 'package:mixup/infrastructure/observability/marionette_talker_observer.dart';
import 'package:mixup/presentation/navigation/routes.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';

Future<void> main() async {
  final marionetteLogCollector = kDebugMode ? PrintLogCollector() : null;
  final talker = createTalker(
    observer: marionetteLogCollector == null
        ? null
        : MarionetteTalkerObserver(marionetteLogCollector),
  );
  await runZonedGuarded<Future<void>>(
    () async {
      if (kDebugMode) {
        MarionetteBinding.ensureInitialized(
          MarionetteConfiguration(logCollector: marionetteLogCollector),
        );
      } else {
        WidgetsFlutterBinding.ensureInitialized();
      }

      runApp(
        ProviderScope(
          observers: [TalkerRiverpodObserver(talker: talker)],
          overrides: [talkerProvider.overrideWithValue(talker)],
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) =>
        handleUncaughtAppException(talker, error, stackTrace),
  );
}

/// The root widget for the Mixup application.
class MyApp extends ConsumerWidget {
  /// Creates the root widget for the Mixup application.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Flutter Demo',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
