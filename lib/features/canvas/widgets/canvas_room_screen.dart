import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/canvas_models.dart';
import '../painters/canvas_painter.dart';
import '../providers/canvas_providers.dart';
import '../../reactions/overlays/reaction_overlay.dart';
import '../../chaos_mode/modifiers/chaos_overlay.dart';
import '../../../shared/models/room_model.dart';
import '../../room/providers/room_providers.dart';
import '../../realtime/providers/realtime_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../voice/providers/voice_chat_service.dart';
import '../../chat/chat_widget.dart';
import '../../../core/services/user_profile_service.dart';

// ═══════════════════════════════════════════════════════════════════
// CanvasRoomScreen — main game screen
// Layout (mobile portrait):
//   ┌─────────────────────────────────────┐
//   │  TopHUD  (timer | word | round)     │
//   ├─────────────────────────────────────┤
//   │                                     │  ← Expanded canvas
//   │        DRAWING BOARD                │     (drawer can draw here)
//   │                                     │
//   ├─────────────────────────────────────┤
//   │  CHAT + GUESS INPUT  (guessers only)│  ← ~50% height
//   ├─────────────────────────────────────┤
//   │  TOOLBAR  (drawer only)             │
//   └─────────────────────────────────────┘
// ═══════════════════════════════════════════════════════════════════

class CanvasRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const CanvasRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<CanvasRoomScreen> createState() => _CanvasRoomScreenState();
}

class _CanvasRoomScreenState extends ConsumerState<CanvasRoomScreen> {
  double _chatHeightRatio = 0.45;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(voiceChatProvider.notifier).joinChannel(widget.roomId);
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      if (mounted) ref.read(voiceChatProvider.notifier).leaveChannel();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasController = ref.watch(canvasControllerProvider(widget.roomId));
    final room = ref.watch(roomProvider);

    ref.listen(roomProvider, (previous, next) {
      if (previous?.status != 'wordSelection' &&
          next?.status == 'wordSelection') {
        canvasController.clearCanvas();
      }

      if (previous?.status != 'finished' && next?.status == 'finished') {
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId != null) {
          final myPlayer = next?.players.where((p) => p.name == currentUserId).firstOrNull;
          if (myPlayer != null && myPlayer.score > 0) {
            ref.read(userProfileServiceProvider).updateHighScore(currentUserId, myPlayer.score);
          }
        }
      }
    });

    final tool = ref.watch(toolStateProvider);

    // Sync tool state to canvas controller after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && canvasController.toolState != tool) {
        canvasController.updateTool(tool);
      }
    });

    // ── Who is the drawer? ─────────────────────────────────────────
    // We can securely identify ourselves via our socket ID.
    final socketId = ref.watch(socketServiceProvider).socketId;
    final isDrawer = room != null &&
        room.drawerId != null &&
        room.drawerId == socketId;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1415),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top HUD ───────────────────────────────────────────
            _TopHUD(
              isDrawer: isDrawer,
              onUndo: canvasController.undo,
              onRedo: canvasController.redo,
              onClear: canvasController.clearCanvas,
            ),

            // ── Canvas (always shown, always takes remaining space after toolbar/chat) ──
            Expanded(
              flex: isDrawer ? 1000 : (1000 * (1 - _chatHeightRatio)).toInt(),
              child: _DrawingBoard(
                canvasController: canvasController,
                isDrawer: isDrawer,
                room: room,
              ),
            ),

            // ── Chat Drag Handle ──────────────────────────────
            if (!isDrawer)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  setState(() {
                    final screenHeight = MediaQuery.of(context).size.height;
                    _chatHeightRatio -= details.primaryDelta! / screenHeight;
                    _chatHeightRatio = _chatHeightRatio.clamp(0.15, 0.85);
                  });
                },
                child: Container(
                  height: 20,
                  width: double.infinity,
                  color: const Color(0xFF061414),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F3A30),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Chat panel (guessers only) ─
            if (!isDrawer)
              Expanded(
                flex: (1000 * _chatHeightRatio).toInt(),
                child: const ChatWidget(),
              ),

            // ── Toolbar (drawer only) ─────────────────────────────
            if (isDrawer) _ToolBar(roomId: widget.roomId),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// _DrawingBoard — the white canvas + overlays
// ═══════════════════════════════════════════════════════════════════
class _DrawingBoard extends StatelessWidget {
  final dynamic canvasController;
  final bool isDrawer;
  final Room? room;

  const _DrawingBoard({
    required this.canvasController,
    required this.isDrawer,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // White canvas fill
        Container(color: const Color(0xFFE8E0D0)),

        // Actual drawing surface
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: isDrawer
              ? (d) => canvasController.onPointerDown(
                    DrawPoint(x: d.localPosition.dx, y: d.localPosition.dy),
                  )
              : null,
          onPanUpdate: isDrawer
              ? (d) => canvasController.onPointerMove(
                    DrawPoint(x: d.localPosition.dx, y: d.localPosition.dy),
                  )
              : null,
          onPanEnd: isDrawer ? (_) => canvasController.onPointerUp() : null,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: CanvasPainter(
                strokes: canvasController.strokes,
                remoteStrokes: canvasController.remoteStrokes,
                activeStroke: canvasController.activeStroke,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Chaos + reactions (visual only)
        const IgnorePointer(child: ChaosOverlay()),
        const IgnorePointer(child: ReactionOverlay()),

        // Word choice overlay (drawer only)
        if (isDrawer &&
            room?.status == 'wordSelection' &&
            room!.wordChoices.isNotEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: _WordChoiceOverlay(choices: room!.wordChoices),
              ),
            ),
          ),

        // Turn-end overlay
        if (room?.status == 'turnEnd')
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TURN OVER',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 18,
                        color: Color(0xFFE0B376),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The word was: ${room?.currentWord ?? ''}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Game finished overlay
        if (room?.status == 'finished')
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🏆 GAME OVER',
                      style: TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 16),
                    ...((room?.players ?? [])
                            .toList()
                          ..sort((a, b) => b.score.compareTo(a.score)))
                        .take(3)
                        .map(
                          (p) => Text(
                            '${p.avatar}  ${p.name}  —  ${p.score} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// _WordChoiceOverlay
// ═══════════════════════════════════════════════════════════════════
class _WordChoiceOverlay extends ConsumerWidget {
  final List<WordChoice> choices;
  const _WordChoiceOverlay({required this.choices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF041C1C),
        border: Border.all(color: const Color(0xFF1F3A30), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CHOOSE YOUR WORD',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 12,
              color: Color(0xFFE0B376),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: choices
                .map(
                  (w) => GestureDetector(
                    onTap: () =>
                        ref.read(socketServiceProvider).emitSelectWord(w.word),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF062323),
                        border: Border.all(
                            color: const Color(0xFF39FF14), width: 2),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF39FF14).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            w.category,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF8BA896),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            w.word,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF39FF14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// _TopHUD — timer | word display | round indicator
// ═══════════════════════════════════════════════════════════════════
class _TopHUD extends ConsumerWidget {
  final bool isDrawer;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  const _TopHUD({
    required this.isDrawer,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);

    // ── Build the word display string ───────────────────────────────
    // Drawer sees the actual word.
    // Guessers see revealed letters + underscores, exactly like Skribbl:
    //   [ C, null, null, T, null, A ] → "C  _  _  T  _  A"
    Widget wordWidget;

    if (room == null || room.status == 'waiting') {
      wordWidget = const Text(
        'Waiting...',
        style: TextStyle(
            fontFamily: 'Inter', fontSize: 16, color: Colors.white54),
      );
    } else if (room.status == 'wordSelection') {
      wordWidget = Text(
        isDrawer ? 'Choose your word!' : 'Drawer is choosing...',
        style: const TextStyle(
            fontFamily: 'Inter', fontSize: 16, color: Colors.white70),
      );
    } else if (room.status == 'drawing') {
      if (isDrawer && room.currentWord != null && room.currentWord!.isNotEmpty) {
        // Drawer sees full word
        wordWidget = Text(
          room.currentWord!,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF39FF14),
            letterSpacing: 3,
          ),
        );
      } else {
        // Guessers see revealed partial word
        final letters = room.revealedLetters;
        if (letters.isEmpty) {
          // Fallback: all dashes
          final dashes = List.filled(room.wordLength, '_');
          wordWidget = _buildLetterRow(dashes);
        } else {
          final display = letters
              .map((ch) => ch == ' ' ? ' ' : (ch ?? '_'))
              .toList();
          wordWidget = _buildLetterRow(display);
        }
      }
    } else if (room.status == 'turnEnd' || room.status == 'finished') {
      wordWidget = Text(
        room.currentWord ?? '',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF2D55),
          letterSpacing: 3,
        ),
      );
    } else {
      wordWidget = const SizedBox.shrink();
    }

    // ── Timer color — turns red when < 15s ─────────────────────────
    final timeLeft = room?.timeRemaining ?? 0;
    final timerColor =
        timeLeft < 15 ? const Color(0xFFFF2D55) : const Color(0xFFE0B376);

    return Container(
      color: const Color(0xFF0A1C1D),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              ref.read(roomProvider.notifier).leaveRoom();
              context.go(AppRoutes.home);
            },
            child: const Icon(Icons.arrow_back, color: Color(0xFFE0B376),
                size: 22),
          ),
          const SizedBox(width: 10),

          // Timer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2625),
              border: Border.all(color: timerColor, width: 1.5),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                    color: timerColor.withValues(alpha: 0.3), blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: timerColor, size: 13),
                const SizedBox(width: 3),
                Text(
                  '${timeLeft}s',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Undo/Redo/Clear (drawer only)
          if (isDrawer) ...[
            GestureDetector(
              onTap: onUndo,
              child: const Icon(Icons.undo_rounded,
                  color: Color(0xFF8BA896), size: 22),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRedo,
              child: const Icon(Icons.redo_rounded,
                  color: Color(0xFF8BA896), size: 22),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.delete_outline,
                  color: Color(0xFFFF2D55), size: 22),
            ),
            const SizedBox(width: 8),
          ],

          // Word display (center, expanded)
          Expanded(
            child: Center(child: wordWidget),
          ),

          // Round indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1F3A30), width: 2),
            ),
            child: Text(
              '${room?.currentRound ?? 0} / ${room?.maxRounds ?? 3}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterRow(List<String> chars) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: chars.asMap().entries.map((entry) {
          final ch = entry.value;
          if (ch == ' ') {
            return const SizedBox(width: 12);
          }
          final isRevealed = ch != '_';
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRevealed ? ch.toUpperCase() : '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  width: 18,
                  height: 2.5,
                  color: isRevealed
                      ? const Color(0xFF39FF14)
                      : Colors.white54,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// _ToolBar — brush sizes + palette + eraser (drawer only)
// ═══════════════════════════════════════════════════════════════════
class _ToolBar extends ConsumerWidget {
  final String roomId;
  const _ToolBar({required this.roomId});

  static const _paletteRow1 = [
    Color(0xFF161320),
    Colors.white,
    Color(0xFFEF3A40),
    Color(0xFFF06511),
    Color(0xFFFBD414),
    Color(0xFF10B543),
  ];
  static const _paletteRow2 = [
    Color(0xFF2E88F9),
    Color(0xFF635CFB),
    Color(0xFFB047FF),
    Color(0xFFE53086),
    Color(0xFFDBAE7E),
    Color(0xFF6A7482),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(toolStateProvider);
    final notifier = ref.read(toolStateProvider.notifier);

    return Container(
      color: const Color(0xFF061A19),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brush sizes + eraser
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _SizeBtn(sz: 4, sel: tool.size == 4, onTap: () => notifier.setSize(4)),
                  const SizedBox(width: 10),
                  _SizeBtn(sz: 8, sel: tool.size == 8, onTap: () => notifier.setSize(8)),
                  const SizedBox(width: 10),
                  _SizeBtn(sz: 16, sel: tool.size == 16, onTap: () => notifier.setSize(16)),
                  const SizedBox(width: 10),
                  _SizeBtn(sz: 24, sel: tool.size == 24, onTap: () => notifier.setSize(24)),
                ],
              ),
              GestureDetector(
                onTap: notifier.toggleEraser,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tool.isErasing
                        ? const Color(0xFFE0B376).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tool.isErasing
                          ? const Color(0xFFE0B376)
                          : const Color(0xFF1F3A30),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.format_paint_outlined,
                    color: tool.isErasing
                        ? const Color(0xFFE0B376)
                        : const Color(0xFF5A706F),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Color palette row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _paletteRow1
                .map((c) => _ColorBtn(c: c, tool: tool, notifier: notifier))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Color palette row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _paletteRow2
                .map((c) => _ColorBtn(c: c, tool: tool, notifier: notifier))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ColorBtn extends StatelessWidget {
  final Color c;
  final ToolState tool;
  final ToolStateNotifier notifier;
  const _ColorBtn({required this.c, required this.tool, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final selected = tool.color == c && !tool.isErasing;
    return GestureDetector(
      onTap: () {
        if (tool.isErasing) notifier.toggleEraser();
        notifier.setColor(c);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? 40 : 36,
        height: selected ? 40 : 36,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFE0B376) : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFFE0B376).withValues(alpha: 0.6), blurRadius: 10)]
              : null,
        ),
      ),
    );
  }
}

class _SizeBtn extends StatelessWidget {
  final double sz;
  final bool sel;
  final VoidCallback onTap;
  const _SizeBtn({required this.sz, required this.sel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: sel ? const Color(0xFFE0B376) : const Color(0xFF1F3A30),
            width: sel ? 2 : 1,
          ),
          boxShadow: sel
              ? [BoxShadow(color: const Color(0xFFE0B376).withValues(alpha: 0.35), blurRadius: 8)]
              : null,
        ),
        child: Center(
          child: Container(
            width: sz.clamp(4, 22),
            height: sz.clamp(4, 22),
            decoration: const BoxDecoration(
              color: Color(0xFF8BA896),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
