import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/dashboard_screen.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('Trang chủ: tên riêng 1 dòng, không lặp Level/Coins, chấm xanh cho người đang online', (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = await loggedInGamer();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => QuestService()),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // "Xin chào" tách khỏi tên
    expect(find.text('Xin chào 👋'), findsOneWidget);
    expect(find.text('Lưu Phước Nhật Tú'), findsOneWidget);

    // Level + Coins chỉ ở thanh trên cùng (MainNavigationScreen), Trang chủ không lặp lại
    expect(find.textContaining('Lv.'), findsNothing);
    expect(find.textContaining('Level'), findsNothing);
    expect(find.text('340'), findsNothing);

    // 1 người hợp 95% đang online, 1 người 60% offline -> nói rõ số người, chỉ 1 chấm xanh
    expect(find.text('1 đồng đội hợp >80% đang online'), findsOneWidget);
    expect(find.byTooltip('Đang online'), findsOneWidget);
  });
}
