import 'dart:async';

import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';
import 'chat_service.dart';

/// Gọi API thông báo (backend/Controllers/NotificationsController.cs)
class NotificationApi {
  final AuthService auth;

  NotificationApi(this.auth);

  ApiClient get _api => auth.api;

  Future<List<AppNotification>> getAll() async =>
      (await _api.get('notifications') as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();

  Future<(int notifications, int chats)> getSummary() async {
    final data = await _api.get('notifications/summary') as Map<String, dynamic>;
    return (data['unreadNotifications'] as int? ?? 0, data['unreadChats'] as int? ?? 0);
  }

  Future<void> markRead(String id) => _api.post('notifications/$id/read');

  Future<void> markAllRead() => _api.post('notifications/read-all');
}

/// Số trên nút 🔔 và 💬 của khung chính. Cập nhật ngay khi có thông báo / tin nhắn mới qua SignalR;
/// không kết nối được SignalR thì hỏi lại server mỗi [pollInterval].
class NotificationCenter extends ChangeNotifier {
  static const pollInterval = Duration(seconds: 30);

  final NotificationApi _api;
  final ChatRealtime _realtime;
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _pollTimer;

  int unreadNotifications = 0;
  int unreadChats = 0;

  NotificationCenter(AuthService auth)
      : _api = NotificationApi(auth),
        _realtime = ChatRealtime.factory(auth) {
    final myId = auth.currentUser?.id;
    _subs.add(_realtime.notifications.listen((_) {
      unreadNotifications++;
      notifyListeners();
    }));
    // Tin nhắn của người khác -> hỏi lại số cuộc trò chuyện chưa đọc (tin của mình không tính)
    _subs.add(_realtime.messages.where((m) => m.senderId != null && m.senderId != myId).listen((_) => refresh()));
    refresh();
    _realtime.start().then((_) {
      if (!_realtime.connected) _pollTimer = Timer.periodic(pollInterval, (_) => refresh());
    });
  }

  Future<void> refresh() async {
    try {
      final (notifications, chats) = await _api.getSummary();
      unreadNotifications = notifications;
      unreadChats = chats;
      notifyListeners();
    } on ApiException {
      // Mất mạng tạm thời: giữ số cũ
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _realtime.stop();
    super.dispose();
  }
}
