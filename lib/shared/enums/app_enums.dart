enum GameMode {
  normal,
  chaos,
  speedDraw,
  blindDraw,
  guessGame,
}

enum BrushType {
  normal,
  neon,
  spray,
  pixel,
  rainbow,
  eraser,
}

enum ConnectionStatus {
  connected,
  disconnected,
  connecting,
  error,
}

enum ChaosEventType {
  reverseControls,
  fogCanvas,
  rainbowMode,
  giantBrush,
  mirrorMode,
}

enum ReplayEventType {
  strokeStart,
  strokeEnd,
  chaosEvent,
  reaction,
}