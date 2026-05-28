import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/retro_ui.dart';
import '../../../core/routes/app_router.dart';
import '../auth/providers/auth_provider.dart';

/// HomeScreen — main hub. Create or join a room.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentName = ref.watch(currentUserIdProvider);
    final currentAvatar = ref.watch(currentUserAvatarProvider);

    Future<void> openGithub() async {
      final uri = Uri.parse('https://github.com/Shalin1204');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return ScanlineOverlay(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlowText(
                      'THE CHIत्रA GAME',
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 13,
                        color: RetroColors.neonGreen,
                        letterSpacing: 2,
                        shadows: [Shadow(color: RetroColors.neonGreen, blurRadius: 10)],
                      ),
                    ),
                    // Avatar button — tapping opens profile in edit mode
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.editProfile),
                      child: Tooltip(
                        message: currentName.isNotEmpty ? currentName : 'Profile',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF041C1C),
                            border: Border.all(color: RetroColors.neonGreen, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: RetroColors.neonGreen.withValues(alpha: 0.25),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              currentAvatar.isNotEmpty ? currentAvatar : '👤',
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Greeting under header
                if (currentName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Hey, $currentName 👋',
                    style: const TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 14,
                      color: RetroColors.dimText,
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                const PixelDivider(),
                const SizedBox(height: 40),

                // Art character placeholder
                Center(
                  child: RetroPixelBorder(
                    borderColor: RetroColors.pixelYellow,
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        '🎨',
                        style: TextStyle(fontSize: 72),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Actions
                RetroButton(
                  label: '▶  CREATE ROOM',
                  onPressed: () => context.push(AppRoutes.createRoom),
                  color: RetroColors.neonGreen,
                ),
                const SizedBox(height: 16),
                RetroButton(
                  label: '⇒  JOIN ROOM',
                  onPressed: () => context.push(AppRoutes.joinRoom),
                  color: RetroColors.electricBlue,
                ),
                const Spacer(),

                // Footer
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SHALIN MISHRA | ',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 7,
                          color: RetroColors.dimText,
                          letterSpacing: 2,
                        ),
                      ),
                      InkWell(
                        onTap: openGithub,
                        child: Text(
                          '<GitHub>',
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 7,
                            color: RetroColors.neonGreen,
                            letterSpacing: 2,
                            decoration: TextDecoration.underline,
                            decorationColor: RetroColors.neonGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
