import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../realtime/providers/realtime_providers.dart';

class ActiveReaction {
  final String id;
  final String emoji;
  final double x; // 0.0 – 1.0 relative to screen
  final double y;

  const ActiveReaction({
    required this.id,
    required this.emoji,
    required this.x,
    required this.y,
  });
}

/// activeReactionsProvider — reactions currently animating on screen.
final activeReactionsProvider =
    StateNotifierProvider<ReactionNotifier, List<ActiveReaction>>(
  (ref) => ReactionNotifier(ref),
);

class ReactionNotifier extends StateNotifier<List<ActiveReaction>> {
  final Ref _ref;
  final _rng = Random();

  ReactionNotifier(this._ref) : super([]) {
    final socket = _ref.read(socketServiceProvider);
    socket.onReaction = (userId, emoji) => _add(emoji);
  }

  void _add(String emoji) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final reaction = ActiveReaction(
      id: id,
      emoji: emoji,
      x: 0.1 + _rng.nextDouble() * 0.8,
      y: 0.4 + _rng.nextDouble() * 0.4,
    );
    state = [...state, reaction];

    // Clean up after animation completes
    Future.delayed(const Duration(milliseconds: 1600), () {
      state = state.where((r) => r.id != id).toList();
    });
  }
}