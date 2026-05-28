import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/reaction_providers.dart';

/// ReactionOverlay — floating emoji reactions that float up and fade.
class ReactionOverlay extends ConsumerWidget {
  const ReactionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactions = ref.watch(activeReactionsProvider);
    return Stack(
      children: reactions
          .map((r) => _FloatingReaction(reaction: r))
          .toList(),
    );
  }
}

class _FloatingReaction extends StatelessWidget {
  final ActiveReaction reaction;

  const _FloatingReaction({required this.reaction});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final x = reaction.x * size.width;
    final y = reaction.y * size.height;

    return Positioned(
      left: x,
      top: y,
      child: Text(
        reaction.emoji,
        style: const TextStyle(fontSize: 32),
      )
          .animate()
          .moveY(begin: 0, end: -120, duration: 1500.ms, curve: Curves.easeOut)
          .fadeOut(delay: 1000.ms, duration: 500.ms),
    );
  }
}