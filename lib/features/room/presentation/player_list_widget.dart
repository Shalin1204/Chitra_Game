import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../room/providers/room_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../realtime/providers/realtime_providers.dart';

class PlayerListWidget extends ConsumerWidget {
  const PlayerListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    if (room == null) return const SizedBox();

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: RetroColors.darkBg,
        border: Border(right: BorderSide(color: RetroColors.pixelPurple, width: 2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: RetroColors.pixelPurple.withValues(alpha: 0.2),
            width: double.infinity,
            child: const Text(
              'PLAYERS',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 10,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: room.players.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (ctx, i) {
                final p = room.players[i];
                final isDrawer = p.id == room.drawerId;
                final isMe = p.name == currentUserId;
                final hasGuessed = room.guessedPlayers.contains(p.id);
                final amIHost = room.players.any((p) => p.name == currentUserId && p.isHost);

                return Container(
                  color: hasGuessed ? RetroColors.neonGreen.withValues(alpha: 0.1) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: p.cursorColor.withValues(alpha: 0.2),
                          border: Border.all(color: p.cursorColor, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(p.avatar, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name + (isMe ? ' (You)' : ''),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: hasGuessed ? RetroColors.neonGreen : Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.score} pts',
                              style: const TextStyle(
                                fontFamily: 'PressStart2P',
                                fontSize: 8,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDrawer)
                        const Icon(Icons.edit, size: 16, color: Colors.white),
                      if (amIHost && !isMe)
                        IconButton(
                          icon: const Icon(Icons.volume_off, size: 16, color: Colors.redAccent),
                          onPressed: () {
                            ref.read(socketServiceProvider).emitVoiceSignal({
                              'action': 'mute',
                              'targetId': p.id,
                            });
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
