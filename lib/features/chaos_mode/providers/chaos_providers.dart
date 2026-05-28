import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../events/chaos_event.dart';
import '../../realtime/providers/realtime_providers.dart';

/// activeChaosEventProvider — the currently active chaos event (if any).
final activeChaosEventProvider = StateProvider<ChaosEvent?>((ref) => null);

/// chaosEventHistoryProvider — log of chaos events this session.
final chaosEventHistoryProvider =
    StateProvider<List<ChaosEvent>>((ref) => []);

/// chaosListenerProvider — hooks into socket events and updates chaos state.
final chaosListenerProvider = Provider<void>((ref) {
  final socket = ref.watch(socketServiceProvider);
  socket.onChaosEvent = (data) {
    final event = ChaosEvent.fromJson(data);
    event.apply();
    ref.read(activeChaosEventProvider.notifier).state = event;
    ref.read(chaosEventHistoryProvider.notifier).update((list) => [...list, event]);

    // Auto-remove after duration
    Future.delayed(event.duration, () {
      event.remove();
      if (ref.read(activeChaosEventProvider)?.id == event.id) {
        ref.read(activeChaosEventProvider.notifier).state = null;
      }
    });
  };
});