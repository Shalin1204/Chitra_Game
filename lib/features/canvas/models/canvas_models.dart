import 'package:flutter/material.dart';
import '../../../shared/enums/app_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DrawPoint — single point on a stroke path (includes pressure for freehand)
// ─────────────────────────────────────────────────────────────────────────────
class DrawPoint {
  final double x;
  final double y;
  final double pressure; // 0.0 – 1.0, used by perfect_freehand

  const DrawPoint({required this.x, required this.y, this.pressure = 0.5});

  Offset get offset => Offset(x, y);

  factory DrawPoint.fromJson(Map<String, dynamic> json) {
    return DrawPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: (json['p'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'p': pressure};
}

// ─────────────────────────────────────────────────────────────────────────────
// Stroke — one continuous brush stroke (delta-synced over socket)
// ─────────────────────────────────────────────────────────────────────────────
class Stroke {
  final String id;
  final List<DrawPoint> points;
  final Color color;
  final double size;
  final BrushType brushType;
  final String userId;
  final int timestamp;

  const Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.size,
    required this.brushType,
    required this.userId,
    required this.timestamp,
  });

  Stroke copyWith({List<DrawPoint>? points}) {
    return Stroke(
      id: id,
      points: points ?? this.points,
      color: color,
      size: size,
      brushType: brushType,
      userId: userId,
      timestamp: timestamp,
    );
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id'] as String,
      points: (json['pts'] as List<dynamic>)
          .map((p) => DrawPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      color: Color(json['color'] as int),
      size: (json['size'] as num).toDouble(),
      brushType: BrushType.values.firstWhere(
        (e) => e.name == json['brush'],
        orElse: () => BrushType.normal,
      ),
      userId: json['uid'] as String,
      timestamp: json['ts'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pts': points.map((p) => p.toJson()).toList(),
        'color': color.toARGB32(),
        'size': size,
        'brush': brushType.name,
        'uid': userId,
        'ts': timestamp,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// ToolState — current brush configuration (driven by ToolBar)
// ─────────────────────────────────────────────────────────────────────────────
class ToolState {
  final BrushType brushType;
  final Color color;
  final double size;
  final bool isErasing;

  const ToolState({
    this.brushType = BrushType.normal,
    this.color = const Color(0xFFFFFFFF),
    this.size = 4.0,
    this.isErasing = false,
  });

  ToolState copyWith({
    BrushType? brushType,
    Color? color,
    double? size,
    bool? isErasing,
  }) {
    return ToolState(
      brushType: brushType ?? this.brushType,
      color: color ?? this.color,
      size: size ?? this.size,
      isErasing: isErasing ?? this.isErasing,
    );
  }
}