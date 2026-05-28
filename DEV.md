# 🎨 Chitra Game — Developer Reference

> Realtime multiplayer draw-and-guess game with chaos mode, voice rooms, categorized word packs, and expressive avatars.  
> Built with Flutter (cross-platform) + Node.js (Socket.IO backend).

---

## 📦 Tech Stack

| Layer | Technology |
|---|---|
| **Client** | Flutter 3 (Dart) |
| **State Management** | Riverpod 2 (+ Riverpod Generator) |
| **Realtime** | Socket.IO client (`socket_io_client`) |
| **Navigation** | go_router 13 |
| **Drawing Engine** | `perfect_freehand` |
| **Persistence** | `shared_preferences` |
| **Voice** | Agora RTC Engine 6 |
| **Animations** | `flutter_animate` |
| **Backend Runtime** | Node.js |
| **Backend Realtime** | Socket.IO 4 |
| **Backend Utilities** | `uuid` |
| **Code Gen (client)** | `build_runner`, `freezed`, `json_serializable` |
| **CI/Lint** | `flutter_lints`, `riverpod_lint`, `custom_lint` |

---

## 🗂 Project Structure

```
chaos_canvas/
├── lib/
│   ├── main.dart                  # App entry point, Firebase init, theme setup
│   ├── firebase_options.dart      # Auto-generated Firebase config
│   ├── core/                      # Shared infrastructure
│   │   ├── theme/                 # AppTheme, RetroColors, RetroTextStyles
│   │   ├── routes/                # go_router AppRouter + AppRoutes constants
│   │   ├── widgets/               # RetroButton, RetroTextField, ScanlineOverlay, etc.
│   │   ├── constants/             # App-wide constants
│   │   ├── errors/                # Error handling helpers
│   │   ├── network/               # Network utilities
│   │   ├── services/              # Shared services
│   │   └── utils/                 # Helper utilities
│   ├── shared/
│   │   └── models/
│   │       └── room_model.dart    # Room, Player, WordChoice Dart models
│   └── features/
│       ├── auth/
│       │   └── providers/
│       │       └── auth_provider.dart       # currentUserIdProvider, currentUserAvatarProvider
│       ├── profile/
│       │   └── profile_screen.dart          # Avatar picker + display name entry
│       ├── home/
│       │   └── home_screen.dart             # Create/Join room UI
│       ├── canvas/
│       │   ├── models/canvas_models.dart    # DrawPoint, Stroke, ToolState
│       │   ├── painters/canvas_painter.dart # CustomPainter using perfect_freehand
│       │   ├── providers/canvas_providers.dart # CanvasController, ToolStateNotifier
│       │   └── widgets/
│       │       └── canvas_room_screen.dart  # Main game screen (HUD + canvas + toolbar + chat overlay)
│       ├── room/
│       │   ├── providers/
│       │   │   └── room_providers.dart      # RoomNotifier (handles socket room events)
│       │   └── presentation/
│       │       └── player_list_widget.dart  # Player list with avatars + scores
│       ├── chat/
│       │   └── chat_widget.dart             # Real-time chat + guess submission
│       ├── realtime/
│       │   ├── socket/
│       │   │   └── socket_service.dart      # SocketIO wrapper, emit helpers, callback hooks
│       │   └── providers/
│       │       └── realtime_providers.dart  # socketServiceProvider
│       ├── voice/
│       │   └── providers/
│       │       └── voice_chat_service.dart  # Agora voice channel join/leave/mute
│       ├── chaos_mode/
│       │   └── modifiers/
│       │       └── chaos_overlay.dart       # Visual chaos effects overlay
│       ├── reactions/
│       │   └── overlays/
│       │       └── reaction_overlay.dart    # Floating emoji reactions overlay
│       ├── replay/                          # (WIP) Replay engine
│       └── mini_games/                      # (WIP) Mini-games feature

├── server/
│   ├── package.json               # Node.js manifest (socket.io, uuid, nodemon)
│   ├── .env                       # Environment variables (PORT, etc.)
│   └── src/
│       ├── index.js               # HTTP server + Socket.IO init + handler registration
│       ├── rooms/
│       │   ├── room_manager.js    # RoomManager class — all room/player state
│       │   └── words.js           # Categorized word bank + getRandomWords()
│       ├── sockets/
│       │   └── room_handlers.js   # join_room, leave_room, start_game, select_word, chat_message
│       ├── canvas/
│       │   └── canvas_handlers.js # draw_stroke, clear_canvas socket events
│       ├── chaos/
│       │   └── chaos_scheduler.js # Triggers random chaos events during game
│       ├── voice/
│       │   └── voice_handlers.js  # Voice mute signal forwarding
│       ├── replay/                # Replay recording + playback
│       ├── middleware/            # Auth/rate-limit middleware
│       └── utils/                 # Server-side helpers
```

---

## 🔌 Socket.IO Event Protocol

### Client → Server

| Event | Payload | Description |
|---|---|---|
| `join_room` | `{ code, name, avatar }` | Join existing room (code) or create new one (code = `"NEW"`) |
| `leave_room` | — | Leave the current room |
| `start_game` | — | Host starts the game |
| `select_word` | `{ word }` | Drawer selects one of the offered words |
| `chat_message` | `{ text }` | Send a chat or guess message |
| `draw_stroke` | `{ stroke }` | Stream drawing strokes |
| `clear_canvas` | — | Clear the canvas (drawer only) |
| `voice_signal` | `{ action, targetId }` | Host mutes a specific player |

### Server → Client

| Event | Payload | Description |
|---|---|---|
| `room_state` | `Room` (safe — word hidden) | Full room state broadcast |
| `round_state` | `{ status, round, maxRounds, drawerId? }` | Round lifecycle transitions |
| `word_choices` | `{ words: [{word, category}] }` | Sent **only to the drawer** — 3 word choices |
| `timer_update` | `{ timeRemaining }` | Countdown tick (every second) |
| `chat_message` | `{ id, sender, text, isSystem, color }` | Chat / system notification |
| `chaos_event` | `{ type }` | Triggers a chaos modifier |
| `error` | `{ message }` | Error notification |

---

## 🎮 Game Loop (Server-side)

```
Host: start_game
  └─► _startTurn(drawerIndex=0)
        ├─ room.status = 'wordSelection'
        ├─ Broadcast room_state (word hidden)
        └─ Emit word_choices to drawer only
              │
              Drawer: select_word
              ├─ room.status = 'drawing'
              ├─ Broadcast room_state (word length only)
              └─ Start 80s countdown timer
                    │
                    Every 1s: timer_update
                    │
                    Guess correct → score += timeRemaining × 10
                    Drawer score  += 50 per correct guess
                    │
                    All guessed or timer=0 → _endTurn
                    ├─ room.status = 'turnEnd'
                    ├─ Reveal word in chat
                    └─ After 5s → _startTurn(next player)
                          │
                          All players drawn → next round
                          All rounds done → room.status = 'finished'
```

---

## 🏗 Flutter Architecture

### State Management (Riverpod)

| Provider | Type | Purpose |
|---|---|---|
| `currentUserIdProvider` | `StateProvider<String>` | Logged-in display name |
| `currentUserAvatarProvider` | `StateProvider<String>` | Selected emoji avatar |
| `socketServiceProvider` | `Provider<SocketService>` | Singleton socket wrapper |
| `roomProvider` | `StateNotifier<Room?>` | Full room state |
| `toolStateProvider` | `StateNotifier<ToolState>` | Active color/brush/eraser |
| `canvasControllerProvider` | `StateNotifier<CanvasController>` | Strokes + drawing logic |
| `voiceChatProvider` | `StateNotifier<VoiceState>` | Agora voice channel |

### Key Data Flow

```
SocketService (singleton)
  └─ onRoomState callback ──► RoomNotifier._handleRoomState()
  └─ onWordChoices callback ─► RoomNotifier._handleWordChoices()  [preserved, not overwritten]
  └─ onTimerUpdate callback ─► RoomNotifier._handleTimerUpdate()
  └─ onRoundState callback ──► RoomNotifier._handleRoundState()

RoomNotifier (StateNotifier<Room?>)
  ├─ createRoom(displayName, avatar, mode)  → emit join_room { code: 'NEW', name, avatar }
  ├─ joinRoom(code, displayName, avatar)    → emit join_room { code, name, avatar }
  └─ leaveRoom()                            → emit leave_room
```

---

## 🐛 Bug Fixes Applied

### 1. "Drawer is choosing" — Word Selection Frozen
**Problem:** Server broadcasts a public `room_state` immediately after emitting `word_choices` to the drawer privately. The Flutter `_handleRoomState` was overwriting `wordChoices` with an empty list from the public broadcast, removing the word options from the UI before the drawer could pick one.

**Fix:** `_handleRoomState` in `room_providers.dart` now checks: if the incoming state has `status == 'wordSelection'` AND the current state already has `wordChoices`, preserve them instead of overwriting.

### 2. Color Palette Not Visible
**Problem:** The toolbar used platform-conditional layout that broke color display on certain screen sizes.

**Fix:** Replaced the conditional `isMobile` layout branches with a universal `SingleChildScrollView` wrapping the entire toolbar row. Colors are always accessible via horizontal scroll.

### 3. Remote Strokes Not Synced to Guessers
**Problem:** The drawer's strokes were drawn locally, but guessers couldn't see them because `remoteStrokes` were not connected to the Painter and socket events for `stroke_update` weren't triggering a repaint.

**Fix:** Added a `remoteStrokes` layer to `CanvasPainter` and wired up `SocketService` stroke events to update the remote strokes list and trigger a canvas repaint for all clients.

### 4. Canvas Not Clearing Between Rounds
**Problem:** Players would still see the drawing from the previous round when the next round started.

**Fix:** Added a listener in `CanvasRoomScreen` to detect when the `roomProvider` status changes to `wordSelection` (the start of a new round) and automatically calls `clearCanvas()`.

### 5. Server Crash on Empty Room / Player Leaving
**Problem:** `_startTurn()` in `room_handlers.js` tried to index into `room.players` even if the room was empty or the drawer disconnected, causing `drawerIndex >= room.players.length` to evaluate true but `room.players[drawerIndex]` being undefined.

**Fix:** Added an early exit check for `if (!room || !room.players || room.players.length === 0)` at the top of `_startTurn()`.

---

## 🖼 UI Screens Summary

### Profile Screen (`lib/features/profile/profile_screen.dart`)
- Dark teal theme (`#041C1C`) with gold pixel typography
- Display name input with underline-only `TextField`
- 4-column avatar `GridView` with 20 emoji options  
- Selected avatar highlighted with neon green glow border
- Gradient gold "PLAY" button
- Saves `display_name` + `avatar` to `SharedPreferences`
- Auto-navigates to Home if profile already set

### Canvas Room Screen (`lib/features/canvas/widgets/canvas_room_screen.dart`)
- Full-screen layout: HUD → Canvas → Toolbar
- **Top HUD:** Back arrow, golden timer badge, spaced word display (`C _ _ T _ A`), round counter
- **Canvas:** Cream/beige (`#E5DFD1`) background, `CustomPaint` + `perfect_freehand` rendering
- **Chat Overlay:** Semi-transparent dark bubbles floating over the canvas bottom
- **Bottom Toolbar:** Dark teal (`#061A19`) panel with:
  - 4 brush size selectors (circular, gold border when selected)
  - Eraser toggle
  - 2 rows × 6 colors (rounded square swatches, gold border when selected)

### Player List Widget (`lib/features/room/presentation/player_list_widget.dart`)
- Circular avatar with player's `cursorColor` as border ring
- Player name, score, host/drawer badges
- Highlights green when player has correctly guessed

### Word Choice Overlay
- Appears only to drawer during `wordSelection` status
- Shows 3 options as cards with Category label + Word text
- Tapping emits `select_word` to server

---

## 🔑 Avatar System

- 20 emoji avatars defined in `ProfileScreen._avatars`
- Saved to `SharedPreferences` under key `'avatar'`
- Sent to server via `join_room` socket event as `avatar` field
- Stored per-player in `RoomManager._makePlayer()`, defaulting to `'👽'`
- Displayed in `PlayerListWidget` as circular emoji container

---

## 🗣 Categorized Word System

Words are organized in `server/src/rooms/words.js` across 6 categories:

| Category | Example Words |
|---|---|
| Animals | cat, elephant, unicorn, kangaroo |
| Objects | guitar, piano, bicycle, umbrella |
| Food / Eating Thing | pizza, sushi, taco, pancake |
| Nature | mountain, ocean, jungle, flower |
| Trending Movie Character | Batman, Spider-Man, Deadpool, Joker |
| Mythical / Sci-Fi | dragon, zombie, wizard, alien |

`getRandomWords(count=3)` flattens all categories, shuffles, and returns `{ word, category }` objects. These are sent to the drawer as structured data, allowing the UI to display the category above each word choice.

---

## 🚀 Running Locally

### Backend
```bash
cd server
npm install
npm run dev       # nodemon auto-reloads on change
# Server runs on :3000
```

### Flutter Client
```bash
flutter pub get
flutter run -d chrome   # or android/ios
```

### Environment
- Copy `.env.example` → `.env` in `server/`
- Set `PORT=3000` (default)
- Update `socketUrl` in `lib/core/constants/` to point to your server

---

## 📋 Known Pending Work

- [ ] `replay/` — Stroke-by-stroke game replay
- [ ] `mini_games/` — Mini-game modes
- [x] Persistent leaderboard (Firebase Firestore - Added High Score tracker)
- [ ] Chaos mode: visual glitch effects (`chaos_scheduler.js` + `chaos_overlay.dart`)
- [ ] Gallery screen (saved drawings)
- [ ] Rankings screen (persistent scores)