import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/blocked_users_screen.dart';
import 'package:blush_mobile_app/screens/chat_room_screen.dart';
import 'package:blush_mobile_app/screens/match_feed_screen.dart';
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

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('phòng chat: menu ⋮ → Chặn → xác nhận → gọi API và rời phòng', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    final auth = await _gamer(requests);
    // Mở phòng chat từ 1 màn khác để kiểm tra chặn xong thì quay lại
    await tester.pumpWidget(_wrap(
      auth,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatRoomScreen(userId: 'u-toxic', displayName: 'ToxicGamer99')),
            ),
            child: const Text('mo chat'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('mo chat'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Báo cáo hoặc chặn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chặn'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Người này không nhận được thông báo'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Chặn'));
    await tester.pumpAndSettle();

    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/api/blocks/u-toxic');
    expect(find.byType(ChatRoomScreen), findsNothing);
    expect(find.text('mo chat'), findsOneWidget);
  });

  testWidgets('tab Đồng đội: chặn 1 người thì thẻ của họ biến mất', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), const Scaffold(body: MatchFeedScreen()))); // trong app tab nằm trong Scaffold của MainNavigationScreen
    await tester.pumpAndSettle();

    expect(find.text('Đăng Khoa', skipOffstage: false), findsOneWidget);
    final menus = find.byTooltip('Báo cáo hoặc chặn', skipOffstage: false);
    await tester.ensureVisible(menus.last);
    await tester.pumpAndSettle();
    await tester.tap(menus.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chặn'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Chặn'));
    await tester.pumpAndSettle();

    expect(requests.last.url.path, '/api/blocks/a0000000-0000-0000-0000-000000000008');
    expect(find.text('Đăng Khoa', skipOffstage: false), findsNothing);
  });

  testWidgets('Người đã chặn: hiện danh sách, bỏ chặn gọi API rồi xóa khỏi danh sách', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), const BlockedUsersScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ToxicGamer99'), findsOneWidget);
    await tester.tap(find.text('Bỏ chặn'));
    await tester.pumpAndSettle();

    expect(requests.last.method, 'DELETE');
    expect(requests.last.url.path, '/api/blocks/u-toxic');
    expect(find.text('Bạn chưa chặn ai.'), findsOneWidget);
  });
}
