import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';
import '../api/api_client.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

/// Gọi API chat (backend/Controllers/ChatController.cs).
/// Dùng: `ChatService(context.read<AuthService>())`
class ChatService {
  static const pageSize = 50;

  final AuthService auth;

  ChatService(this.auth);

  ApiClient get _api => auth.api;

  Future<List<ChatRoom>> getRooms() async =>
      (await _api.get('chat/rooms') as List).map((e) => ChatRoom.fromJson(e as Map<String, dynamic>)).toList();

  /// Mở phòng với 1 người (có rồi thì backend trả phòng cũ)
  Future<ChatRoom> openRoom(String userId) async =>
      ChatRoom.fromJson(await _api.post('chat/rooms', {'userId': userId}) as Map<String, dynamic>);

  Future<ChatRoom> getRoom(String roomId) async => ChatRoom.fromJson(await _api.get('chat/rooms/$roomId') as Map<String, dynamic>);

  /// [before] = tải tin cũ hơn mốc này. Trả về theo thứ tự cũ -> mới.
  Future<List<ChatMessage>> getMessages(String roomId, {DateTime? before}) async {
    final query = ['limit=$pageSize', if (before != null) 'before=${Uri.encodeQueryComponent(before.toUtc().toIso8601String())}'].join('&');
    final data = await _api.get('chat/rooms/$roomId/messages?$query') as List;
    return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> send(String roomId, String content) async =>
      ChatMessage.fromJson(await _api.post('chat/rooms/$roomId/messages', {'content': content.trim()}) as Map<String, dynamic>);

  /// Đánh dấu đã đọc hết tin trong phòng (để đếm tin chưa đọc)
  Future<void> markRead(String roomId) => _api.post('chat/rooms/$roomId/read');

  Future<ChatRoom> answerIceBreaker(String roomId, String choice) async =>
      ChatRoom.fromJson(await _api.post('chat/rooms/$roomId/icebreaker', {'choice': choice}) as Map<String, dynamic>);
}

/// Nhận tin thời gian thực qua SignalR (/hubs/chat). Mỗi màn chat tự mở khi hiện và đóng khi thoát.
/// Kết nối không được (mạng chặn WebSocket...) thì [connected] = false, màn chat tự hỏi lại server định kỳ.
abstract class ChatRealtime {
  /// Test thay bằng bản giả để không mở kết nối mạng thật
  static ChatRealtime Function(AuthService auth) factory = SignalRChatRealtime.new;

  Stream<ChatMessage> get messages;
  Stream<ChatRoom> get rooms;
  Stream<AppNotification> get notifications;
  bool get connected;

  Future<void> start();
  Future<void> stop();
}

class SignalRChatRealtime implements ChatRealtime {
  final AuthService auth;
  final _messages = StreamController<ChatMessage>.broadcast();
  final _rooms = StreamController<ChatRoom>.broadcast();
  final _notifications = StreamController<AppNotification>.broadcast();
  HubConnection? _hub;

  SignalRChatRealtime(this.auth);

  @override
  Stream<ChatMessage> get messages => _messages.stream;
  @override
  Stream<ChatRoom> get rooms => _rooms.stream;
  @override
  Stream<AppNotification> get notifications => _notifications.stream;
  @override
  bool get connected => _hub?.state == HubConnectionState.Connected;

  @override
  Future<void> start() async {
    // baseUrl dạng http://host:5000/api -> hub ở http://host:5000/hubs/chat
    final hubUrl = auth.api.baseUrl.replaceFirst(RegExp(r'/api/?$'), '/hubs/chat');
    final hub = HubConnectionBuilder()
        .withUrl(hubUrl, options: HttpConnectionOptions(accessTokenFactory: () async => auth.api.accessToken ?? ''))
        .withAutomaticReconnect()
        .build();
    hub.on('message', (args) {
      final data = args?.firstOrNull;
      if (data is Map) _messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(data)));
    });
    hub.on('room', (args) {
      final data = args?.firstOrNull;
      if (data is Map) _rooms.add(ChatRoom.fromJson(_deepCast(data)));
    });
    hub.on('notification', (args) {
      final data = args?.firstOrNull;
      if (data is Map) _notifications.add(AppNotification.fromJson(_deepCast(data)));
    });
    _hub = hub;
    try {
      await hub.start();
    } catch (_) {
      // Không kết nối được: để connected = false, màn chat dùng cách hỏi lại định kỳ
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _hub?.stop();
    } catch (_) {}
    await _messages.close();
    await _rooms.close();
    await _notifications.close();
  }

  // JSON lồng nhau từ SignalR là Map<dynamic, dynamic> -> đổi sang Map<String, dynamic> cho fromJson
  static Map<String, dynamic> _deepCast(Map data) =>
      data.map((k, v) => MapEntry(k.toString(), v is Map ? _deepCast(v) : v));
}
