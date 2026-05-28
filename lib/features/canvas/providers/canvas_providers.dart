import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/canvas_controller.dart';
import '../models/canvas_models.dart';
import '../../realtime/providers/realtime_providers.dart';
import '../../../shared/enums/app_enums.dart';
import '../../auth/providers/auth_providers.dart';

/// canvasControllerProvider — scoped per room via family.
/// Pass roomId to get (or create) the controller for that room.
final canvasControllerProvider =
    ChangeNotifierProvider.family<CanvasController, String>((ref, roomId) {
  final socket = ref.watch(socketServiceProvider);
  final userId = ref.watch(currentUserIdProvider);
  return CanvasController(socket: socket, userId: userId);
});

/// toolStateProvider — the current brush configuration.
final toolStateProvider = StateNotifierProvider<ToolStateNotifier, ToolState>(
  (ref) => ToolStateNotifier(),
);

class ToolStateNotifier extends StateNotifier<ToolState> {
  ToolStateNotifier() : super(const ToolState());

  void setColor(Color color) => state = state.copyWith(color: color);
  void setBrushType(BrushType type) => state = state.copyWith(brushType: type);
  void setSize(double size) => state = state.copyWith(size: size);
  void toggleEraser() =>
      state = state.copyWith(isErasing: !state.isErasing);
}

/// liveCursorsProvider — map of userId → cursor position.
final liveCursorsProvider =
    StateProvider<Map<String, Offset>>((ref) => {});