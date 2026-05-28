const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const RoomManager = require('./rooms/room_manager');
const ChaosScheduler = require('./chaos/chaos_scheduler');
const registerCanvasHandlers = require('./canvas/canvas_handlers');
const registerRoomHandlers = require('./sockets/room_handlers');
const registerVoiceHandlers = require('./voice/voice_handlers');

const app = express();

app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

app.get('/', (req, res) => {
  res.send('Chitra Game Server Running');
});

const PORT = process.env.PORT || 3000;

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

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
