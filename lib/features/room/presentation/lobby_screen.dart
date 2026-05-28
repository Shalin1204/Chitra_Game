import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/retro_ui.dart';
import '../../../shared/models/room_model.dart';
import '../providers/room_providers.dart';
import '../../realtime/providers/realtime_providers.dart';

/// LobbyScreen — shows connected players and room code while waiting.
/// Host can start the game. Navigates to CanvasRoomScreen on round_start.
class LobbyScreen extends ConsumerWidget {
  final String roomId;

  const LobbyScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final socketId = ref.watch(socketServiceProvider).socketId;
    final myPlayer = room?.players.where((p) => p.id == socketId).firstOrNull;
    final isHost = myPlayer?.isHost ?? false;

    ref.listen(roomProvider, (prev, next) {
      if (next != null && next.status != 'waiting') {
        context.go('/room/canvas/${next.id}');
      }
    });

    if (room == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: RetroColors.neonGreen)),
      );
    }

    return ScanlineOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LOBBY'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: RetroColors.neonGreen),
            onPressed: () {
              ref.read(roomProvider.notifier).leaveRoom();
              context.go(AppRoutes.home);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Room code share card
              RetroPixelBorder(
                borderColor: RetroColors.pixelYellow,
                child: Column(
                  children: [
                    const Text(
                      'ROOM CODE',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 8,
                        color: RetroColors.dimText,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlowText(
                          room.code,
                          style: const TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 28,
                            color: RetroColors.pixelYellow,
                            letterSpacing: 8,
                          ),
                          glowColor: RetroColors.pixelYellow,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: RetroColors.pixelYellow),
                          onPressed: () =>
                              Clipboard.setData(ClipboardData(text: room.code)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'PLAYERS (${room.players.length}/8)',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 9,
                  color: RetroColors.neonGreen,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: room.players.length,
                  separatorBuilder: (_, __) => const PixelDivider(),
                  itemBuilder: (_, i) => _PlayerRow(player: room.players[i]),
                ),
              ),

              const SizedBox(height: 16),
              RetroButton(
                label: isHost ? '▶▶  START GAME' : (myPlayer?.isReady == true ? 'READY' : '▶▶  READY UP'),
                onPressed: () {
                  if (isHost) {
                    ref.read(roomProvider.notifier).startGame();
                  } else {
                    ref.read(roomProvider.notifier).readyUp();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Player player;

  const _PlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            color: player.cursorColor,
          ),
          const SizedBox(width: 12),
          Text(
            player.displayName.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'PixelifySans',
              fontSize: 16,
              color: RetroColors.lightText,
            ),
          ),
          if (player.isHost) ...[
            const SizedBox(width: 8),
            Text(
              '[HOST]',
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 7,
                color: RetroColors.pixelYellow,
              ),
            ),
          ] else if (player.isReady) ...[
            const SizedBox(width: 8),
            Text(
              '[READY]',
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 7,
                color: RetroColors.neonGreen,
              ),
            ),
          ],
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.isOnline ? RetroColors.neonGreen : RetroColors.chaosRed,
            ),
          ),
        ],
      ),
    );
  }
}