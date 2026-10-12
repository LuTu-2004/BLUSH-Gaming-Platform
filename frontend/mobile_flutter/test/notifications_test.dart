import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/main.dart';
import 'package:blush_mobile_app/screens/chat_list_screen.dart';
import 'package:blush_mobile_app/screens/chat_room_screen.dart';
import 'package:blush_mobile_app/screens/community_screen.dart';
import 'package:blush_mobile_app/screens/notifications_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

Future<AuthService> _gamer(List<http.Request> requests) async {
  final backend = fakeBackend();
  final auth = createAuth((req) async {
    requests.add(req);
    return backend(req);
  });
  await auth.login('gamer@blush.vn', '123456');
  return auth;
}

Widget _app(AuthService auth, {Widget? home}) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: home == null ? const BlushApp() : MaterialApp(home: home),
    );

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('khung chính: số chưa đọc trên 🔔 và 💬, thông báo mới qua SignalR tăng số', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(_app(await _gamer([])));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byTooltip('Thông báo'), matching: find.text('2')), findsOneWidget);
    expect(find.descendant(of: find.byTooltip('Tin nhắn'), matching: find.text('1')), findsOneWidget);

    FakeChatRealtime.last!.pushNotification(notificationJson('n9', 'QuestCompleted', 'Hoàn thành nhiệm vụ: Ghép đội 1 lần'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byTooltip('Thông báo'), matching: find.text('3')), findsOneWidget);
  });

  testWidgets('danh sách thông báo: bấm thông báo Zone thì mở Zone, "Đọc tất cả" gọi API', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _gamer(requests), home: const NotificationsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Cảnh báo từ đội kiểm duyệt BLUSH'), findsOneWidget);
    await tester.tap(find.text('Đọc tất cả'));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/notifications/read-all');
    expect(find.text('Đọc tất cả'), findsNothing);

    await tester.tap(find.text('Khánh Linh đã thả tim bài viết của bạn'));
    await tester.pumpAndSettle();
    expect(requests.any((r) => r.url.path == '/api/notifications/n1/read'), isFalse); // đã đọc tất cả ở trên
    expect(find.byType(ZoneScreen), findsOneWidget);
  });

  testWidgets('mở phòng chat thì đánh dấu đã đọc; tin mới của người kia khi đang mở cũng vậy', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _gamer(requests), home: const ChatRoomScreen(userId: 'u-toxic', displayName: 'ToxicGamer99')));
    await tester.pumpAndSettle();

    int reads() => requests.where((r) => r.method == 'POST' && r.url.path == '/api/chat/rooms/room-1/read').length;
    expect(reads(), 1);

    FakeChatRealtime.last!.push(chatMessageJson('m7', 'Online không?', createdAt: '2026-10-12T03:09:00'));
    await tester.pumpAndSettle();
    expect(reads(), 2);

    FakeChatRealtime.last!.push(chatMessageJson('m8', 'tin của mình', senderId: gamerId, createdAt: '2026-10-12T03:10:00'));
    await tester.pumpAndSettle();
    expect(reads(), 2); // tin của chính mình không cần đánh dấu
  });

  testWidgets('danh sách tin nhắn: hiện số tin chưa đọc của từng cuộc trò chuyện', (tester) async {
    _phoneSize(tester);
    final auth = createAuth((req) async {
      if (req.url.path == '/api/chat/rooms' && req.method == 'GET') {
        return jsonResponse([
          {...chatRoomJson(last: chatMessageJson('m2', 'Chào bạn')), 'unreadCount': 4},
        ]);
      }
      return fakeBackend()(req);
    });
    await auth.login('gamer@blush.vn', '123456');
    await tester.pumpWidget(_app(auth, home: const ChatListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
  });
}
