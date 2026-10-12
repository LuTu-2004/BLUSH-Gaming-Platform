import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/community_screen.dart';
import 'package:blush_mobile_app/screens/vip_screen.dart';
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
      child: MaterialApp(home: Scaffold(body: home)),
    );

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('Bảng tin: hiện bài từ các Zone, thả tim gọi API và cập nhật số tim', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), const CommunityScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Tối nay ai leo rank Liên Quân không? Thiếu 1 trợ thủ!'), findsOneWidget);
    expect(find.byTooltip('Thành viên BLUSH Pass'), findsWidgets); // tác giả VIP có 👑

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/api/posts/p1/like');
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Bảng tin: viết bài chọn Zone đã tham gia rồi hiện ngay trên đầu', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), const CommunityScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chia sẻ chiến tích, rủ đồng đội...'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  GG cả team!  ');
    await tester.tap(find.text('Đăng bài'));
    await tester.pumpAndSettle();

    final create = requests.lastWhere((r) => r.method == 'POST' && r.url.path.endsWith('/posts'));
    expect(create.url.path, '/api/zones/2/posts'); // Zone duy nhất đã tham gia + vào được
    expect(jsonDecode(create.body), {'content': 'GG cả team!'});
    expect(find.text('GG cả team!'), findsOneWidget);
  });

  testWidgets('Bình luận: xem và gửi bình luận, số bình luận trên bài tăng', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), const CommunityScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mode_comment_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('Mình đi rừng nha'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Viết bình luận...'), 'Cho mình theo với');
    await tester.tap(find.byTooltip('Gửi bình luận'));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/posts/p1/comments');
    expect(find.text('Cho mình theo với'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10)); // đóng bảng bình luận
    await tester.pumpAndSettle();
    expect(find.text('2'), findsWidgets); // 1 -> 2 bình luận
  });

  testWidgets('Gỡ bài của mình: chỉ bài của mình có "Gỡ bài viết"', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), const CommunityScreen()));
    await tester.pumpAndSettle();

    final menus = find.byTooltip('Tùy chọn bài viết', skipOffstage: false);
    await tester.ensureVisible(menus.last);
    await tester.pumpAndSettle();
    await tester.tap(menus.last);
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo vi phạm'), findsNothing); // bài của mình: không tự báo cáo
    await tester.tap(find.text('Gỡ bài viết'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Gỡ'));
    await tester.pumpAndSettle();

    expect(requests.last.method, 'DELETE');
    expect(requests.last.url.path, '/api/posts/p2');
    expect(find.text('Bài của mình nè'), findsNothing);
  });

  testWidgets('Zone: tham gia Zone, Zone kín mở trang BLUSH Pass', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), const CommunityScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zone'));
    await tester.pumpAndSettle();

    expect(find.text('Dành cho BLUSH Pass Pro'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tham gia'));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/zones/1/join');
    expect(find.widgetWithText(OutlinedButton, 'Đã tham gia'), findsNWidgets(2));

    await tester.tap(find.text('Sảnh kín BLUSH Pass Pro'));
    await tester.pumpAndSettle();
    expect(find.byType(VipScreen), findsOneWidget);
  });
}
