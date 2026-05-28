const CHAOS_EVENTS = [
  { type: 'reverseControls', label: 'REVERSED!', emoji: '🔄', duration: 15 },
  { type: 'fogCanvas', label: 'FOG OF WAR', emoji: '🌫️', duration: 12 },
  { type: 'rainbowMode', label: 'RAINBOW MODE', emoji: '🌈', duration: 20 },
  { type: 'giantBrush', label: 'GIANT BRUSH!', emoji: '🖌️', duration: 10 },
  { type: 'mirrorMode', label: 'MIRROR MIRROR', emoji: '🪞', duration: 15 },
  { type: 'invisibleInk', label: 'INVISIBLE INK', emoji: '👻', duration: 10 },
  { type: 'earthquake', label: 'EARTHQUAKE!', emoji: '🌍', duration: 8 },
  { type: 'delayedStrokes', label: 'LAG MODE', emoji: '⏳', duration: 12 },
];

const INTERVAL_MS = 45_000; // 45 seconds

/**
 * ChaosScheduler — fires random chaos events every INTERVAL_MS
 * for rooms in chaos game mode.
 */
class ChaosScheduler {
  /** @param {import('socket.io').Server} io */
  constructor(io, roomManager) {
    this.io = io;
    this.roomManager = roomManager;
    /** @type {Map<string, NodeJS.Timeout>} roomId → interval */
    this.timers = new Map();
  }

  start(roomId) {
    if (this.timers.has(roomId)) return;
    const timer = setInterval(() => this._fire(roomId), INTERVAL_MS);
    this.timers.set(roomId, timer);
    console.log(`[Chaos] Scheduler started for room ${roomId}`);
  }

  stop(roomId) {
    const timer = this.timers.get(roomId);
    if (timer) clearInterval(timer);
    this.timers.delete(roomId);
  }

  _fire(roomId) {
    const room = this.roomManager.rooms.get(roomId);
    if (!room || room.status !== 'inProgress') return;

    const event = CHAOS_EVENTS[Math.floor(Math.random() * CHAOS_EVENTS.length)];
    const payload = {
      id: `${roomId}_${Date.now()}`,
      ...event,
    };

    this.io.to(roomId).emit('chaos_event', payload);
    console.log(`[Chaos] Fired "${event.type}" in room ${roomId}`);
  }
}

module.exports = ChaosScheduler;