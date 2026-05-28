enum AvatarType {
  pixelPilot('pixel_pilot', 'assets/avatars/pixel_pilot.png'),
  neonNinja('neon_ninja', 'assets/avatars/neon_ninja.png'),
  glitchGhost('glitch_ghost', 'assets/avatars/glitch_ghost.png'),
  chaosBot('chaos_bot', 'assets/avatars/chaos_bot.png');

  final String id;
  final String assetPath;

  const AvatarType(this.id, this.assetPath);

  static AvatarType fromId(String id) {
    return AvatarType.values.firstWhere(
      (avatar) => avatar.id == id,
      orElse: () => AvatarType.pixelPilot,
    );
  }
}
