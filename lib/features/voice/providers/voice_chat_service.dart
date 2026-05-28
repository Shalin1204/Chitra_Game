import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../realtime/providers/realtime_providers.dart';
import '../../realtime/socket/socket_service.dart';

// Placeholder App ID. The user must replace this with their actual Agora App ID.
const String agoraAppId = '<YOUR_AGORA_APP_ID>';

final voiceChatProvider = StateNotifierProvider<VoiceChatNotifier, VoiceChatState>((ref) {
  final socket = ref.watch(socketServiceProvider);
  return VoiceChatNotifier(socket);
});

class VoiceChatState {
  final bool isJoined;
  final bool isMuted;
  final bool hasError;
  final String errorMessage;

  const VoiceChatState({
    this.isJoined = false,
    this.isMuted = true,
    this.hasError = false,
    this.errorMessage = '',
  });

  VoiceChatState copyWith({
    bool? isJoined,
    bool? isMuted,
    bool? hasError,
    String? errorMessage,
  }) {
    return VoiceChatState(
      isJoined: isJoined ?? this.isJoined,
      isMuted: isMuted ?? this.isMuted,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VoiceChatNotifier extends StateNotifier<VoiceChatState> {
  RtcEngine? _engine;
  final SocketService _socket;

  VoiceChatNotifier(this._socket) : super(const VoiceChatState()) {
    _socket.onVoiceSignal = (data) {
      if (data['action'] == 'force_mute') {
        _forceMute();
      }
    };
  }

  void _forceMute() async {
    if (_engine != null && !state.isMuted) {
      await _engine!.muteLocalAudioStream(true);
      state = state.copyWith(isMuted: true);
    }
  }

  Future<void> initAgora() async {
    if (agoraAppId == '<YOUR_AGORA_APP_ID>') {
      state = state.copyWith(hasError: true, errorMessage: 'Agora App ID missing');
      return;
    }

    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          state = state.copyWith(isJoined: true, hasError: false);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          state = state.copyWith(isJoined: false);
        },
        onError: (ErrorCodeType err, String msg) {
          state = state.copyWith(hasError: true, errorMessage: msg);
        },
      ),
    );

    // Set audio profile
    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    
    await _engine!.enableAudio();
    // Default to muted until user actively unmutes
    await _engine!.muteLocalAudioStream(state.isMuted);
  }

  Future<void> joinChannel(String roomId) async {
    if (_engine == null) await initAgora();
    if (state.hasError && agoraAppId == '<YOUR_AGORA_APP_ID>') return;
    
    // Set client role to broadcaster so they can speak if unmuted
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    await _engine!.joinChannel(
      token: '', // Leave empty if token auth is disabled in Agora console
      channelId: roomId,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
    }
  }

  Future<void> toggleMute() async {
    if (_engine != null) {
      final newMuteState = !state.isMuted;
      await _engine!.muteLocalAudioStream(newMuteState);
      state = state.copyWith(isMuted: newMuteState);
    }
  }

  // Admin mute functionality
  Future<void> muteRemoteUser(int uid) async {
    if (_engine != null) {
      // In Agora, to mute a specific remote user locally:
      // await _engine!.muteRemoteAudioStream(uid: uid, mute: true);
      
      // However, to force-mute them globally, you either need a server-side kick,
      // or send a signaling message via Socket.io instructing them to mute themselves.
      // We'll rely on the socket service to handle global mutes for admins.
    }
  }

  @override
  void dispose() {
    _engine?.release();
    super.dispose();
  }
}
