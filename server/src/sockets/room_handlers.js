/**
 * registerRoomHandlers — handles room join/leave/start events.
 * Imported by index.js and called per-socket connection.
 *
 * Timer rules (Skribbl-style):
 *  - Round 1: 90 seconds per turn
 *  - Round 2: 80 seconds per turn
 *  - Round 3: 70 seconds per turn
 *  - Each round all players get one turn as drawer.
 *
 * Word hints:
 *  - revealedLetters: array of chars, null = hidden, letter = revealed
 *  - Any guess that has a correct letter at the correct position reveals it
 *  - At 50% time remaining, one random letter is auto-revealed
 *  - At 25% time remaining, another random letter is auto-revealed
 */
const { getRandomWords } = require('../rooms/words');

const BASE_TURN_TIME = 30; // seconds for all rounds
const TIME_REDUCTION_PER_ROUND = 0; // do not reduce time

function registerRoomHandlers(io, socket, roomManager, chaosScheduler) {
  socket.on('join_room', ({ code, name, avatar }) => {
    let room;
    if (code === 'NEW') {
      room = roomManager.createRoom(socket.id, name, avatar, 'normal');
    } else {
      room = roomManager.joinRoom(socket.id, code, name, avatar);
    }
    if (!room) {
      socket.emit('error', { message: 'Room not found or full' });
      return;
    }
    socket.join(room.id);
    _emitSafeRoomState(io, room);
  });

  socket.on('leave_room', () => {
    const room = roomManager.leaveRoom(socket.id);
    if (room) {
      socket.leave(room.id);
      _emitSafeRoomState(io, room);
    }
  });

  socket.on('ready_up', () => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return;
    const player = room.players.find(p => p.id === socket.id);
    if (player) {
      player.isReady = !player.isReady;
      _emitSafeRoomState(io, room);
    }
  });

  // GAME LOOP
  socket.on('start_game', () => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room || room.hostId !== socket.id || room.players.length === 0) return;
    room.status = 'inProgress';
    room.currentRound = 1;
    io.to(room.id).emit('round_state', {
      status: room.status,
      round: room.currentRound,
      maxRounds: room.maxRounds,
    });
    _startTurn(io, room, 0);
  });

  socket.on('select_word', ({ word }) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room || room.drawerId !== socket.id || room.status !== 'wordSelection') return;

    const turnTime = Math.max(
      30,
      BASE_TURN_TIME - (room.currentRound - 1) * TIME_REDUCTION_PER_ROUND
    );

    room.currentWord = word;
    room.wordLength = word.length;
    room.status = 'drawing';
    room.timeRemaining = turnTime;
    room.maxTurnTime = turnTime;

    // Initialize revealed letters — spaces are always shown, letters are null (hidden)
    room.revealedLetters = word.split('').map(ch => (ch === ' ' ? ' ' : null));

    _emitSafeRoomState(io, room);

    io.to(room.id).emit('chat_message', {
      id: Date.now().toString(),
      sender: 'System',
      text: `${room.players.find(p => p.id === room.drawerId)?.displayName} is drawing!`,
      isSystem: true,
      color: '#00FF00',
    });

    // Track hint milestones
    let hint50Revealed = false;
    let hint25Revealed = false;

    room.turnTimer = setInterval(() => {
      room.timeRemaining--;
      io.to(room.id).emit('timer_update', { timeRemaining: room.timeRemaining });

      // Auto-reveal a letter at 50% time
      if (!hint50Revealed && room.timeRemaining <= Math.floor(turnTime * 0.5)) {
        hint50Revealed = true;
        _revealRandomLetter(io, room);
      }

      // Auto-reveal another letter at 25% time
      if (!hint25Revealed && room.timeRemaining <= Math.floor(turnTime * 0.25)) {
        hint25Revealed = true;
        _revealRandomLetter(io, room);
      }

      if (room.timeRemaining <= 0) {
        _endTurn(io, room);
      }
    }, 1000);
  });

  socket.on('chat_message', ({ text }) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return;

    const player = room.players.find(p => p.id === socket.id);
    if (!player) return;

    // Guessing logic — only for non-drawers who haven't guessed yet
    if (
      room.status === 'drawing' &&
      socket.id !== room.drawerId &&
      !room.guessedPlayers.has(socket.id)
    ) {
      if (text.toLowerCase() === room.currentWord.toLowerCase()) {
        // Correct guess!
        room.guessedPlayers.add(socket.id);
        const points = Math.round(room.timeRemaining * 10);
        player.score += points;
        const drawer = room.players.find(p => p.id === room.drawerId);
        if (drawer) drawer.score += 50;

        // Reveal all remaining letters
        room.revealedLetters = room.currentWord.split('');

        io.to(room.id).emit('chat_message', {
          id: Date.now().toString(),
          sender: 'System',
          text: `${player.displayName} guessed the word! (+${points} pts)`,
          isSystem: true,
          color: '#39FF14',
        });

        _emitSafeRoomState(io, room);

        if (room.guessedPlayers.size >= room.players.length - 1) {
          _endTurn(io, room);
        }
        return;
      } else {
        // Close guess — reveal correct-position letters
        const guessChars = text.toLowerCase().split('');
        const wordChars = room.currentWord.toLowerCase().split('');
        let anyRevealed = false;

        for (let i = 0; i < wordChars.length; i++) {
          if (room.revealedLetters[i] === null && guessChars[i] === wordChars[i]) {
            room.revealedLetters[i] = room.currentWord[i]; // keep original case
            anyRevealed = true;
          }
        }

        if (anyRevealed) {
          // Broadcast updated revealed letters
          _emitSafeRoomState(io, room);
          io.to(room.id).emit('chat_message', {
            id: Date.now().toString(),
            sender: 'System',
            text: `${player.displayName}'s guess revealed a letter! 🔍`,
            isSystem: true,
            color: '#FFE600',
          });
        }
      }
    }

    // Normal chat (drawer sees all chat, guessers see all except hidden word attempts)
    // Drawer cannot send chat while drawing
    if (socket.id === room.drawerId && room.status === 'drawing') return;

    io.to(room.id).emit('chat_message', {
      id: Date.now().toString(),
      sender: player.displayName,
      text,
      isSystem: false,
      color: player.cursorColor,
    });
  });

  socket.on('voice_signal', (data) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return;

    if (data.action === 'mute' && room.hostId === socket.id) {
      io.to(data.targetId).emit('voice_signal', {
        action: 'force_mute',
        senderId: socket.id,
      });
    }
  });

  // ── Internal helpers ────────────────────────────────────────────────────────

  function _revealRandomLetter(io, room) {
    const hidden = room.revealedLetters
      .map((ch, i) => ({ ch, i }))
      .filter(({ ch }) => ch === null);

    if (hidden.length === 0) return;

    const pick = hidden[Math.floor(Math.random() * hidden.length)];
    room.revealedLetters[pick.i] = room.currentWord[pick.i];

    io.to(room.id).emit('chat_message', {
      id: Date.now().toString(),
      sender: 'System',
      text: `Hint: a new letter has been revealed!`,
      isSystem: true,
      color: '#00D4FF',
    });

    _emitSafeRoomState(io, room);
  }

  function _getTurnTime(room) {
    return Math.max(30, BASE_TURN_TIME - (room.currentRound - 1) * TIME_REDUCTION_PER_ROUND);
  }

  function _startTurn(io, room, drawerIndex) {
    if (!room || !room.players || room.players.length === 0) return;

    if (drawerIndex >= room.players.length) {
      // All players had a turn this round — advance round
      room.currentRound++;
      if (room.currentRound > room.maxRounds) {
        room.status = 'finished';
        io.to(room.id).emit('round_state', {
          status: room.status,
          round: room.currentRound - 1,
          maxRounds: room.maxRounds,
          scores: room.players.map(p => ({ name: p.displayName, avatar: p.avatar, score: p.score })),
        });
        _emitSafeRoomState(io, room);
        return;
      }
      drawerIndex = 0;

      io.to(room.id).emit('chat_message', {
        id: Date.now().toString(),
        sender: 'System',
        text: `🏁 Round ${room.currentRound} starts! Turn time: ${_getTurnTime(room)}s`,
        isSystem: true,
        color: '#BF5FFF',
      });
    }

    room.drawerIndex = drawerIndex;
    room.drawerId = room.players[drawerIndex].id;
    room.status = 'wordSelection';
    room.guessedPlayers.clear();
    room.currentWord = '';
    room.wordLength = 0;
    room.revealedLetters = [];

    io.to(room.id).emit('round_state', {
      status: room.status,
      round: room.currentRound,
      maxRounds: room.maxRounds,
      drawerId: room.drawerId,
    });
    _emitSafeRoomState(io, room);

    const words = getRandomWords(3);
    io.to(room.drawerId).emit('word_choices', { words });
  }

  function _endTurn(io, room) {
    if (room.turnTimer) {
      clearInterval(room.turnTimer);
      room.turnTimer = null;
    }

    // Reveal full word on turn end
    if (room.currentWord) {
      room.revealedLetters = room.currentWord.split('');
    }

    room.status = 'turnEnd';
    io.to(room.id).emit('round_state', {
      status: room.status,
      round: room.currentRound,
      maxRounds: room.maxRounds,
    });
    _emitSafeRoomState(io, room);

    io.to(room.id).emit('chat_message', {
      id: Date.now().toString(),
      sender: 'System',
      text: `The word was: ${room.currentWord}`,
      isSystem: true,
      color: '#FF2D55',
    });

    setTimeout(() => {
      _startTurn(io, room, room.drawerIndex + 1);
    }, 5000);
  }

  function _emitSafeRoomState(io, room) {
    const safeRoom = { ...room };
    safeRoom.guessedPlayers = Array.from(room.guessedPlayers);
    delete safeRoom.turnTimer;
    delete safeRoom.chaosTimer;

    // Hide current word from guessers during drawing/selection.
    // Revealed letters are safe to send — they only show guessed chars.
    if (safeRoom.status === 'drawing' || safeRoom.status === 'wordSelection') {
      safeRoom.currentWord = '';
    }

    // Drawer gets revealedLetters = full word (they already know it)
    // Others get the partial revealedLetters array
    io.to(room.id).emit('room_state', safeRoom);
  }
}

module.exports = registerRoomHandlers;