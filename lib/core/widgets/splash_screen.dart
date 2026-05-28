import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/retro_ui.dart';
import '../routes/app_router.dart';
import '../../features/auth/providers/auth_provider.dart';

/// SplashScreen
/// Shows the Chitra Game logo with pixel-boot animation,
/// then navigates to AuthScreen after 3 seconds.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  Timer? _bootTimer;
  int _loadProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    // Fake boot loader
    _bootTimer = Timer(const Duration(milliseconds: 300), _tick);
  }

  void _tick() {
    if (!mounted) return;
    if (_loadProgress < 100) {
      setState(() => _loadProgress += 10);
      _bootTimer = Timer(const Duration(milliseconds: 120), _tick);
    } else {
      _bootTimer = Timer(const Duration(milliseconds: 400), () async {
        if (!mounted) return;
        // Check if profile already set — skip profile screen if so
        final prefs = await SharedPreferences.getInstance();
        final name = prefs.getString('display_name') ?? '';
        final avatar = prefs.getString('avatar') ?? '👽';
        if (mounted) {
          if (name.isNotEmpty) {
            ref.read(currentUserIdProvider.notifier).state = name;
            ref.read(currentUserAvatarProvider.notifier).state = avatar;
          }
          context.go(name.isNotEmpty ? AppRoutes.home : AppRoutes.profile);
        }
      });
    }
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tap to skip — same logic, check prefs
        SharedPreferences.getInstance().then((prefs) {
          if (!mounted) return;
          final name = prefs.getString('display_name') ?? '';
          final avatar = prefs.getString('avatar') ?? '👽';
          if (name.isNotEmpty) {
            ref.read(currentUserIdProvider.notifier).state = name;
            ref.read(currentUserAvatarProvider.notifier).state = avatar;
          }
          context.go(name.isNotEmpty ? AppRoutes.home : AppRoutes.profile);
        });
      },
      child: ScanlineOverlay(
        child: Scaffold(
          backgroundColor: RetroColors.darkBg,
          body: Center(
            child: FadeTransition(
              opacity: _opacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlowText(
                      'CHAOS',
                      style: RetroTextStyles.pixelTitle.copyWith(fontSize: 32),
                      glowColor: RetroColors.chaosRed,
                    ),
                    GlowText(
                      'CANVAS',
                      style: RetroTextStyles.pixelTitle.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MULTIPLAYER DRAWING PARTY',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 7,
                        color: RetroColors.dimText,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    PixelProgressBar(
                      value: _loadProgress / 100,
                      height: 20,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'LOADING... $_loadProgress%',
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 8,
                        color: RetroColors.neonGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}