// Khớp backend/Dtos/FeedDtos.cs (Zone + Feed)
import 'payment_model.dart';

class Zone {
  final int id;
  final String name;
  final int gameId;
  final String gameName;
  final String purpose;
  final String purposeLabel;
  final String? description;
  final bool isVipOnly; // Zone kín: BLUSH Pass Pro
  final int memberCount;
  final bool isMember;
  final bool canAccess;

  const Zone({
    required this.id,
    required this.name,
    required this.gameId,
    required this.gameName,
    required this.purpose,
    required this.purposeLabel,
    this.description,
    this.isVipOnly = false,
    this.memberCount = 0,
    this.isMember = false,
    this.canAccess = true,
  });

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        gameId: json['gameId'] as int? ?? 0,
        gameName: json['gameName'] as String? ?? '',
        purpose: json['purpose'] as String? ?? '',
        purposeLabel: json['purposeLabel'] as String? ?? '',
        description: json['description'] as String?,
        isVipOnly: json['isVipOnly'] as bool? ?? false,
        memberCount: json['memberCount'] as int? ?? 0,
        isMember: json['isMember'] as bool? ?? false,
        canAccess: json['canAccess'] as bool? ?? true,
      );
}

class FeedAuthor {
  final String id;
  final String displayName;
  final String avatarEmoji;
  final String? avatarUrl;
  final bool isVip;

  const FeedAuthor({required this.id, required this.displayName, this.avatarEmoji = '🎮', this.avatarUrl, this.isVip = false});

  factory FeedAuthor.fromJson(Map<String, dynamic> json) => FeedAuthor(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? '',
        avatarEmoji: json['avatarEmoji'] as String? ?? '🎮',
        avatarUrl: json['avatarUrl'] as String?,
        isVip: json['isVip'] as bool? ?? false,
      );
}

class Post {
  final String id;
  final int zoneId;
  final String zoneName;
  final FeedAuthor author;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final bool canDelete;

  const Post({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.author,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.canDelete = false,
  });

  Post copyWith({int? likeCount, int? commentCount, bool? likedByMe}) => Post(
        id: id,
        zoneId: zoneId,
        zoneName: zoneName,
        author: author,
        content: content,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        likedByMe: likedByMe ?? this.likedByMe,
        canDelete: canDelete,
      );

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        zoneId: json['zoneId'] as int? ?? 0,
        zoneName: json['zoneName'] as String? ?? '',
        author: FeedAuthor.fromJson(json['author'] as Map<String, dynamic>),
        content: json['content'] as String? ?? '',
        createdAt: parseServerDate(json['createdAt']) ?? DateTime.now(),
        likeCount: json['likeCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        likedByMe: json['likedByMe'] as bool? ?? false,
        canDelete: json['canDelete'] as bool? ?? false,
      );
}

class Comment {
  final String id;
  final FeedAuthor author;
  final String content;
  final DateTime createdAt;
  final bool canDelete;

  const Comment({required this.id, required this.author, required this.content, required this.createdAt, this.canDelete = false});

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        author: FeedAuthor.fromJson(json['author'] as Map<String, dynamic>),
        content: json['content'] as String? ?? '',
        createdAt: parseServerDate(json['createdAt']) ?? DateTime.now(),
        canDelete: json['canDelete'] as bool? ?? false,
      );
}
