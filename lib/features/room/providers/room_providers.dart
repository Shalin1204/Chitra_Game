import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/enums/app_enums.dart';
import '../../realtime/socket/socket_service.dart';
import '../../realtime/providers/realtime_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// roomProvider — current room state, updated via socket events
// ─────────────────────────────────────────────────────────────────────────────
final roomProvider = StateNotifierProvider<RoomNotifier, Room?>((ref) {
  final socket = ref.watch(socketServiceProvider);
  return RoomNotifier(socket);
});

class RoomNotifier extends StateNotifier<Room?> {
  final SocketService _socket;
  final _uuid = const Uuid();

  RoomNotifier(this._socket) : super(null) {
    _socket.onRoomState = _handleRoomState;
    _socket.onRoundState = _handleRoundState;
    _socket.onTimerUpdate = _handleTimerUpdate;
    _socket.onWordChoices = _handleWordChoices;
  }

  void _handleRoomState(Map<String, dynamic> data) {
    final currentWordChoices = state?.wordChoices ?? const [];
    final currentWord = state?.currentWord;
    var newRoom = Room.fromJson(data);

    // Preserve secret word choices for drawer (not in public room_state)
    if (newRoom.status == 'wordSelection' && currentWordChoices.isNotEmpty) {
      newRoom = Room(
        id: newRoom.id,
        code: newRoom.code,
        players: newRoom.players,
        mode: newRoom.mode,
        status: newRoom.status,
        currentRound: newRoom.currentRound,
        maxRounds: newRoom.maxRounds,
        drawerId: newRoom.drawerId,
        wordLength: newRoom.wordLength,
        timeRemaining: newRoom.timeRemaining,
        guessedPlayers: newRoom.guessedPlayers,
        wordChoices: currentWordChoices,
        currentWord: newRoom.currentWord ?? currentWord,
        revealedLetters: newRoom.revealedLetters,
      );
    }
    state = newRoom;
  }

  void _handleRoundState(Map<String, dynamic> data) {
    if (state != null) {
      state = Room(
        id: state!.id,
        code: state!.code,
        players: state!.players,
        mode: state!.mode,
        status: data['status'] ?? state!.status,
        currentRound: data['round'] ?? state!.currentRound,
        maxRounds: data['maxRounds'] ?? state!.maxRounds,
        drawerId: data['drawerId'] ?? state!.drawerId,
        wordLength: state!.wordLength,
        timeRemaining: state!.timeRemaining,
        guessedPlayers: state!.guessedPlayers,
        wordChoices: state!.wordChoices,
        revealedLetters: state!.revealedLetters,
      );
    }
  }

  void _handleTimerUpdate(int timeRemaining) {
    if (state != null) {
      state = Room(
        id: state!.id,
        code: state!.code,
        players: state!.players,
        mode: state!.mode,
        status: state!.status,
        currentRound: state!.currentRound,
        maxRounds: state!.maxRounds,
        drawerId: state!.drawerId,
        wordLength: state!.wordLength,
        timeRemaining: timeRemaining,
        guessedPlayers: state!.guessedPlayers,
        wordChoices: state!.wordChoices,
        revealedLetters: state!.revealedLetters,
      );
    }
  }

  void _handleWordChoices(List<WordChoice> words) {
    if (state != null) {
      state = Room(
        id: state!.id,
        code: state!.code,
        players: state!.players,
        mode: state!.mode,
        status: state!.status,
        currentRound: state!.currentRound,
        maxRounds: state!.maxRounds,
        drawerId: state!.drawerId,
        wordLength: state!.wordLength,
        timeRemaining: state!.timeRemaining,
        guessedPlayers: state!.guessedPlayers,
        wordChoices: words,
        revealedLetters: state!.revealedLetters,
      );
    }
  }

  void createRoom({required String displayName, required String avatar, required GameMode mode}) {
    final roomCode = _uuid.v4().replaceAll('-', '').substring(0, 6).toUpperCase();
    final playerId = _uuid.v4();
    state = Room(
      id: roomCode,
      code: roomCode,
      players: [Player(id: playerId, name: displayName, avatar: avatar, isHost: true)],
      mode: mode,
    );
    _socket.joinRoom('NEW', displayName, avatar);
  }

  void joinRoom(String code, String displayName, String avatar) {
    final playerId = _uuid.v4();
    state = Room(
      id: code,
      code: code,
      players: [Player(id: playerId, name: displayName, avatar: avatar)],
      mode: GameMode.normal,
    );
    _socket.joinRoom(code, displayName, avatar);
  }

  void leaveRoom() {
    _socket.leaveRoom();
    state = null;
  }

  void startGame() => _socket.emitStartGame();

  void readyUp() => _socket.emitReadyUp();
}