import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/match_log_screen.dart';
import 'package:blush_mobile_app/screens/quests_screen.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(loadRobotoFromSdk);

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
