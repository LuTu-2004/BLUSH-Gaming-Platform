import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/main.dart';
import 'package:blush_mobile_app/screens/admin_screen.dart';
import 'package:blush_mobile_app/screens/auth_screen.dart';
import 'package:blush_mobile_app/screens/chat_room_screen.dart';
import 'package:blush_mobile_app/screens/checkout_screen.dart';
import 'package:blush_mobile_app/screens/enable_two_factor_screen.dart';
import 'package:blush_mobile_app/screens/forgot_password_screen.dart';
import 'package:blush_mobile_app/screens/landing_screen.dart';
import 'package:blush_mobile_app/screens/onboarding_screen.dart';
import 'package:blush_mobile_app/screens/payment_flow_screens.dart';
import 'package:blush_mobile_app/screens/payment_history_screen.dart';
import 'package:blush_mobile_app/models/payment_model.dart';
import 'package:blush_mobile_app/screens/staff_screen.dart';
import 'package:blush_mobile_app/screens/two_factor_screen.dart';
import 'package:blush_mobile_app/screens/vip_screen.dart';
import 'package:blush_mobile_app/screens/verify_email_screen.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

// Mở từng tab trên màn hình cỡ điện thoại (360x800) để bắt lỗi overflow (sọc vàng-đen)
void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('đăng nhập rồi mở từng tab không bị lỗi', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = await loggedInGamer();
    final theme = ThemeService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => QuestService()),
        ],
        child: const BlushApp(),
      ),
    );
    await tester.pump();

    // Chạy 2 vòng: giao diện tối rồi giao diện sáng
    for (var round = 0; round < 2; round++) {
      for (final label in ['Đồng đội', 'Xếp hạng', 'Nhiệm vụ', 'Hồ sơ', 'Trang chủ']) {
        await tester.tap(find.text(label).last);
        await tester.pump(const Duration(milliseconds: 300));
      }
      theme.toggleTheme();
      await tester.pump(const Duration(milliseconds: 300));
    }
  });

  final standaloneScreens = <String, Widget>{
    'Landing': const LandingScreen(),
    'Đăng nhập': const AuthScreen(isLogin: true),
    'Đăng ký': const AuthScreen(isLogin: false),
    'Xác minh email': const VerifyEmailScreen(email: 'mot.email.rat.dai.cua.sinh.vien@daihoc.edu.vn'),
    'Quên mật khẩu': const ForgotPasswordScreen(),
    'Xác thực 2 bước': const TwoFactorScreen(email: 'mot.email.rat.dai.cua.sinh.vien@daihoc.edu.vn'),
    'Bật 2 bước': const EnableTwoFactorScreen(email: 'mot.email.rat.dai.cua.sinh.vien@daihoc.edu.vn', password: 'x'),
    'Chat': const ChatRoomScreen(),
    'Checkout': CheckoutScreen(package: VipPackage.fromJson(vipPackagesJson[2])),
    'Cổng giả lập MoMo': MockGatewayScreen(checkout: CheckoutResult.fromJson(checkoutJson('MoMo'))),
    'Chuyển khoản VietQR (demo)': BankTransferScreen(checkout: CheckoutResult.fromJson(checkoutJson('VietQR'))),
    'Chuyển khoản VietQR (PayOS)': BankTransferScreen(checkout: CheckoutResult.fromJson(checkoutJson('VietQR', isMock: false))),
    'Chờ thanh toán MoMo': PaymentWaitingScreen(checkout: CheckoutResult.fromJson(checkoutJson('MoMo', isMock: false))),
    'Kết quả thành công': PaymentResultScreen(transaction: PaymentTransaction.fromJson(transactionJson(status: 'Paid'))),
    'Kết quả thất bại': PaymentResultScreen(transaction: PaymentTransaction.fromJson(transactionJson(status: 'Failed'))),
    'Lịch sử thanh toán': const PaymentHistoryScreen(),
    'Staff': const StaffScreen(),
    'VIP': const VipScreen(),
    'Admin': const AdminScreen(),
    'Onboarding': const OnboardingScreen(),
    'Sửa sở thích': const OnboardingScreen(isEditing: true),
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
