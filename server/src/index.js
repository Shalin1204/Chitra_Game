const { createServer } = require('http');
const { Server } = require('socket.io');
const RoomManager = require('./rooms/room_manager');
const ChaosScheduler = require('./chaos/chaos_scheduler');
const registerCanvasHandlers = require('./canvas/canvas_handlers');
const registerRoomHandlers = require('./sockets/room_handlers');
const registerVoiceHandlers = require('./voice/voice_handlers');

const PORT = process.env.PORT || 3000;

const httpServer = createServer();
const io = new Server(httpServer, {
  cors: { origin: '*' },
  transports: ['websocket'],
});

const roomManager = new RoomManager();
const chaosScheduler = new ChaosScheduler(io, roomManager);

io.on('connection', (socket) => {
  console.log(`[+] Client connected: ${socket.id}`);

  // Register feature-specific handlers
  registerRoomHandlers(io, socket, roomManager, chaosScheduler);
  registerCanvasHandlers(io, socket, roomManager);
  registerVoiceHandlers(io, socket, roomManager);

  socket.on('disconnect', () => {
    console.log(`[-] Client disconnected: ${socket.id}`);
    roomManager.handleDisconnect(socket.id, io);
  });
});

httpServer.listen(PORT, () => {
  console.log(`🎮 Chitra Game server running on :${PORT}`);
});
