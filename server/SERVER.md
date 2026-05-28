# Chitra Game — Node.js Backend

Real-time WebSocket server powering the Chitra Game multiplayer drawing game.

---

## Stack

- **Runtime:** Node.js 18+
- **WebSockets:** Socket.IO 4
- **IDs:** `uuid` v9
- **Dev:** `nodemon`

---

## Start

```bash
npm install
npm run dev      # nodemon (auto-reload)
npm start        # production
```

Server listens on `PORT` env variable, defaulting to **3000**.

---

## Directory Layout

```
src/
├── index.js                  # Entry — HTTP server + Socket.IO init + handler registration
├── rooms/
│   ├── room_manager.js       # RoomManager: creates/joins/leaves rooms, manages player state
│   └── words.js              # 60+ words in 6 categories, getRandomWords() returns {word, category}
├── sockets/
│   └── room_handlers.js      # join_room, leave_room, start_game, select_word, chat_message
├── canvas/
│   └── canvas_handlers.js    # draw_stroke, clear_canvas relay
├── chaos/
│   └── chaos_scheduler.js    # Schedules and emits random chaos_event during gameplay
├── voice/
│   └── voice_handlers.js     # Forwards host mute signals to target players
├── replay/                   # (WIP) Stroke recording and playback
├── middleware/               # Auth / rate-limit middleware
└── utils/                    # Shared server utilities
```

---

## Socket Events

### Client → Server

| Event | Payload | Notes |
|---|---|---|
| `join_room` | `{ code, name, avatar }` | `code = "NEW"` creates a room |
| `leave_room` | — | |
| `start_game` | — | Host only |
| `ready_up` | — | Non-host players in lobby |
| `select_word` | `{ word }` | Drawer only, during `wordSelection` |
| `chat_message` | `{ text }` | Guesses validated server-side |
| `draw_stroke` | `{ stroke }` | Relayed to room (drawer only) |
| `clear_canvas` | — | Relayed to room (drawer only) |
| `voice_signal` | `{ action, targetId }` | Host mutes player |

### Server → Client

| Event | Payload | Notes |
|---|---|---|
| `room_state` | Room object | `currentWord` hidden during play |
| `round_state` | `{ status, round, maxRounds, drawerId? }` | |
| `word_choices` | `{ words: [{word, category}] }` | Private — drawer socket only |
| `timer_update` | `{ timeRemaining }` | Every 1 second |
| `chat_message` | `{ id, sender, text, isSystem, color }` | |
| `chaos_event` | `{ type }` | Random modifier trigger |
| `error` | `{ message }` | |

---

## Room State Shape

```js
{
  id: string,
  code: string,           // 6-char uppercase join code
  hostId: string,
  players: Player[],
  gameMode: string,       // 'normal' | 'chaos'
  status: string,         // 'waiting' | 'wordSelection' | 'drawing' | 'turnEnd' | 'finished'
  currentRound: number,
  maxRounds: number,      // Default: 3
  drawerId: string,
  currentWord: string,    // Hidden (empty) during play; revealed at turnEnd
  wordLength: number,
  timeRemaining: number,
  maxTurnTime: number,    // Fixed 30s per round
  revealedLetters: (string|null)[],  // null=hidden, string=revealed char
  guessedPlayers: string[],
}
```

### Player Shape

```js
{
  id: string,           // Socket ID
  displayName: string,
  avatar: string,       // Emoji (e.g. '👽'), defaults to '👽'
  cursorColor: string,  // Hex from PLAYER_COLORS palette
  isHost: boolean,
  role: 'artist',
  score: number,
  isReady: boolean,     // For lobby ready up
  isOnline: boolean,
}
```

---

## Scoring

- **Correct guess:** `Math.round(timeRemaining × 10)` points for the guesser
- **Drawer bonus:** `+50` points for each player who guesses correctly
- Drawer does **not** earn bonus if no one guesses
- Drawer **cannot send chat** during drawing phase

---

## Timer Rules (Skribbl-style)

| Round | Turn Time |
|---|---|
| All Rounds | **30 seconds** |

---

## Word Hint System

- `revealedLetters[i]` = `null` means hidden; a letter string means revealed
- Spaces are always revealed
- **On any guess** — correct-position letters are revealed to everyone
- **At 50% time remaining** — 1 random letter auto-revealed
- **At 25% time remaining** — 1 more random letter auto-revealed  
- **On turn end / all guessed** — all letters revealed

---

## Game Loop Flow

```
start_game  (host)
  └─► _startTurn(index = 0)
        ├─ status = 'wordSelection'
        ├─ Broadcast room_state
        └─ Emit word_choices to drawer only

select_word  (drawer)
  ├─ status = 'drawing'
  ├─ turnTime = 30s (Fixed)
  ├─ revealedLetters initialized (all null except spaces)
  └─ Start countdown setInterval

    [every second] → emit timer_update
    [at 50% time ] → reveal 1 random hidden letter + broadcast
    [at 25% time ] → reveal 1 more hidden letter + broadcast

    chat_message (guesser)
      └─ Match currentWord (case-insensitive)
           ├─ Exact: +score, reveal all letters, system msg
           └─ Partial: reveal correct-position chars, system msg

    Drawer chat → blocked (no-op)

    All guessed OR timer ≤ 0
      └─► _endTurn()
            ├─ status = 'turnEnd'
            ├─ Reveal full word
            └─ After 5s → _startTurn(next index)

  All players drawn → currentRound++
  currentRound > maxRounds → status = 'finished' + scores
```

---

## Word Categories

Defined in `src/rooms/words.js`:

| Category | Count |
|---|---|
| Animals | 11 |
| Objects | 10 |
| Food / Eating Thing | 9 |
| Nature | 8 |
| Trending Movie Character | 8 |
| Mythical / Sci-Fi | 8 |

`getRandomWords(count = 3)` — flattens all categories into `{word, category}` pairs, shuffles, returns first `count`.

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3000` | HTTP server port |

Create a `.env` file in `server/`:
```
PORT=3000
```
