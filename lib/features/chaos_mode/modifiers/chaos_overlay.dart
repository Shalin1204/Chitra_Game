import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/chaos_providers.dart';

/// ChaosOverlay — displays a fullscreen banner when a chaos event fires.
/// Positioned as an IgnorePointer layer above the canvas.
class ChaosOverlay extends ConsumerWidget {
  const ChaosOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(activeChaosEventProvider);
    if (event == null) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: RetroColors.chaosRed.withValues(alpha: 0.9),
            border: Border.all(color: RetroColors.chaosRed, width: 3),
            boxShadow: const [
              BoxShadow(color: RetroColors.chaosRed, blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                event.label,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        )
            .animate()
            .shake(duration: 300.ms)
            .fadeIn(duration: 200.ms)
            .then()
            .fadeOut(delay: Duration(milliseconds: event.duration.inMilliseconds - 500)),
      ),
    );
  }
}