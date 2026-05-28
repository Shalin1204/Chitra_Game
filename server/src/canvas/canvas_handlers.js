const { throttle } = require('../utils/throttle');

/**
 * registerCanvasHandlers — relays stroke deltas and cursor positions.
 *
 * CRITICAL PERFORMANCE:
 *   - Only stroke DELTAS are sent, never full bitmaps.
 *   - Cursor events are throttled server-side as a second safety net.
 *   - Broadcast excludes the sender (socket.broadcast.to).
 */
function registerCanvasHandlers(io, socket, roomManager) {
  // ── Strokes ──────────────────────────────────────────────────────────────

  socket.on('stroke_start', (data) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return;
    socket.broadcast.to(room.id).emit('stroke_start', data);
  });

  socket.on('stroke_update', (data) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return;
    // Relay the delta — clients append to their in-flight stroke
    socket.broadcast.to(room.id).emit('stroke_update', data);
  });

  socket.on('stroke_end', (data) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return;
    socket.broadcast.to(room.id).emit('stroke_end', data);
  });

  // ── Cursor ────────────────────────────────────────────────────────────────

  const throttledCursor = throttle((data) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return;
    socket.broadcast.to(room.id).emit('cursor_move', {
      uid: socket.id,
      x: data.x,
      y: data.y,
    });
  }, 50); // 20fps max

  socket.on('cursor_move', throttledCursor);

  // ── Reactions ─────────────────────────────────────────────────────────────

  socket.on('reaction', ({ emoji }) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return;
    io.to(room.id).emit('reaction', { uid: socket.id, emoji });
  });
}

module.exports = registerCanvasHandlers;