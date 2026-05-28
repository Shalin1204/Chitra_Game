import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/home_screen.dart';
import '../../features/room/presentation/create_room_screen.dart';
import '../../features/room/presentation/join_room_screen.dart';
import '../../features/room/presentation/lobby_screen.dart';
import '../../features/canvas/widgets/canvas_room_screen.dart';
import '../../features/replay/playback/replay_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../widgets/splash_screen.dart';

part 'app_router.g.dart';

/// Route name constants — import these instead of raw strings.
abstract class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  static const home = '/home';
  static const createRoom = '/room/create';
  static const joinRoom = '/room/join';
  static const lobby = '/room/lobby/:roomId';
  static const canvasRoom = '/room/canvas/:roomId';
  static const replay = '/replay/:sessionId';
  static const profile = '/profile';       // first-time setup
  static const editProfile = '/profile/edit'; // opened from home
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (ctx, state) => _buildPage(const SplashScreen(), state),
      ),

      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (ctx, state) => _buildPage(const HomeScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.createRoom,
        pageBuilder: (ctx, state) =>
            _buildPage(const CreateRoomScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.joinRoom,
        pageBuilder: (ctx, state) => _buildPage(const JoinRoomScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.lobby,
        pageBuilder: (ctx, state) {
          final roomId = state.pathParameters['roomId']!;
          return _buildPage(LobbyScreen(roomId: roomId), state);
        },
      ),
      GoRoute(
        path: AppRoutes.canvasRoom,
        pageBuilder: (ctx, state) {
          final roomId = state.pathParameters['roomId']!;
          return _buildPage(CanvasRoomScreen(roomId: roomId), state);
        },
      ),
      GoRoute(
        path: AppRoutes.replay,
        pageBuilder: (ctx, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return _buildPage(ReplayScreen(sessionId: sessionId), state);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (ctx, state) => _buildPage(const ProfileScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (ctx, state) => _buildPage(const ProfileScreen(isEditMode: true), state),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Text(
          'PAGE NOT FOUND\n${state.error}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent, fontFamily: 'PressStart2P', fontSize: 12),
        ),
      ),
    ),
  );
}

CustomTransitionPage<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      // Pixel-flash transition: quick fade + slight scale
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}

