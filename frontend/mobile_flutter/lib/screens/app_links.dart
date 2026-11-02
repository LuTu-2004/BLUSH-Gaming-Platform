import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/feed_service.dart';
import '../widgets/auth_widgets.dart';
import 'badges_screen.dart';
import 'chat_room_screen.dart';
import 'community_screen.dart';
import 'match_log_screen.dart';
import 'quests_screen.dart';
import 'vip_screen.dart';

/// Màn hình ứng với 1 link của thông báo (trong app hoặc thông báo đẩy), do backend đặt:
/// 'vip', 'quests', 'badges', 'matches', 'zone:<id>', 'chat:<userId>'.
/// Trả về null nếu không mở được (Zone không còn quyền vào, phòng chat đã bị chặn...).
Future<Widget?> screenForLink(BuildContext context, String link) async {
  switch (link) {
    case 'vip':
      return const VipScreen();
    case 'quests':
      return const QuestsScreen();
    case 'badges':
      return const BadgesScreen();
    case 'matches':
      return const MatchLogScreen();
  }
  final auth = context.read<AuthService>();
  try {
    if (link.startsWith('zone:')) {
      final zoneId = int.tryParse(link.substring(5));
      final zone = (await FeedService(auth).getZones()).where((z) => z.id == zoneId).firstOrNull;
      if (zone != null && zone.canAccess) return ZoneScreen(zone: zone);
    } else if (link.startsWith('chat:')) {
      final userId = link.substring(5);
      final room = (await ChatService(auth).getRooms()).where((r) => r.other.id == userId).firstOrNull;
      if (room != null) {
        return ChatRoomScreen(userId: userId, displayName: room.other.displayName, avatarEmoji: room.other.avatarEmoji, avatarUrl: room.other.avatarUrl);
      }
    }
  } on ApiException catch (e) {
    if (context.mounted) showErrorSnack(context, e.message);
  }
  return null;
}
