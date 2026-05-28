/// SocketEvents — all socket.io event name constants.
/// Use these rather than raw strings in emit/on calls.
abstract class SocketEvents {
  // Room
  static const joinRoom = 'join_room';
  static const leaveRoom = 'leave_room';
  static const roomState = 'room_state';

  // Canvas
  static const strokeStart = 'stroke_start';
  static const strokeUpdate = 'stroke_update';
  static const strokeEnd = 'stroke_end';
  static const cursorMove = 'cursor_move';

  // Game
  static const startGame = 'start_game';
  static const roundState = 'round_state';
  static const roundStart = 'round_start';
  static const roundEnd = 'round_end';
  static const chaosEvent = 'chaos_event';

  // Social
  static const reaction = 'reaction';

  // Voice
  static const voiceSignal = 'voice_signal';
}