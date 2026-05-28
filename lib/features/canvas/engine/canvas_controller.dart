import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../realtime/socket/socket_service.dart';
import '../models/canvas_models.dart';
import '../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CanvasController — top-level notifier for the canvas state.
// Consumed by CanvasRoomScreen via Riverpod provider.
// ─────────────────────────────────────────────────────────────────────────────
class CanvasController extends ChangeNotifier {
  final StrokeManager _strokeManager = StrokeManager();
  final UndoRedoManager _undoRedo = UndoRedoManager();
  final SocketService _socket;
  final String _userId;

  ToolState toolState = const ToolState();
  Stroke? _activeStroke;

  CanvasController({required SocketService socket, required String userId})
      : _socket = socket,
        _userId = userId {
    _socket.onStrokeStart = (data) => applyRemoteStrokeStart(Stroke.fromJson(data));
    _socket.onStrokeDelta = (id, pt) => applyRemoteStrokeDelta(id, DrawPoint.fromJson(pt));
    _socket.onStrokeEnd = (id) => applyRemoteStrokeEnd(id);
  }

  List<Stroke> get strokes => _strokeManager.strokes;
  List<Stroke> get remoteStrokes => _strokeManager.remoteStrokes;

  // ── Drawing ───────────────────────────────────────────────────────────────

  void onPointerDown(DrawPoint point) {
    _activeStroke = Stroke(
      id: '${_userId}_${DateTime.now().millisecondsSinceEpoch}',
      points: [point],
      color: toolState.color,
      size: toolState.size,
      brushType: toolState.brushType,
      userId: _userId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _socket.emitStrokeStart(_activeStroke!);
    notifyListeners();
  }

  void onPointerMove(DrawPoint point) {
    if (_activeStroke == null) return;
    _activeStroke = _activeStroke!.copyWith(
      points: [..._activeStroke!.points, point],
    );
    _socket.emitStrokeDelta(_activeStroke!.id, point);
    notifyListeners();
  }

  void onPointerUp() {
    if (_activeStroke == null) return;
    _strokeManager.addStroke(_activeStroke!);
    _undoRedo.pushSnapshot(List.from(_strokeManager.strokes));
    _socket.emitStrokeEnd(_activeStroke!.id);
    _activeStroke = null;
    notifyListeners();
  }

  // ── Remote strokes ────────────────────────────────────────────────────────

  void applyRemoteStrokeStart(Stroke stroke) {
    _strokeManager.beginRemote(stroke);
    notifyListeners();
  }

  void applyRemoteStrokeDelta(String strokeId, DrawPoint point) {
    _strokeManager.appendRemote(strokeId, point);
    notifyListeners();
  }

  void applyRemoteStrokeEnd(String strokeId) {
    _strokeManager.finalizeRemote(strokeId);
    notifyListeners();
  }

  // ── Tool ──────────────────────────────────────────────────────────────────

  void updateTool(ToolState newTool) {
    toolState = newTool;
    notifyListeners();
  }

  // ── Undo / Redo ───────────────────────────────────────────────────────────

  void undo() {
    final snapshot = _undoRedo.undo();
    if (snapshot != null) {
      _strokeManager.loadSnapshot(snapshot);
      notifyListeners();
    }
  }

  void redo() {
    final snapshot = _undoRedo.redo();
    if (snapshot != null) {
      _strokeManager.loadSnapshot(snapshot);
      notifyListeners();
    }
  }

  void clearCanvas() {
    _undoRedo.pushSnapshot(List.from(_strokeManager.strokes));
    _strokeManager.clear();
    notifyListeners();
  }

  Stroke? get activeStroke => _activeStroke;
}

// ─────────────────────────────────────────────────────────────────────────────
// StrokeManager — manages completed and in-flight strokes
// ─────────────────────────────────────────────────────────────────────────────
class StrokeManager {
  final List<Stroke> _strokes = [];
  final Map<String, Stroke> _remoteInFlight = {};

  List<Stroke> get strokes => UnmodifiableListView(_strokes);
  List<Stroke> get remoteStrokes => _remoteInFlight.values.toList();

  void addStroke(Stroke stroke) => _strokes.add(stroke);

  void beginRemote(Stroke stroke) => _remoteInFlight[stroke.id] = stroke;

  void appendRemote(String strokeId, DrawPoint point) {
    final existing = _remoteInFlight[strokeId];
    if (existing == null) return;
    _remoteInFlight[strokeId] = existing.copyWith(
      points: [...existing.points, point],
    );
  }

  void finalizeRemote(String strokeId) {
    final stroke = _remoteInFlight.remove(strokeId);
    if (stroke != null) _strokes.add(stroke);
  }

  void loadSnapshot(List<Stroke> snapshot) {
    _strokes
      ..clear()
      ..addAll(snapshot);
  }

  void clear() => _strokes.clear();
}

// ─────────────────────────────────────────────────────────────────────────────
// UndoRedoManager — bounded history stack
// ─────────────────────────────────────────────────────────────────────────────
class UndoRedoManager {
  final List<List<Stroke>> _undoStack = [];
  final List<List<Stroke>> _redoStack = [];

  void pushSnapshot(List<Stroke> snapshot) {
    _undoStack.add(snapshot);
    if (_undoStack.length > AppConstants.maxUndoHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  List<Stroke>? undo() {
    if (_undoStack.isEmpty) return null;
    final snapshot = _undoStack.removeLast();
    _redoStack.add(snapshot);
    return snapshot;
  }

  List<Stroke>? redo() {
    if (_redoStack.isEmpty) return null;
    final snapshot = _redoStack.removeLast();
    _undoStack.add(snapshot);
    return snapshot;
  }
}