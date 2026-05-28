import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/retro_ui.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/room_providers.dart';

/// JoinRoomScreen — enter a 6-char room code to join an existing room.
class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeCtrl = TextEditingController();
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(currentUserIdProvider));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _join() {
    if (_codeCtrl.text.trim().length < 4) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ref.read(currentUserIdProvider.notifier).state = name;
    final avatar = ref.read(currentUserAvatarProvider);
    ref.read(roomProvider.notifier).joinRoom(
          _codeCtrl.text.trim().toUpperCase(),
          name,
          avatar,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roomProvider, (prev, next) {
      if (next != null && prev == null) {
        context.go('/room/lobby/${next.id}');
      }
    });

    return ScanlineOverlay(
      child: Scaffold(
        appBar: AppBar(title: const Text('JOIN ROOM')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: RetroPixelBorder(
              borderColor: RetroColors.electricBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ENTER CODE',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 9,
                      color: RetroColors.electricBlue,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 24,
                      color: RetroColors.electricBlue,
                      letterSpacing: 8,
                    ),
                    textAlign: TextAlign.center,
                    cursorColor: RetroColors.electricBlue,
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: const BorderSide(color: RetroColors.electricBlue, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: const BorderSide(color: RetroColors.electricBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  RetroTextField(
                    controller: _nameCtrl,
                    label: 'YOUR NAME',
                  ),
                  const SizedBox(height: 24),
                  RetroButton(
                    label: 'JOIN ▶',
                    onPressed: _join,
                    color: RetroColors.electricBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}