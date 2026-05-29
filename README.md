<div align="center">

# 🎨 Chitra Game

**A real-time multiplayer draw-and-guess game — think Skribbl.io, but with chaos mode, voice chat, expressive avatars, and categorized word packs.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Socket.IO-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![Socket.IO](https://img.shields.io/badge/Socket.IO-4.x-010101?style=for-the-badge&logo=socket.io&logoColor=white)](https://socket.io)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.x-00B4D8?style=for-the-badge)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## ✨ What is Chitra Game?

Chitra Game is a **cross-platform multiplayer drawing party game** built entirely from scratch. Players take turns drawing a secret word while others race to guess it in real-time chat. What sets it apart:

- 🌀 **Chaos Mode** — Random visual modifiers activate mid-game to shake things up *(Upcoming)*
- 🎙 **Voice Chat** — Built-in Agora-powered voice rooms so you can laugh with friends while playing  
- 🏷 **Categorized Words** — Words come with context: *"Trending Movie Character: Deadpool"* — not just random nouns
- 👽 **Expressive Avatars & Profiles** — Choose from 20 unique emoji avatars and track your all-time High Score (powered by Firebase)
- ⚡ **Real-time Everything** — Live drawing strokes, guesses, timers, and lobby "Ready Up" states sync instantly over WebSockets
- 🎨 **Advanced Canvas** — Smooth pressure-sensitive drawing with Undo/Redo support and a draggable chat panel for a better view

---

## 📱 Screenshots

> *Coming soon — deploy and screenshot the live app!*

---

## 🧰 Tech Stack

### Frontend — Flutter (Cross-Platform)

| Technology | Purpose |
|---|---|
| **Flutter 3** | Cross-platform UI (Android, iOS, Web, Desktop) |
| **Riverpod 2** | Declarative, compile-safe state management |
| **go_router** | Declarative navigation with deep linking |
| **socket_io_client** | WebSocket real-time communication |
| **perfect_freehand** | Smooth, pressure-sensitive drawing strokes |
| **flutter_animate** | Micro-animations and UI transitions |
| **Agora RTC Engine** | Low-latency in-game voice chat |
| **shared_preferences** | Local persistence (profile, avatar, name) |
| **freezed + json_serializable** | Immutable models + JSON serialization |

### Backend — Node.js

| Technology | Purpose |
|---|---|
| **Node.js** | Server runtime |
| **Socket.IO 4** | WebSocket event bus (rooms, canvas, voice signals) |
| **uuid** | Unique room/player ID generation |
| **nodemon** | Auto-reload during development |

---

## 🎮 How It Works

```
┌─────────────────────────────────────────────────────────┐
│                     GAME LOOP                           │
│                                                         │
│  1. Host creates room → shares 6-char code              │
│  2. Players join with display name + emoji avatar       │
│  3. Players click "Ready Up" in the lobby               │
│  4. Host starts the game when ready                     │
│  5. Each round: one player becomes the Drawer           │
│     └── Drawer gets 3 secret word choices with          │
│         categories (e.g., "Food: Sushi")                │
│  6. Drawer draws (Live sync) → others type guesses      │
│     └── Correct guess = points based on time remaining  │
│     └── Drawer gets +50 per correct guesser             │
│  7. Turn ends when timer hits 0 or all players guess    │
│  8. Word revealed → next player draws → repeat          │
│  9. After all rounds → final scoreboard                 │
│ 10. High scores sync securely to Firebase profile       │
└─────────────────────────────────────────────────────────┘
```

---

## 🗂 Project Structure

```
chaos_canvas/
│
├── 📱 lib/                         # Flutter client
│   ├── main.dart                   # App entry, Firebase init
│   ├── core/                       # Design system & infrastructure
│   │   ├── theme/                  # Colors, typography, widgets
│   │   └── routes/                 # App routing (go_router)
│   ├── shared/models/              # Shared data models (Room, Player, WordChoice)
│   └── features/                   # Feature modules
│       ├── profile/                # Avatar picker + name setup
│       ├── home/                   # Create / Join room
│       ├── canvas/                 # Drawing board + toolbar + HUD
│       ├── room/                   # Room state + player list
│       ├── chat/                   # Real-time guess chat
│       ├── voice/                  # Agora voice integration
│       ├── chaos_mode/             # Chaos visual effects
│       ├── reactions/              # Floating emoji reactions
│       ├── replay/                 # (WIP) Stroke replay engine
│       └── mini_games/             # (WIP) Mini-game modes
│
└── 🖥 server/                      # Node.js backend
    └── src/
        ├── index.js                # Server entry, Socket.IO init
        ├── rooms/
        │   ├── room_manager.js     # Room & player state management
        │   └── words.js            # Categorized word bank (6 categories, 60+ words)
        ├── sockets/
        │   └── room_handlers.js    # Game loop, scoring, chat logic
        ├── canvas/                 # Canvas event relay
        ├── chaos/                  # Chaos event scheduler
        └── voice/                  # Voice signal forwarding
```

---

## 🏷 Word Categories

The word bank is organized into themed categories — displayed to the drawer when choosing their word:

| 🐾 Animals | 🎸 Objects | 🍕 Food | 🌿 Nature | 🦸 Movie Characters | 🐉 Mythical |
|---|---|---|---|---|---|
| Elephant | Guitar | Pizza | Mountain | Batman | Dragon |
| Unicorn | Piano | Sushi | Jungle | Spider-Man | Wizard |
| Kangaroo | Bicycle | Tacos | Ocean | Deadpool | Vampire |
| ... | ... | ... | ... | ... | ... |

---

## ⚡ Real-time Architecture

```
Flutter Client                    Node.js Server
     │                                 │
     │── join_room ──────────────────► │  Create/Join room
     │◄─ room_state ────────────────── │  Broadcast to all
     │                                 │
     │── start_game ───────────────── ►│  Host triggers game
     │◄─ word_choices ─────────────── │  Sent ONLY to drawer (private)
     │◄─ room_state ────────────────── │  Broadcast (word hidden)
     │                                 │
     │── select_word ──────────────── ►│  Drawer picks a word
     │◄─ timer_update (×80) ────────── │  1-second countdown
     │                                 │
     │── chat_message ─────────────── ►│  Player guesses
     │◄─ chat_message (correct!) ───── │  Server validates + awards points
     │◄─ room_state ────────────────── │  Updated scores
     │                                 │
     │◄─ chaos_event ───────────────── │  Random mid-game modifier
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0
- Node.js ≥ 18
- Android Studio / Xcode (for mobile)

### 1. Clone the repo
```bash
git clone https://github.com/yourusername/chitra-game.git
cd chitra-game
```

### 2. Start the backend
```bash
cd server
npm install
npm run dev
# ✅ Server listening on :3000
```

### 3. Run the Flutter app
```bash
cd ..
flutter pub get
flutter run -d chrome     # Web
flutter run -d android    # Android
flutter run -d ios        # iOS
```

### 4. Configure server URL
Update your server URL in `lib/core/constants/` to point at your backend (localhost or deployed URL).

---

## 🌐 Deployment

### Backend
The Node.js server can be deployed to any platform supporting WebSockets:
- **Railway** — `railway up` (recommended, free tier available)
- **Render** — Connect GitHub repo, set start command to `node src/index.js`
- **Fly.io** — `fly launch` + `fly deploy`

### Flutter Web
```bash
flutter build web
# Deploy `build/web/` to Firebase Hosting, Vercel, or Netlify
```

---

## 🏗 Key Engineering Decisions

### Why Riverpod?
Riverpod's compile-time safety and provider scoping makes it ideal for a game where state (room, canvas, tool, voice) is deeply interconnected but needs to stay isolated per feature.

### Why Socket.IO over Firebase Realtime?
Socket.IO gives us full control over the game event protocol — custom events, room namespacing, and the ability to send private events to specific sockets (e.g., `word_choices` to the drawer only). Firebase RTDB doesn't support socket-level granularity out of the box.

### Word Choice Privacy
The server sends `word_choices` **only to the drawer's socket** (not broadcast). The public `room_state` hides `currentWord`. The Flutter client preserves `wordChoices` locally and doesn't let incoming `room_state` overwrites clear them during `wordSelection` — fixing the "Drawer is choosing" bug.

### `perfect_freehand`
Instead of rendering raw `Path` objects, strokes are rendered using `perfect_freehand` which produces smooth, variable-width Bézier curves that simulate natural brush pressure — making drawings look expressive rather than jagged.

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -m 'feat: add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📄 License

MIT © Shalin Mishra — see [LICENSE](LICENSE) for details.

---

<div align="center">
    
## 📱 Download APK

Try the latest Android build of Chitra Game:

👉 [Download APK](LINK_TO_APK)

### Features Included
- Real-time multiplayer drawing
- Live guess chat
- Room code system
- Emoji avatars
- Firebase profile storage
- Categorized word packs
- Cross-platform Flutter architecture

> Note: The APK is intended for testing and demonstration purposes.

**Made with ❤️, Flutter, and a little bit of Guessing-Game-chaos!**

⭐ Star this repo if you found it useful!

</div>
