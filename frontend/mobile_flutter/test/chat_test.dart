import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/chat_list_screen.dart';
import 'package:blush_mobile_app/screens/chat_room_screen.dart';
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

Widget _wrap(AuthService auth, Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: MaterialApp(home: home),
    );

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

const _room = ChatRoomScreen(userId: 'u-toxic', displayName: 'ToxicGamer99');

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('mở phòng: gọi API mở phòng theo userId, hiện lịch sử + câu phá băng', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), _room));
    await tester.pumpAndSettle();

    final open = requests.firstWhere((r) => r.method == 'POST' && r.url.path == '/api/chat/rooms');
    expect(jsonDecode(open.body), {'userId': 'u-toxic'});
    expect(find.text('Chào bạn, leo rank không?'), findsOneWidget);
    expect(find.text('Hai bạn chọn khác nhau. Thử thuyết phục đối phương xem!'), findsOneWidget); // tin hệ thống
    expect(find.text('Team thua 10 mạng đầu game, bạn sẽ?'), findsOneWidget);
    expect(find.textContaining('đã trả lời. Chọn đi'), findsOneWidget); // người kia đã chọn, chưa lộ đáp án
  });

  testWidgets('gửi tin: gọi API, hiện tin; tin đó về lại qua SignalR không bị nhân đôi', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), _room));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Leo chứ!  ');
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pumpAndSettle();

    final send = requests.lastWhere((r) => r.method == 'POST' && r.url.path == '/api/chat/rooms/room-1/messages');
    expect(jsonDecode(send.body), {'content': 'Leo chứ!'});
    expect(find.text('Leo chứ!'), findsOneWidget);

    FakeChatRealtime.last!.push(chatMessageJson('m3', 'Leo chứ!', senderId: gamerId, createdAt: '2026-10-12T03:01:00'));
    await tester.pumpAndSettle();
    expect(find.text('Leo chứ!'), findsOneWidget);
  });

  testWidgets('tin của người kia đến qua SignalR thì hiện ngay; tin phòng khác bị bỏ qua', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(_wrap(await _gamer([]), _room));
    await tester.pumpAndSettle();

    FakeChatRealtime.last!.push(chatMessageJson('m9', 'Vào trận thôi!', createdAt: '2026-10-12T03:05:00'));
    FakeChatRealtime.last!.push({...chatMessageJson('x1', 'Tin phòng khác'), 'roomId': 'room-khac'});
    await tester.pumpAndSettle();

    expect(find.text('Vào trận thôi!'), findsOneWidget);
    expect(find.text('Tin phòng khác'), findsNothing);
  });

  testWidgets('trả lời câu phá băng thì thấy lựa chọn của người kia', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), _room));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🛡️ Thủ trụ chờ late game'));
    await tester.pumpAndSettle();

    expect(requests.last.url.path, '/api/chat/rooms/room-1/icebreaker');
    expect(jsonDecode(requests.last.body), {'choice': 'A'});
    expect(find.text('Bạn chọn: 🛡️ Thủ trụ chờ late game'), findsOneWidget);
    expect(find.textContaining('chọn: ⚔️ All-in lật kèo'), findsOneWidget);
  });

  testWidgets('danh sách tin nhắn: hiện phòng + tin cuối, có tin mới thì tải lại', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), const ChatListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Hoàng Minh Thùy Trang Rất Dài'), findsOneWidget);
    expect(find.text('Chào bạn, leo rank không?'), findsOneWidget);

    final before = requests.where((r) => r.url.path == '/api/chat/rooms').length;
    FakeChatRealtime.last!.push(chatMessageJson('m9', 'Tin mới'));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.url.path == '/api/chat/rooms').length, before + 1);
  });
}
