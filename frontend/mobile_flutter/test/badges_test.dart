import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/badges_screen.dart';
import 'package:blush_mobile_app/screens/notifications_screen.dart';
import 'package:blush_mobile_app/screens/profile_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

Widget _wrap(AuthService auth, Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: MaterialApp(home: home),
    );

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('Huy hiệu: đã nhận có ngày nhận, chưa nhận hiện điều kiện + khóa', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(await loggedInGamer(), const BadgesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Đã nhận 1/2 huy hiệu'), findsOneWidget);
    expect(find.text('Nhận ngày 12/10/2026'), findsOneWidget);
    expect(find.text('Viết 20 bình luận trong các Zone'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('Hồ sơ game thủ có mục Huy hiệu, bấm vào mở danh sách', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(await loggedInGamer(), const Scaffold(body: ProfileScreen())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Huy hiệu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huy hiệu'));
    await tester.pumpAndSettle();

    expect(find.byType(BadgesScreen), findsOneWidget);
  });

  testWidgets('Thông báo nhận huy hiệu mở màn Huy hiệu', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final backend = fakeBackend();
    final auth = createAuth((req) async {
      if (req.url.path == '/api/notifications') {
        return jsonResponse([notificationJson('n5', 'BadgeEarned', 'Nhận huy hiệu mới: 💬 Hòa đồng', link: 'badges')]);
      }
      return backend(req);
    });
    await auth.login('gamer@blush.vn', '123456');
    await tester.pumpWidget(_wrap(auth, const NotificationsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhận huy hiệu mới: 💬 Hòa đồng'));
    await tester.pumpAndSettle();

    expect(find.byType(BadgesScreen), findsOneWidget);
  });
}
