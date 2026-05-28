import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/retro_ui.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/enums/app_enums.dart';
import '../providers/room_providers.dart';

/// CreateRoomScreen
/// Allows the host to configure game mode and create a room.
/// Navigates to LobbyScreen on success.
class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  GameMode _selectedMode = GameMode.normal;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(currentUserIdProvider));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _create() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ref.read(currentUserIdProvider.notifier).state = name;
    final avatar = ref.read(currentUserAvatarProvider);
    ref.read(roomProvider.notifier).createRoom(
          displayName: name,
          avatar: avatar,
          mode: _selectedMode,
        );
    // Navigation happens in roomProvider listener (see lobby_screen)
  }

  @override
  Widget build(BuildContext context) {
    // Watch for room creation → navigate to lobby
    ref.listen(roomProvider, (prev, next) {
      if (next != null && prev == null) {
        context.go('/room/lobby/${next.id}');
      }
    });

    return ScanlineOverlay(
      child: Scaffold(
        appBar: AppBar(title: const Text('CREATE ROOM')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RetroPixelBorder(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RetroTextField(
                      controller: _nameCtrl,
                      label: 'YOUR NAME',
                      hint: 'PIXEL_MASTER',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'GAME MODE',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 9,
                        color: RetroColors.pixelYellow,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[GameMode.normal, GameMode.chaos].map((mode) => _ModeOption(
                          mode: mode,
                          selected: _selectedMode == mode,
                          onTap: mode == GameMode.normal ? () => setState(() => _selectedMode = mode) : () {},
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              RetroButton(
                label: '▶▶  START LOBBY',
                onPressed: _create,
                color: RetroColors.neonGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final GameMode mode;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = {
    GameMode.normal: 'GUESS GAME',
    GameMode.chaos: '🌪 CHAOS MODE (UPCOMING)',
  };

  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = mode == GameMode.chaos;
    final color = selected ? RetroColors.neonGreen : RetroColors.dimText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isUpcoming ? RetroColors.dimText.withValues(alpha: 0.5) : color,
            width: selected ? 2 : 1,
          ),
          color: selected ? RetroColors.neonGreen.withValues(alpha: 0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 12),
            Text(
              _labels[mode] ?? mode.name.toUpperCase(),
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 9,
                color: isUpcoming ? RetroColors.dimText.withValues(alpha: 0.5) : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}