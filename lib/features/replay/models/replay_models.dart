import '../../../shared/enums/app_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReplayEvent — single timestamped event stored for session replay.
// Store EVENTS not bitmaps — efficient and replayable.
// ─────────────────────────────────────────────────────────────────────────────
class ReplayEvent {
  final ReplayEventType type;
  final int timestamp; // ms since session start
  final Map<String, dynamic> data;

  const ReplayEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'ts': timestamp,
        'data': data,
      };

  factory ReplayEvent.fromJson(Map<String, dynamic> json) {
    return ReplayEvent(
      type: ReplayEventType.values.firstWhere((e) => e.name == json['type']),
      timestamp: json['ts'] as int,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ReplaySession — container for a full recorded session
// ─────────────────────────────────────────────────────────────────────────────
class ReplaySession {
  final String id;
  final String roomId;
  final List<ReplayEvent> events;
  final int durationMs;
  final DateTime recordedAt;

  const ReplaySession({
    required this.id,
    required this.roomId,
    required this.events,
    required this.durationMs,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'events': events.map((e) => e.toJson()).toList(),
        'durationMs': durationMs,
        'recordedAt': recordedAt.toIso8601String(),
      };
}