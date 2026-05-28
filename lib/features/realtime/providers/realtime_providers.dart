import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../socket/socket_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/enums/app_enums.dart';

/// socketServiceProvider — single SocketService instance for the app lifetime.
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  service.connect(ref.read(currentUserIdProvider));
  ref.onDispose(() => service.disconnect());
  return service;
});

/// connectionStatusProvider — reactive connection status.
final connectionStatusProvider = StateProvider<ConnectionStatus>(
  (ref) => ConnectionStatus.disconnected,
);