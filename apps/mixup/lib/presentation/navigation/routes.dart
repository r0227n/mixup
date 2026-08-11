import 'package:go_router/go_router.dart';
import 'package:mixup/core/logger/talker.dart';
import 'package:mixup/presentation/features/home/screens/home_screen.dart';
import 'package:mixup/presentation/features/practice/screens/lyrics_timing_screen.dart';
import 'package:mixup/presentation/features/practice/screens/mix_assignment_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'routes.g.dart';

/// The application router and the single source of truth for route definitions.
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final talker = ref.watch(talkerProvider);
  final router = GoRouter(
    observers: [TalkerRouteObserver(talker)],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/songs/:songId/timing',
        builder: (context, state) => LyricsTimingScreen(
          songId: state.pathParameters['songId']!,
        ),
      ),
      GoRoute(
        path: '/songs/:songId/mix',
        builder: (context, state) => MixAssignmentScreen(
          songId: state.pathParameters['songId']!,
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
}
