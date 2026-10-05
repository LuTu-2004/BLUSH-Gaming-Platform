// Khớp backend/Dtos/MatchDtos.cs

/// 1 người được gợi ý ghép đội (GET api/match/suggestions)
class MatchSuggestion {
  final String userId;
  final String displayName;
  final String avatarEmoji;
  final String? avatarUrl;
  final int? age;
  final String mbti;
  final String bio;
  final String? region;
  final bool? usesMic;
  final bool isVip;
  final int gameId;
  final String gameName;
  final String? position;
  final String? purpose;
  final List<String> hobbies;

  /// Độ hợp 0-100
  final int score;

  /// Vì sao hợp nhau (sau này do AI viết)
  final String reason;

  const MatchSuggestion({
    required this.userId,
    required this.displayName,
    this.avatarEmoji = '🎮',
    this.avatarUrl,
    this.age,
    this.mbti = '',
    this.bio = '',
    this.region,
    this.usesMic,
    this.isVip = false,
    required this.gameId,
    required this.gameName,
    this.position,
    this.purpose,
    this.hobbies = const [],
    required this.score,
    this.reason = '',
  });

  /// Dòng phụ: "Liên Quân Mobile · Đường giữa"
  String get gameLine => [gameName, if (position != null && position!.isNotEmpty) position!].join(' · ');

  factory MatchSuggestion.fromJson(Map<String, dynamic> json) => MatchSuggestion(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String? ?? '',
        avatarEmoji: json['avatarEmoji'] as String? ?? '🎮',
        avatarUrl: json['avatarUrl'] as String?,
        age: json['age'] as int?,
        mbti: json['mbti'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        region: json['region'] as String?,
        usesMic: json['usesMic'] as bool?,
        isVip: json['isVip'] as bool? ?? false,
        gameId: json['gameId'] as int,
        gameName: json['gameName'] as String? ?? '',
        position: json['position'] as String?,
        purpose: json['purpose'] as String?,
        hobbies: (json['hobbies'] as List? ?? const []).cast<String>(),
        score: json['score'] as int? ?? 0,
        reason: json['reason'] as String? ?? '',
      );
}
