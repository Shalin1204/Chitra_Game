const { v4: uuidv4 } = require('uuid');
const PLAYER_COLORS = ['#39FF14','#FF2D55','#00D4FF','#FFE600','#BF5FFF','#FF6B00','#FF69B4','#00FFFF'];

/**
 * RoomManager — tracks all active rooms and players.
 *
 * Room shape:
 * {
 *   id: string,
 *   code: string,
 *   hostId: string,
 *   players: Player[],
 *   gameMode: string,
 *   status: 'waiting' | 'countdown' | 'inProgress' | 'roundEnd' | 'finished',
 *   currentRound: number,
 *   maxRounds: number,
 *   chaosTimer: NodeJS.Timeout | null,
 * }
 */
class RoomManager {
  constructor() {
    /** @type {Map<string, object>} roomId → room */
    this.rooms = new Map();
    /** @type {Map<string, string>} socketId → roomId */
    this.socketToRoom = new Map();
  }

  createRoom(socketId, displayName, avatar, gameMode = 'normal') {
    const id = uuidv4();
    const code = this._generateCode();
    const player = this._makePlayer(socketId, displayName, avatar, true);
    const room = {
      id, code, hostId: socketId,
      players: [player],
      gameMode,
      status: 'waiting', // waiting, wordSelection, drawing, turnEnd, roundEnd
      currentRound: 0,
      maxRounds: 3,
      drawerId: null,
      currentWord: '',
      wordLength: 0,
      turnTimer: null,
      timeRemaining: 0,
      chaosTimer: null,
      drawerIndex: -1,
      guessedPlayers: new Set(),
    };
    this.rooms.set(id, room);
    this.socketToRoom.set(socketId, id);
    return room;
  }

  joinRoom(socketId, code, displayName, avatar) {
    const room = [...this.rooms.values()].find((r) => r.code === code);
    if (!room) return null;
    if (room.players.length >= 8) return null;
    const player = this._makePlayer(socketId, displayName, avatar, false);
    room.players.push(player);
    this.socketToRoom.set(socketId, room.id);
    return room;
  }

  leaveRoom(socketId) {
    const roomId = this.socketToRoom.get(socketId);
    if (!roomId) return null;
    const room = this.rooms.get(roomId);
    if (!room) return null;
    room.players = room.players.filter((p) => p.id !== socketId);
    this.socketToRoom.delete(socketId);
    if (room.players.length === 0) {
      this.rooms.delete(roomId);
      return null;
    }
    // Reassign host if needed
    if (room.hostId === socketId && room.players.length > 0) {
      room.hostId = room.players[0].id;
      room.players[0].isHost = true;
    }
    return room;
  }

  handleDisconnect(socketId, io) {
    const room = this.leaveRoom(socketId);
    if (room) {
      io.to(room.id).emit('room_state', room);
    }
  }

  getRoomBySocket(socketId) {
    const roomId = this.socketToRoom.get(socketId);
    return roomId ? this.rooms.get(roomId) : null;
  }

  _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
  }

  _makePlayer(socketId, displayName, avatar, isHost) {
    return {
      id: socketId,
      displayName,
      avatar: avatar || '👽',
      cursorColor: PLAYER_COLORS[Math.floor(Math.random() * PLAYER_COLORS.length)],
      isHost,
      role: 'artist',
      score: 0,
      isOnline: true,
    };
  }
}

module.exports = RoomManager;