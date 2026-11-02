import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/match_log_screen.dart';
import 'package:blush_mobile_app/screens/quests_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

Future<void> _pumpQuests(WidgetTester tester, AuthService auth) async {
  tester.view.physicalSize = const Size(360, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final quests = QuestService();
  await quests.load(auth);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: quests),
      ],
      child: const MaterialApp(home: Scaffold(body: QuestsScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

ElevatedButton _chestButton(WidgetTester tester) => tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Mở rương'));

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('Rương khóa khi chưa xong hết nhiệm vụ ngày', (tester) async {
    await _pumpQuests(tester, await loggedInGamer()); // 2/3 nhiệm vụ ngày xong
    expect(find.text('Rương hoàn thành'), findsOneWidget);
    expect(find.textContaining('Xong 3/3 để mở'), findsOneWidget);
    expect(_chestButton(tester).onPressed, isNull);
  });

  testWidgets('Xong hết nhiệm vụ ngày: mở rương gọi API, cộng quà rồi hiện "Đã mở"', (tester) async {
    final today = DateTime.now().toUtc().add(const Duration(hours: 7)).toIso8601String().substring(0, 10);
    final requests = <http.Request>[];
    final backend = fakeBackend(user: gamerJson());
    final auth = createAuth((req) async {
      requests.add(req);
      final path = req.url.path.replaceFirst('/api/', '');
      if (path == 'quest') {
        return jsonResponse([for (final q in questsJson()) q['type'] == 'Daily' ? {...q, 'current': q['target'], 'isCompleted': true} : q]);
      }
      if (path == 'quest/claim-chest') {
        return jsonResponse({'message': 'Mở rương thành công!', 'addedCoins': 50, 'addedExp': 100, 'user': {...gamerJson(coins: 390, exp: 1250), 'lastDailyChestDate': today}});
      }
      return backend(req);
    });
    await auth.login('gamer@blush.vn', '123456');
    await _pumpQuests(tester, auth);

    expect(find.textContaining('Xong hết nhiệm vụ!'), findsOneWidget);
    await tester.tap(find.text('Mở rương'));
    await tester.pumpAndSettle();

    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/api/quest/claim-chest');
    expect(auth.currentUser!.coins, 390);
    expect(find.text('Đã mở'), findsOneWidget);
    expect(find.text('Mở rương'), findsNothing);
  });

  testWidgets('Nhiệm vụ chưa xong có nút "Làm ngay" mở đúng nơi làm', (tester) async {
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = await loggedInGamer();
    final quests = QuestService();
    await quests.load(auth);
    final tabs = <int>[];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: quests),
        ],
        child: MaterialApp(home: Scaffold(body: QuestsScreen(onNavigate: tabs.add))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lưu kết quả chơi cùng đồng đội để tính tiến độ nhiệm vụ'), findsOneWidget);
    // "Like 5 bài viết" (3/5) + "Đạt chuỗi 3 trận thắng" (0/3) chưa xong; xong rồi thì là Nhận quà / Đã nhận
    expect(find.text('Làm ngay'), findsNWidgets(2));
    expect(find.text('Đang làm'), findsNothing);

    // Like bài -> sang tab Cộng đồng
    await tester.tap(find.text('Làm ngay').first);
    expect(tabs, [2]);

    // Chuỗi thắng -> Nhật ký trận đấu
    await tester.tap(find.text('Làm ngay').last);
    await tester.pumpAndSettle();
    expect(find.byType(MatchLogScreen), findsOneWidget);
  });
}
