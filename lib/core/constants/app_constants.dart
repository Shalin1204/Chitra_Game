/// AppConstants — single source of truth for magic numbers,
/// API endpoints, socket event names, and timing values.
abstract class AppConstants {
  // ── Server ──────────────────────────────────────────────────────────────
  static const String socketUrl = 'https://chitra-game.onrender.com';
  static const int socketReconnectDelay = 2000; // ms

  // ── Room ─────────────────────────────────────────────────────────────────
  static const int maxPlayersPerRoom = 8;
  static const int roomCodeLength = 6;

  // ── Canvas ───────────────────────────────────────────────────────────────
  static const double defaultBrushSize = 4.0;
  static const double minBrushSize = 1.0;
  static const double maxBrushSize = 64.0;
  static const int maxUndoHistory = 50;

  // ── Realtime ─────────────────────────────────────────────────────────────
  static const int strokeThrottleMs = 16; // ~60fps
  static const int cursorThrottleMs = 50; // 20fps for cursor

  // ── Chaos ────────────────────────────────────────────────────────────────
  static const int chaosEventIntervalSeconds = 45;
  static const int chaosEventDurationSeconds = 15;

  // ── Rounds ───────────────────────────────────────────────────────────────
  static const int defaultRoundDurationSeconds = 90;
  static const int lobbyCountdownSeconds = 5;
}