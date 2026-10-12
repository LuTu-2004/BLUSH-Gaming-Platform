// Khớp backend/Dtos/ChatDtos.cs
import 'payment_model.dart';

class ChatUser {
  final String id;
  final String displayName;
  final String avatarEmoji;
  final String? avatarUrl;

  const ChatUser({required this.id, required this.displayName, this.avatarEmoji = '🎮', this.avatarUrl});

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? '',
        avatarEmoji: json['avatarEmoji'] as String? ?? '🎮',
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class ChatMessage {
  final String id;
  final String roomId;
  final String? senderId; // null = tin hệ thống
  final String content;
  final DateTime createdAt;

  const ChatMessage({required this.id, required this.roomId, this.senderId, required this.content, required this.createdAt});

  bool get isSystem => senderId == null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        senderId: json['senderId'] as String?,
        content: json['content'] as String? ?? '',
        createdAt: parseServerDate(json['createdAt']) ?? DateTime.now(),
      );
}

/// Câu hỏi phá băng nhìn từ phía mình: lựa chọn của người kia chỉ có khi mình đã chọn
class ChatIceBreaker {
  final String question;
  final String optionA;
  final String optionB;
  final String optionAIcon;
  final String optionBIcon;
  final String? myChoice; // 'A' | 'B'
  final bool theyAnswered;
  final String? theirChoice;

  const ChatIceBreaker({
    required this.question,
    required this.optionA,
    required this.optionB,
    this.optionAIcon = '🛡️',
    this.optionBIcon = '👑',
    this.myChoice,
    this.theyAnswered = false,
    this.theirChoice,
  });

  String labelOf(String choice) => choice == 'A' ? '$optionAIcon $optionA' : '$optionBIcon $optionB';

  factory ChatIceBreaker.fromJson(Map<String, dynamic> json) => ChatIceBreaker(
        question: json['question'] as String? ?? '',
        optionA: json['optionA'] as String? ?? '',
        optionB: json['optionB'] as String? ?? '',
        optionAIcon: json['optionAIcon'] as String? ?? '🛡️',
        optionBIcon: json['optionBIcon'] as String? ?? '👑',
        myChoice: json['myChoice'] as String?,
        theyAnswered: json['theyAnswered'] as bool? ?? false,
        theirChoice: json['theirChoice'] as String?,
      );
}

class ChatRoom {
  final String id;
  final ChatUser other;
  final ChatIceBreaker? iceBreaker;
  final ChatMessage? lastMessage;
  final int unreadCount; // tin người kia gửi mà mình chưa đọc
  final DateTime? createdAt;

  const ChatRoom({required this.id, required this.other, this.iceBreaker, this.lastMessage, this.unreadCount = 0, this.createdAt});

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
        id: json['id'] as String,
        other: ChatUser.fromJson(json['other'] as Map<String, dynamic>),
        iceBreaker: json['iceBreaker'] == null ? null : ChatIceBreaker.fromJson(json['iceBreaker'] as Map<String, dynamic>),
        lastMessage: json['lastMessage'] == null ? null : ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>),
        unreadCount: json['unreadCount'] as int? ?? 0,
        createdAt: parseServerDate(json['createdAt']),
      );
}

/// "14:05" nếu là hôm nay, "12/10 14:05" nếu ngày khác
String formatChatTime(DateTime t) {
  final now = DateTime.now();
  final hm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
  return sameDay ? hm : '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} $hm';
}
