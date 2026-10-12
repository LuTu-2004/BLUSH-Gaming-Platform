import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'chat_room_screen.dart';

/// Danh sách cuộc trò chuyện (GET api/chat/rooms), người mới nhắn lên đầu.
/// Có tin mới qua SignalR thì tự tải lại; quay về từ phòng chat cũng tải lại.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final AuthService _auth = context.read<AuthService>();
  late final ChatService _service = ChatService(_auth);
  late final ChatRealtime _realtime = ChatRealtime.factory(_auth);
  StreamSubscription<ChatMessage>? _sub;

  List<ChatRoom>? _rooms;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = _realtime.messages.listen((_) => _load());
    _realtime.start();
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _realtime.stop();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rooms = await _service.getRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _openRoom(ChatRoom room) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(userId: room.other.id, displayName: room.other.displayName, avatarEmoji: room.other.avatarEmoji, avatarUrl: room.other.avatarUrl),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final rooms = _rooms;
    final myId = _auth.currentUser?.id;

    Widget body;
    if (rooms == null && _error != null) {
      body = Center(
        child: Padding(
          padding: AppSpace.page,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.lg),
              ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    } else if (rooms == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (rooms.isEmpty) {
      body = Center(
        child: Padding(
          padding: AppSpace.page,
          child: Text('Chưa có cuộc trò chuyện nào.\nVào tab Đồng đội và bấm "Bắt chuyện" để làm quen nhé!', textAlign: TextAlign.center, style: text.bodyMedium),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          itemCount: rooms.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
          itemBuilder: (_, i) {
            final room = rooms[i];
            final last = room.lastMessage;
            final preview = last == null
                ? 'Chưa có tin nhắn'
                : last.isSystem
                    ? last.content
                    : last.senderId == myId
                        ? 'Bạn: ${last.content}'
                        : last.content;
            return ListTile(
              onTap: () => _openRoom(room),
              leading: AppAvatar(imageUrl: room.other.avatarUrl, fallback: room.other.avatarEmoji, size: 44),
              title: Text(room.other.displayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                preview,
                style: room.unreadCount > 0 ? text.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: t.textPrimary) : text.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (last != null) Text(formatChatTime(last.createdAt), style: text.labelSmall),
                  if (room.unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Badge(label: Text('${room.unreadCount}'), backgroundColor: ThemeService.accent),
                  ],
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Tin nhắn')), body: body);
  }
}
