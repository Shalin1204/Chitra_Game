import '../models/replay_models.dart';
import '../../../shared/enums/app_enums.dart';
import '../../canvas/models/canvas_models.dart';

/// ReplayRecorder — records all session events for later playback.
///
/// Usage:
///   recorder.start()          — begin recording (saves session start time)
///   recorder.recordStroke()   — call on each stroke event
///   recorder.stop()           — finalize and return ReplaySession
class ReplayRecorder {
  final List<ReplayEvent> _events = [];
  int? _startMs;
  bool _recording = false;

  void start() {
    _startMs = DateTime.now().millisecondsSinceEpoch;
    _recording = true;
    _events.clear();
  }

  void recordStrokeStart(Stroke stroke) {
    if (!_recording) return;
    _record(ReplayEventType.strokeStart, stroke.toJson());
  }

  void recordStrokeEnd(String strokeId) {
    if (!_recording) return;
    _record(ReplayEventType.strokeEnd, {'id': strokeId});
  }

  void recordChaosEvent(String eventType) {
    if (!_recording) return;
    _record(ReplayEventType.chaosEvent, {'eventType': eventType});
  }

  void recordReaction(String userId, String emoji) {
    if (!_recording) return;
    _record(ReplayEventType.reaction, {'uid': userId, 'emoji': emoji});
  }

  void _record(ReplayEventType type, Map<String, dynamic> data) {
    final ts = DateTime.now().millisecondsSinceEpoch - (_startMs ?? 0);
    _events.add(ReplayEvent(type: type, timestamp: ts, data: data));
  }

  ReplaySession stop({required String sessionId, required String roomId}) {
    _recording = false;
    final durationMs = DateTime.now().millisecondsSinceEpoch - (_startMs ?? 0);
    return ReplaySession(
      id: sessionId,
      roomId: roomId,
      events: List.from(_events),
      durationMs: durationMs,
      recordedAt: DateTime.now(),
    );
  }
}