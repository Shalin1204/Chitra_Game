/**
 * registerVoiceHandlers — relays WebRTC signaling messages (SDP + ICE).
 *
 * Signaling flow:
 *   1. Peer A sends voice_signal { type: 'offer', to: peerId, sdp }
 *   2. Server forwards to peerId
 *   3. Peer B sends voice_signal { type: 'answer', to: peerId, sdp }
 *   4. ICE candidates exchanged via { type: 'ice', to: peerId, candidate }
 */
function registerVoiceHandlers(io, socket, roomManager) {
  socket.on('voice_signal', (signal) => {
    const { to, ...rest } = signal;
    if (!to) return;
    // Forward to the specific peer
    io.to(to).emit('voice_signal', { ...rest, from: socket.id });
  });
}

module.exports = registerVoiceHandlers;