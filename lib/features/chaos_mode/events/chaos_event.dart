import '../../../shared/enums/app_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChaosEvent — abstract base for all chaos mode events
// ─────────────────────────────────────────────────────────────────────────────
abstract class ChaosEvent {
  final String id;
  final ChaosEventType type;
  final Duration duration;

  const ChaosEvent({
    required this.id,
    required this.type,
    required this.duration,
  });

  /// apply — activate the event effect
  void apply();

  /// remove — deactivate the event effect
  void remove();

  /// label — display name shown in UI banner
  String get label;

  /// emoji — icon for the event
  String get emoji;

  factory ChaosEvent.fromJson(Map<String, dynamic> json) {
    final type = ChaosEventType.values.firstWhere(
      (e) => e.name == json['type'],
    );
    switch (type) {
      case ChaosEventType.reverseControls:
        return ReverseControlsEvent(id: json['id'], duration: Duration(seconds: json['duration'] ?? 15));
      case ChaosEventType.fogCanvas:
        return FogCanvasEvent(id: json['id'], duration: Duration(seconds: json['duration'] ?? 15));
      case ChaosEventType.rainbowMode:
        return RainbowModeEvent(id: json['id'], duration: Duration(seconds: json['duration'] ?? 15));
      case ChaosEventType.giantBrush:
        return GiantBrushEvent(id: json['id'], duration: Duration(seconds: json['duration'] ?? 15));
      case ChaosEventType.mirrorMode:
        return MirrorModeEvent(id: json['id'], duration: Duration(seconds: json['duration'] ?? 15));
    }
  }
}

// ─── Concrete Events ──────────────────────────────────────────────────────────

class ReverseControlsEvent extends ChaosEvent {
  const ReverseControlsEvent({required super.id, super.duration = const Duration(seconds: 15)})
      : super(type: ChaosEventType.reverseControls);

  @override
  void apply() {/* flip x/y in CanvasController */}
  @override
  void remove() {/* restore */}
  @override
  String get label => 'REVERSED!';
  @override
  String get emoji => '🔄';
}

class FogCanvasEvent extends ChaosEvent {
  const FogCanvasEvent({required super.id, super.duration = const Duration(seconds: 15)})
      : super(type: ChaosEventType.fogCanvas);

  @override
  void apply() {/* show fog overlay */}
  @override
  void remove() {/* remove fog */}
  @override
  String get label => 'FOG OF WAR';
  @override
  String get emoji => '🌫️';
}

class RainbowModeEvent extends ChaosEvent {
  const RainbowModeEvent({required super.id, super.duration = const Duration(seconds: 15)})
      : super(type: ChaosEventType.rainbowMode);

  @override
  void apply() {/* cycle colours in CanvasController */}
  @override
  void remove() {/* restore user colour */}
  @override
  String get label => 'RAINBOW MODE';
  @override
  String get emoji => '🌈';
}

class GiantBrushEvent extends ChaosEvent {
  const GiantBrushEvent({required super.id, super.duration = const Duration(seconds: 15)})
      : super(type: ChaosEventType.giantBrush);

  @override
  void apply() {/* multiply brush size */}
  @override
  void remove() {/* restore size */}
  @override
  String get label => 'GIANT BRUSH!';
  @override
  String get emoji => '🖌️';
}

class MirrorModeEvent extends ChaosEvent {
  const MirrorModeEvent({required super.id, super.duration = const Duration(seconds: 15)})
      : super(type: ChaosEventType.mirrorMode);

  @override
  void apply() {/* mirror strokes horizontally */}
  @override
  void remove() {/* stop mirroring */}
  @override
  String get label => 'MIRROR MIRROR';
  @override
  String get emoji => '🪞';
}