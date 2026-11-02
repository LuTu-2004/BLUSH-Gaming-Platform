import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/profile_screen.dart';
import 'package:blush_mobile_app/screens/vip_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

Widget _app(AuthService auth, Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: MaterialApp(home: home),
    );

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('Đang dùng BLUSH Pass thường: gói thường "Gia hạn thêm", gói Pro "Nâng cấp lên Pro", không còn tokens', (tester) async {
    tester.view.physicalSize = const Size(360, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = createAuth(fakeBackend(user: {...gamerJson(), 'isVip': true, 'vipPackageName': 'BLUSH Pass', 'vipExpireAt': '2026-12-01T00:00:00Z'}));
    await auth.login('gamer@blush.vn', '123456');
    await tester.pumpWidget(_app(auth, const VipScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Gia hạn thêm'), findsOneWidget);
    expect(find.text('Nâng cấp lên Pro'), findsNWidgets(2)); // Pro 1 tháng + Pro 3 tháng
    expect(find.text('Chọn gói này'), findsNothing);
    expect(find.textContaining('Bắt đầu sau khi gói hiện tại hết hạn'), findsNWidgets(3));
    expect(find.textContaining('tokens'), findsNothing);
  });

  testWidgets('Hồ sơ: nút lưu chỉ bấm được khi đã sửa chữ, không còn thẻ Lịch sử thanh toán', (tester) async {
    tester.view.physicalSize = const Size(360, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(await loggedInGamer(), const Scaffold(body: ProfileScreen())));
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử thanh toán'), findsNothing);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget); // Sở thích chơi game có icon riêng

    ButtonStyleButton saveButton(String label) =>
        tester.widget<ButtonStyleButton>(find.ancestor(of: find.text(label), matching: find.bySubtype<ButtonStyleButton>()));
    expect(saveButton('Đã lưu').onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Giới thiệu bản thân'), 'Main support, tối nào cũng online');
    await tester.pump();
    expect(saveButton('Lưu thay đổi').onPressed, isNotNull);
  });
}
