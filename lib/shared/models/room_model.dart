import 'package:flutter/material.dart';

import '../enums/app_enums.dart';

const List<Color> _playerPalette = <Color>[
  Color(0xFF39FF14),
  Color(0xFF00D4FF),
  Color(0xFFFFE600),
  Color(0xFFFF2D55),
  Color(0xFFBF5FFF),
  Color(0xFFFF6B00),
];

class WordChoice {
  final String word;
  final String category;

  WordChoice({required this.word, required this.category});

  factory WordChoice.fromJson(Map<String, dynamic> json) {
    return WordChoice(
      word: json['word'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'category': category,
  };
}

class Player {
  final String id;
  final String name;
  final String avatar;
  final bool isHost;
  final int score;
  final bool isReady;

  Player({
    required this.id,
    required this.name,
    this.avatar = '👽',
    this.isHost = false,
    this.score = 0,
    this.isReady = false,
  });

  String get displayName => name;

  bool get isOnline => true;

  Color get cursorColor => _playerPalette[id.hashCode.abs() % _playerPalette.length];

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] ?? '',
      name: json['name'] ?? json['displayName'] ?? '',
      avatar: json['avatar'] ?? '👽',
      isHost: json['isHost'] ?? false,
      score: json['score'] ?? 0,
      isReady: json['isReady'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'isHost': isHost,
        'score': score,
        'isReady': isReady,
      };
}

class Room {
  final String id;
  final String code;
  final List<Player> players;
  final GameMode mode;
  final String status;
  final int currentRound;
  final int maxRounds;
  final String? drawerId;
  final int wordLength;
  final int timeRemaining;
  final List<String> guessedPlayers;
  final List<WordChoice> wordChoices;
  final String? currentWord;
  // Each element is null (hidden) or a revealed letter character
  final List<String?> revealedLetters;

  Room({
    required this.id,
    required this.players,
    required this.mode,
    this.status = 'waiting',
    this.currentRound = 0,
    this.maxRounds = 3,
    this.drawerId,
    this.wordLength = 0,
    this.timeRemaining = 0,
    this.guessedPlayers = const [],
    this.wordChoices = const [],
    this.currentWord,
    this.revealedLetters = const [],
    String? code,
  }) : code = code ?? id;

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? '',
      code: json['code'] ?? json['id'] ?? '',
      players: (json['players'] as List<dynamic>? ?? [])
          .map((player) => Player.fromJson(player as Map<String, dynamic>))
          .toList(),
      mode: GameMode.values.firstWhere(
        (value) => value.name == json['mode'] || value.name == json['gameMode'],
        orElse: () => GameMode.normal,
      ),
      status: json['status'] ?? 'waiting',
      currentRound: json['currentRound'] ?? 0,
      maxRounds: json['maxRounds'] ?? 3,
      drawerId: json['drawerId'],
      wordLength: json['wordLength'] ?? 0,
      timeRemaining: json['timeRemaining'] ?? 0,
      guessedPlayers: List<String>.from(json['guessedPlayers'] ?? []),
      wordChoices: (json['wordChoices'] as List<dynamic>? ?? [])
          .map((w) => WordChoice.fromJson(w as Map<String, dynamic>))
          .toList(),
      currentWord: json['currentWord'],
      revealedLetters: (json['revealedLetters'] as List<dynamic>? ?? [])
          .map((e) => e as String?)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'players': players.map((player) => player.toJson()).toList(),
        'mode': mode.name,
        'status': status,
        'currentRound': currentRound,
        'maxRounds': maxRounds,
      };
}