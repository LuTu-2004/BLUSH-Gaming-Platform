import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/landing_screen.dart';
import 'package:blush_mobile_app/screens/leaderboard_screen.dart';
import 'package:blush_mobile_app/screens/match_feed_screen.dart';
import 'package:blush_mobile_app/screens/vip_screen.dart';
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

// Tính năng chưa có trong app: không được quảng cáo / bán (luật bảo vệ người tiêu dùng + chính sách Google Play)
const _notBuiltYet = ['Xếp Zone bằng AI', 'Bong bóng chat', 'Nhóm kín', 'Coaching', 'giờ cao điểm', 'huy hiệu mỗi ngày', 'cho tới khi hai bên kết nối'];

void _expectNoFalseClaims(WidgetTester tester) {
  final texts = tester.widgetList<Text>(find.byType(Text, skipOffstage: false)).map((t) => t.data ?? '').join('\n');
  for (final claim in _notBuiltYet) {
    expect(texts.contains(claim), isFalse, reason: 'Màn hình vẫn nhắc "$claim" (chưa có tính năng này)');
  }
}

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('màn VIP chỉ ghi quyền lợi đang có thật', (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(await loggedInGamer(), const VipScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Không giới hạn lượt AI mỗi ngày'), findsWidgets);
    _expectNoFalseClaims(tester);
  });

  testWidgets('màn Landing không quảng cáo tính năng chưa có', (tester) async {
    tester.view.physicalSize = const Size(360, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(createAuth((_) async => fail('Landing không gọi API')), const LandingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Ghép đội thông minh'), findsOneWidget);
    _expectNoFalseClaims(tester);
  });

  testWidgets('huy hiệu VIP 👑 hiện cho người khác: thẻ đồng đội + bảng xếp hạng', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Đăng Khoa (isVip) trong gợi ý đồng đội
    await tester.pumpWidget(_wrap(await loggedInGamer(), const Scaffold(body: MatchFeedScreen())));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Thành viên BLUSH Pass', skipOffstage: false), findsOneWidget);

    // Bảo Nam (isVip) trên bảng xếp hạng
    await tester.pumpWidget(_wrap(await loggedInGamer(), const Scaffold(body: LeaderboardScreen())));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Thành viên BLUSH Pass', skipOffstage: false), findsOneWidget);
  });
}
