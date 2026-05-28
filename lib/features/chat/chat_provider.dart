import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../realtime/socket/socket_service.dart';
import '../realtime/providers/realtime_providers.dart';

class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final bool isSystem;
  final String colorHex;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.isSystem = false,
    this.colorHex = '#FFFFFF',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      text: json['text'] as String,
      isSystem: json['isSystem'] as bool? ?? false,
      colorHex: json['color'] as String? ?? '#FFFFFF',
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final socket = ref.watch(socketServiceProvider);
  return ChatNotifier(socket);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final SocketService _socket;

  ChatNotifier(this._socket) : super([]) {
    _socket.onChatMessage = (data) {
      state = [...state, ChatMessage.fromJson(data)];
    };
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _socket.emitChatMessage(text.trim());
  }

  void clearChat() {
    state = [];
  }
}
