import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/main.dart';
import 'package:blush_mobile_app/screens/admin_screen.dart';
import 'package:blush_mobile_app/screens/main_navigation_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';
import 'package:blush_mobile_app/widgets/revenue_charts.dart';

import 'test_helpers.dart';

Future<AuthService> _admin(List<http.Request> requests) async {
  final backend = fakeBackend(user: {...gamerJson(), 'role': 'Admin'});
  final auth = createAuth((req) async {
    requests.add(req);
    return backend(req);
  });
  await auth.login('admin@blush.vn', '123456');
  return auth;
}

Widget _app(AuthService auth) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: const MaterialApp(home: AdminScreen()),
    );

/// Màn máy tính: menu cố định bên trái, bảng giao dịch nhiều cột
void _desktopSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(loadRobotoFromSdk);

  test('compactVnd', () {
    expect(compactVnd(0), '0');
    expect(compactVnd(49000), '49K');
    expect(compactVnd(1223000), '1,2tr');
    expect(compactVnd(15000000), '15tr');
  });

  testWidgets('Tổng quan: số liệu thật, đổi 7/30 ngày, chạm cột xem chi tiết', (tester) async {
    _desktopSize(tester);

    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _admin(requests)));
    await tester.pumpAndSettle();

    expect(find.text('1.223.000đ'), findsOneWidget);
    expect(find.text('27 giao dịch thành công / 33 giao dịch'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
    expect(find.text('1 giao dịch đang chờ thanh toán'), findsOneWidget);
    expect(find.text('236K'), findsOneWidget); // chỉ ghi số ở cột cao nhất

    // Chạm cột cao nhất (cách hôm nay 2 ngày) -> dòng chi tiết đổi sang ngày đó
    await tester.tap(find.text('236K'));
    await tester.pump();
    expect(find.text('03/10'), findsOneWidget);
    expect(find.text('236.000đ'), findsOneWidget);

    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();
    expect(requests.lastWhere((r) => r.url.path.endsWith('/summary')).url.queryParameters['days'], '7');
    expect(find.text('Doanh thu 7 ngày'), findsOneWidget);
    expect(find.text('305.000đ'), findsNWidgets(2)); // doanh thu 7 ngày = doanh thu tháng này trong dữ liệu mẫu
  });

  testWidgets('Giao dịch: lọc, xác nhận chuyển khoản VietQR', (tester) async {
    _desktopSize(tester);

    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _admin(requests)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giao dịch'));
    await tester.pumpAndSettle();

    expect(find.text('25 giao dịch'), findsOneWidget);
    expect(find.text('Tải thêm (23)'), findsOneWidget);
    // Chỉ giao dịch VietQR chưa trả mới có nút xác nhận tay
    expect(find.text('Xác nhận đã nhận tiền'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Đang chờ'));
    await tester.pumpAndSettle();
    expect(requests.last.url.queryParameters['status'], 'Pending');

    await tester.tap(find.text('Xác nhận đã nhận tiền'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/api/admin/payments/transactions/179116082433973/confirm');
    expect(find.text('Xác nhận đã nhận tiền'), findsNothing);
    expect(find.text('Thành công'), findsWidgets);
  });

  testWidgets('Người dùng: số liệu thật, lọc, tạm khóa và đổi vai trò gọi API', (tester) async {
    _desktopSize(tester);

    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _admin(requests)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Người dùng'));
    await tester.pumpAndSettle();

    expect(find.text('3 người dùng'), findsOneWidget);
    expect(find.text('11'), findsOneWidget); // KPI thành viên
    expect(find.text('Super Admin (bạn)'), findsOneWidget);
    expect(find.text('Khóa vĩnh viễn'), findsWidgets); // chip lọc + nhãn trạng thái người bị khóa
    expect(find.byTooltip('Thao tác'), findsNWidgets(2)); // không có menu cho chính mình

    await tester.tap(find.widgetWithText(ChoiceChip, 'Staff'));
    await tester.pumpAndSettle();
    expect(requests.last.url.queryParameters['role'], 'Staff');

    // Tạm khóa ToxicGamer99 (người thứ 2)
    await tester.tap(find.byTooltip('Thao tác').first);
    await tester.pumpAndSettle();
    expect(find.text('Mở khóa tài khoản'), findsNothing);
    await tester.tap(find.text('Tạm khóa 7 ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Tạm khóa'));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/admin/users/u-toxic/status');
    expect(jsonDecode(requests.last.body), {'status': 'Suspended', 'suspendDays': 7});
    expect(find.textContaining('Tạm khóa đến'), findsOneWidget);

    // Đổi vai trò
    await tester.tap(find.byTooltip('Thao tác').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt vai trò Staff'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Đổi'));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/admin/users/u-toxic/role');
    expect(jsonDecode(requests.last.body), {'role': 'Staff'});
  });

  testWidgets('Người dùng: nút AI phân tích phong cách chơi của hồ sơ cũ', (tester) async {
    _desktopSize(tester);

    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _admin(requests)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Người dùng'));
    await tester.pumpAndSettle();

    expect(find.text('AI ghép đội'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Phân tích'));
    await tester.pumpAndSettle();
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/api/admin/ai/playstyles');
    expect(find.text('AI đã phân tích 9 hồ sơ.'), findsOneWidget);
  });

  test('token bị từ chối (tài khoản bị khóa) -> tự đăng xuất', () async {
    var locked = false;
    final backend = fakeBackend();
    final auth = createAuth((req) async {
      if (locked && !req.url.path.endsWith('auth/login')) return http.Response('', 401);
      return backend(req);
    });
    await auth.login('gamer@blush.vn', '123456');
    expect(auth.isLoggedIn, isTrue);

    locked = true;
    await expectLater(auth.refreshUser(), throwsA(anything));
    expect(auth.isLoggedIn, isFalse);
    expect(auth.api.accessToken, isNull);
  });

  test('sai mật khẩu (401 khi chưa có token) không gọi đăng xuất', () async {
    var calls = 0;
    final auth = createAuth((req) async => http.Response('{"message":"Sai email hoặc mật khẩu."}', 401));
    auth.api.onUnauthorized = () => calls++;
    await expectLater(auth.login('a@b.vn', 'x'), throwsA(anything));
    expect(calls, 0);
  });

  testWidgets('Admin đăng nhập vào thẳng trang quản trị, chuyển được sang app người dùng', (tester) async {
    _desktopSize(tester);
    final auth = await _admin([]);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: const BlushApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(AdminScreen), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);

    await tester.tap(find.text('Xem app người dùng'));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });

  testWidgets('Màn hẹp: menu nằm trong ngăn kéo ☰', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(await _admin([])));
    await tester.pumpAndSettle();

    expect(find.text('Người dùng'), findsNothing); // menu đang ẩn
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Người dùng'));
    await tester.pumpAndSettle();
    expect(find.text('3 người dùng'), findsOneWidget); // màn hẹp vẫn hiện danh sách, không tràn chữ
  });
}
