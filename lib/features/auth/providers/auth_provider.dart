import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserIdProvider = StateProvider<String>((ref) {
  return '';
});

final currentUserAvatarProvider = StateProvider<String>((ref) {
  return '👽';
});