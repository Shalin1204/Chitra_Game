import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/app_constants.dart';
import '../../canvas/models/canvas_models.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/enums/app_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SocketService — singleton wrapper around socket_io_client
//
// Responsibilities:
//  • Connect / disconnect lifecycle
//  • Emit stroke deltas (NOT full bitmaps)
//  • Emit cursor positions (throttled externally)
//  • Expose stream-like callback registration for incoming events
// ─────────────────────────────────────────────────────────────────────────────
class SocketService {
  late final io.Socket _socket;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  String? get socketId => _status == ConnectionStatus.connected ? _socket.id : null;

  // Callbacks registered by feature providers
  void Function(Map<String, dynamic>)? onStrokeStart;
  void Function(String strokeId, Map<String, dynamic> point)? onStrokeDelta;
  void Function(String strokeId)? onStrokeEnd;
  void Function(String userId, double x, double y)? onCursorMove;
  void Function(Map<String, dynamic>)? onRoomState;
  void Function(Map<String, dynamic>)? onChaosEvent;
  void Function(Map<String, dynamic>)? onRoundState;
  void Function(String userId, String emoji)? onReaction;
  void Function(Map<String, dynamic>)? onVoiceSignal;

  // Skribbl
  void Function(Map<String, dynamic>)? onChatMessage;
  void Function(List<WordChoice>)? onWordChoices;
  void Function(int)? onTimerUpdate;

  void connect(String token) {
    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket
      ..onConnect((_) => _status = ConnectionStatus.connected)
      ..onDisconnect((_) => _status = ConnectionStatus.disconnected)
      ..onReconnect((_) => _status = ConnectionStatus.connected)
      ..onConnectError((_) => _status = ConnectionStatus.error)

      // Strokes
      ..on('stroke_start', (data) => onStrokeStart?.call(data as Map<String, dynamic>))
      ..on('stroke_update', (data) {
        final d = data as Map<String, dynamic>;
        onStrokeDelta?.call(d['id'] as String, d['pt'] as Map<String, dynamic>);
      })
      ..on('stroke_end', (data) => onStrokeEnd?.call((data as Map)['id'] as String))

      // Cursor
      ..on('cursor_move', (data) {
        final d = data as Map<String, dynamic>;
        onCursorMove?.call(
          d['uid'] as String,
          (d['x'] as num).toDouble(),
          (d['y'] as num).toDouble(),
        );
      })

      // Room / game state
      ..on('room_state', (data) => onRoomState?.call(data as Map<String, dynamic>))
      ..on('chaos_event', (data) => onChaosEvent?.call(data as Map<String, dynamic>))
      ..on('round_state', (data) => onRoundState?.call(data as Map<String, dynamic>))

      // Social
      ..on('reaction', (data) {
        final d = data as Map<String, dynamic>;
        onReaction?.call(d['uid'] as String, d['emoji'] as String);
      })

      // Voice signaling
      ..on('voice_signal', (data) => onVoiceSignal?.call(data as Map<String, dynamic>))
      
      // Skribbl
      ..on('chat_message', (data) => onChatMessage?.call(data as Map<String, dynamic>))
      ..on('timer_update', (data) => onTimerUpdate?.call((data as Map<String, dynamic>)['timeRemaining'] as int))
      ..on('word_choices', (data) {
        final wordsList = (data as Map<String, dynamic>)['words'] as List<dynamic>;
        final choices = wordsList.map((w) => WordChoice.fromJson(w as Map<String, dynamic>)).toList();
        onWordChoices?.call(choices);
      });

    _socket.connect();
  }

  void disconnect() => _socket.disconnect();

  // ── Emit helpers ──────────────────────────────────────────────────────────

  void joinRoom(String roomCode, String displayName, String avatar) {
    _socket.emit('join_room', {'code': roomCode, 'name': displayName, 'avatar': avatar});
  }

  void leaveRoom() => _socket.emit('leave_room');

  void emitStrokeStart(Stroke stroke) {
    _socket.emit('stroke_start', stroke.toJson());
  }

  void emitStrokeDelta(String strokeId, DrawPoint point) {
    _socket.emit('stroke_update', {'id': strokeId, 'pt': point.toJson()});
  }

  void emitStrokeEnd(String strokeId) {
    _socket.emit('stroke_end', {'id': strokeId});
  }

  void emitCursorMove(double x, double y) {
    _socket.emit('cursor_move', {'x': x, 'y': y});
  }

  void emitReaction(String emoji) {
    _socket.emit('reaction', {'emoji': emoji});
  }

  void emitVoiceSignal(Map<String, dynamic> signal) {
    _socket.emit('voice_signal', signal);
  }

  void emitStartGame() => _socket.emit('start_game');

  void emitReadyUp() => _socket.emit('ready_up');

  void emitSelectWord(String word) => _socket.emit('select_word', {'word': word});

  void emitChatMessage(String text) => _socket.emit('chat_message', {'text': text});
}