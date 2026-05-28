import 'package:flutter_riverpod/flutter_riverpod.dart';

/// voiceActiveProvider — whether the local user's mic is active.
final voiceActiveProvider = StateProvider<bool>((ref) => false);

/// voiceSpeakingProvider — set of userIds currently speaking.
final voiceSpeakingProvider = StateProvider<Set<String>>((ref) => {});

// TODO: implement PeerConnectionManager + AudioRoomService using flutter_webrtc
// See: lib/features/voice/webrtc/peer_connection_manager.dart
// See: lib/features/voice/services/audio_room_service.dart
// See: lib/features/voice/signaling/signaling_service.dart