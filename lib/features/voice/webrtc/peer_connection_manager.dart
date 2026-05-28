// flutter_webrtc is imported and configured here.
// This file manages peer connections for voice rooms.
//
// Key classes to implement:
//   PeerConnectionManager  — creates/manages RTCPeerConnection per peer
//   AudioRoomService       — join/leave voice room, mute/unmute
//   SignalingService       — exchanges SDP offers/answers via Socket.IO
//
// Implementation steps:
//   1. flutter_webrtc: getUserMedia (audio only)
//   2. Create RTCPeerConnection with STUN servers
//   3. Use socket onVoiceSignal / emitVoiceSignal for signaling
//   4. Add local stream to peer connection
//   5. Listen for remote streams → attach to AudioElement
//
// IMPORTANT: Keep voice state SEPARATE from drawing state.
// VoiceStateController must NOT import CanvasController.

// import 'package:flutter_webrtc/flutter_webrtc.dart';

class PeerConnectionManager {
  // TODO: implement
  final Map<String, dynamic> _peers = {};

  Future<void> createOffer(String peerId) async {
    // 1. Create RTCPeerConnection
    // 2. Add local audio stream
    // 3. Create SDP offer
    // 4. Emit via socket signaling
  }

  Future<void> handleAnswer(String peerId, Map<String, dynamic> sdp) async {
    // Set remote description
  }

  Future<void> handleIceCandidate(String peerId, Map<String, dynamic> candidate) async {
    // Add ICE candidate
  }

  void closePeer(String peerId) {
    _peers.remove(peerId);
  }

  void dispose() {
    _peers.clear();
  }
}