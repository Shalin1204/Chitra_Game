import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/retro_ui.dart';

/// ReplayScreen — plays back a recorded session event-by-event.
/// Receives a sessionId; loads the session from local device cache/storage.
class ReplayScreen extends StatelessWidget {
  final String sessionId;

  const ReplayScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return ScanlineOverlay(
      child: Scaffold(
        appBar: AppBar(title: const Text('REPLAY')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlowText('⏪ REPLAY',
                  style: RetroTextStyles.pixelTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              Text(
                'SESSION: $sessionId',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 8,
                  color: RetroColors.dimText,
                ),
              ),
              const SizedBox(height: 32),
              // TODO: implement ReplayPlaybackController
              RetroPixelBorder(
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'PLAYBACK COMING SOON',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 9,
                      color: RetroColors.neonGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
