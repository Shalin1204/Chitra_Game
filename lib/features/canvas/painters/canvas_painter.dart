import 'package:flutter/material.dart';
import '../models/canvas_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/enums/app_enums.dart';

/// CanvasPainter — renders all completed strokes + the active in-flight stroke.
/// Uses perfect_freehand-style path building for smooth freehand curves.
class CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Stroke> remoteStrokes;
  final Stroke? activeStroke;

  const CanvasPainter({
    required this.strokes,
    required this.remoteStrokes,
    this.activeStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid removed
    // _drawGrid(canvas, size);

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    for (final stroke in remoteStrokes) {
      _drawStroke(canvas, stroke);
    }

    if (activeStroke != null) {
      _drawStroke(canvas, activeStroke!);
    }
  }



  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = _buildPaint(stroke);

    if (stroke.brushType == BrushType.pixel) {
      _drawPixelStroke(canvas, stroke, paint);
      return;
    }

    if (stroke.brushType == BrushType.spray) {
      _drawSprayStroke(canvas, stroke);
      return;
    }

    // Default smooth path
    final path = _buildSmoothPath(stroke.points);
    canvas.drawPath(path, paint);
  }

  // Canvas background color — must match the Container color in _DrawingBoard
  static const Color _canvasColor = Color(0xFFE8E0D0);

  Paint _buildPaint(Stroke stroke) {
    final isEraser = stroke.brushType == BrushType.eraser;
    final paint = Paint()
      ..color = isEraser ? _canvasColor : stroke.color
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.brushType == BrushType.neon) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.outer, stroke.size * 0.8);
    }

    return paint;
  }

  void _drawPixelStroke(Canvas canvas, Stroke stroke, Paint paint) {
    paint.style = PaintingStyle.fill;
    for (final pt in stroke.points) {
      canvas.drawRect(
        Rect.fromCenter(
          center: pt.offset,
          width: stroke.size,
          height: stroke.size,
        ),
        paint,
      );
    }
  }

  void _drawSprayStroke(Canvas canvas, Stroke stroke) {
    // Placeholder — replace with dart:math random spray pattern
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    for (final pt in stroke.points) {
      canvas.drawCircle(pt.offset, stroke.size * 0.4, paint);
    }
  }

  Path _buildSmoothPath(List<DrawPoint> points) {
    if (points.length == 1) {
      return Path()
        ..addOval(Rect.fromCenter(center: points[0].offset, width: 2, height: 2));
    }

    final path = Path()..moveTo(points[0].x, points[0].y);

    for (int i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].x + points[i + 1].x) / 2,
        (points[i].y + points[i + 1].y) / 2,
      );
      path.quadraticBezierTo(points[i].x, points[i].y, mid.dx, mid.dy);
    }

    path.lineTo(points.last.x, points.last.y);
    return path;
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      oldDelegate.strokes != strokes || 
      oldDelegate.remoteStrokes != remoteStrokes ||
      oldDelegate.activeStroke != activeStroke;
}

/// LiveCursorPainter — renders remote player cursors on a separate layer.
class LiveCursorPainter extends CustomPainter {
  final Map<String, Offset> cursors; // userId → position
  final Map<String, Color> cursorColors;

  const LiveCursorPainter({
    required this.cursors,
    required this.cursorColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in cursors.entries) {
      final color = cursorColors[entry.key] ?? RetroColors.neonGreen;
      _drawCursor(canvas, entry.value, color);
    }
  }

  void _drawCursor(Canvas canvas, Offset pos, Color color) {
    // Pixel-art cursor: simple square dot + glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(pos, 8, glowPaint);

    final dotPaint = Paint()..color = color;
    canvas.drawRect(
      Rect.fromCenter(center: pos, width: 6, height: 6),
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(LiveCursorPainter oldDelegate) =>
      oldDelegate.cursors != cursors;
}