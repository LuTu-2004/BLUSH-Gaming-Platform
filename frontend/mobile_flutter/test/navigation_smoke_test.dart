import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/main.dart';
import 'package:blush_mobile_app/screens/admin_screen.dart';
import 'package:blush_mobile_app/screens/auth_screen.dart';
import 'package:blush_mobile_app/screens/chat_room_screen.dart';
import 'package:blush_mobile_app/screens/checkout_screen.dart';
import 'package:blush_mobile_app/screens/landing_screen.dart';
import 'package:blush_mobile_app/screens/staff_screen.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

// Font mặc định trong test vẽ mỗi chữ thành ô vuông (rộng hơn chữ thật),
// nên nạp font Roboto có sẵn trong Flutter SDK để đo kích thước giống điện thoại thật.
Future<void> _loadRobotoFromSdk() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final dir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final name in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf', 'roboto-italic.ttf']) {
    final file = File('$dir/$name');
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
  }
  await loader.load();
}

// Mở từng tab trên màn hình cỡ điện thoại (360x800) để bắt lỗi overflow (sọc vàng-đen)
void main() {
  setUpAll(_loadRobotoFromSdk);

  testWidgets('đăng nhập rồi mở từng tab không bị lỗi', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
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
        child: const BlushApp(),
      ),
    );
    await tester.pump();

    for (final label in ['Tìm Zone', 'Bảng Xếp Hạng', 'Nhiệm Vụ', 'VIP Pass', 'Hồ Sơ', 'Trang Chủ']) {
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(milliseconds: 300));
    }
  });

  final standaloneScreens = <String, Widget>{
    'Landing': const LandingScreen(),
    'Đăng nhập': const AuthScreen(isLogin: true),
    'Đăng ký': const AuthScreen(isLogin: false),
    'Chat': const ChatRoomScreen(),
    'Checkout': const CheckoutScreen(planName: 'BLUSH Pass Pro', price: '49K'),
    'Staff': const StaffScreen(),
    'Admin': const AdminScreen(),
  };

  standaloneScreens.forEach((name, screen) {
    testWidgets('màn $name không bị overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
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
          child: MaterialApp(home: screen),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
