// Khớp backend/Dtos/LeaderboardDtos.cs (GET api/leaderboard)

class LeaderboardEntry {
  final int rank; // bằng EXP thì cùng hạng
  final String userId;
  final String displayName;
  final String avatarEmoji;
  final String? avatarUrl;
  final String? mbti;
  final String? region;
  final int level;
  final int exp;
  final String? gameName;
  final bool isMe;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarEmoji = '🎮',
    this.avatarUrl,
    this.mbti,
    this.region,
    required this.level,
    required this.exp,
    this.gameName,
    this.isMe = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: json['rank'] as int,
        userId: json['userId'] as String,
        displayName: json['displayName'] as String? ?? '',
        avatarEmoji: json['avatarEmoji'] as String? ?? '🎮',
        avatarUrl: json['avatarUrl'] as String?,
        mbti: json['mbti'] as String?,
        region: json['region'] as String?,
        level: json['level'] as int? ?? 1,
        exp: json['exp'] as int? ?? 0,
        gameName: json['gameName'] as String?,
        isMe: json['isMe'] as bool? ?? false,
      );
}

class Leaderboard {
  final List<LeaderboardEntry> items;
  final LeaderboardEntry? me; // null = mình không có trong bảng đang lọc

  const Leaderboard({required this.items, this.me});

  factory Leaderboard.fromJson(Map<String, dynamic> json) => Leaderboard(
        items: (json['items'] as List? ?? const []).map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList(),
        me: json['me'] == null ? null : LeaderboardEntry.fromJson(json['me'] as Map<String, dynamic>),
      );
}
