import '../enums/avatar_type.dart';

class UserProfile {
  final String uid;
  final String username;
  final String avatarId;
  final int matchesPlayed;
  final int wins;
  final int rank;
  final String favoriteBrush;

  const UserProfile({
    required this.uid,
    required this.username,
    required this.avatarId,
    required this.matchesPlayed,
    required this.wins,
    required this.rank,
    required this.favoriteBrush,
  });

  AvatarType get avatar => AvatarType.fromId(avatarId);

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'avatarId': avatarId,
        'matchesPlayed': matchesPlayed,
        'wins': wins,
        'rank': rank,
        'favoriteBrush': favoriteBrush,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      username: json['username'] as String,
      avatarId: json['avatarId'] as String,
      matchesPlayed: json['matchesPlayed'] as int,
      wins: json['wins'] as int,
      rank: json['rank'] as int,
      favoriteBrush: json['favoriteBrush'] as String,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? username,
    String? avatarId,
    int? matchesPlayed,
    int? wins,
    int? rank,
    String? favoriteBrush,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      rank: rank ?? this.rank,
      favoriteBrush: favoriteBrush ?? this.favoriteBrush,
    );
  }
}
