import 'package:go_router/go_router.dart';
import 'package:mixup/core/logger/talker.dart';
import 'package:mixup/presentation/features/home/screens/home_screen.dart';
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
    ],
  );

  ref.onDispose(router.dispose);
  return router;
}
