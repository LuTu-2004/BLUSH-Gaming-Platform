import 'payment_model.dart';

// Khớp backend/Dtos/NotificationDtos.cs

class AppNotification {
  final String id;
  final String type; // PostLiked | PostCommented | ReportResolved | Warning | QuestCompleted | VipActivated | VipExpiring
  final String title;
  final String? body;
  final String? link; // 'zone:2' | 'vip' | 'quests'
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({required this.id, required this.type, required this.title, this.body, this.link, required this.createdAt, this.isRead = false});

  AppNotification markRead() => AppNotification(id: id, type: type, title: title, body: body, link: link, createdAt: createdAt, isRead: true);

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String?,
        link: json['link'] as String?,
        createdAt: parseServerDate(json['createdAt']) ?? DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
      );
}
