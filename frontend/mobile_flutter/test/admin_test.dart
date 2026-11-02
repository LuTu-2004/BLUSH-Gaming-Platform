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
    expect(find.text('Giao dịch thành công'), findsOneWidget);
    // Tổng quan chỉ nói về giao dịch thành công: không còn tỉ lệ thành công / đang chờ
    expect(find.text('DOANH THU · 30 NGÀY QUA'), findsOneWidget); // nhãn nhóm ghi rõ khoảng thời gian đang lọc
    expect(find.textContaining('· tháng này '), findsOneWidget); // hôm nay / tháng này chỉ là dòng phụ
    expect(find.text('Đánh giá trung bình'), findsOneWidget);
    // Hàng hoạt động: app có đang được dùng không, kể cả ngày không có doanh thu
    expect(find.text('HOẠT ĐỘNG · 30 NGÀY QUA'), findsOneWidget);
    expect(find.text('Trung bình 7,5 tin mỗi chat'), findsOneWidget); // 30 tin / 4 cuộc
    expect(find.text('2 trận đồng đội đã xác nhận'), findsOneWidget);
    expect(find.text('Cơ cấu doanh thu'), findsOneWidget);
    expect(find.text('45.296đ'), findsOneWidget); // giá trị trung bình = 1.223.000đ / 27 giao dịch
    expect(find.text('13 giao dịch thành công'), findsOneWidget); // gói bán chạy nhất: BLUSH Pass
    expect(find.text('82%'), findsNothing);
    expect(find.text('1 giao dịch đang chờ thanh toán'), findsNothing);
    expect(find.text('Giao dịch thành công gần đây'), findsOneWidget);
    expect(requests.firstWhere((r) => r.url.path == '/api/admin/payments/transactions').url.queryParameters['status'], 'Paid');

    // Nhấn 1 giao dịch -> copy mã đơn (đối soát VietQR, hỗ trợ người dùng)
    final firstOrder = find.textContaining(RegExp(r'^#\d+$')).first;
    await tester.ensureVisible(firstOrder);
    await tester.tap(firstOrder);
    await tester.pump();
    expect(find.textContaining('Đã copy mã đơn #'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5)); // đợi thông báo tắt
    expect(find.text('236K'), findsOneWidget); // chỉ ghi số ở cột cao nhất

    // Chạm cột cao nhất (cách hôm nay 2 ngày) -> dòng chi tiết đổi sang ngày đó
    await tester.ensureVisible(find.text('236K'));
    await tester.tap(find.text('236K'));
    await tester.pump();
    expect(find.text('03/10'), findsOneWidget);
    expect(find.text('236.000đ'), findsOneWidget);

    await tester.ensureVisible(find.text('7 ngày'));
    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();
    expect(requests.lastWhere((r) => r.url.path.endsWith('/summary')).url.queryParameters['days'], '7');
    expect(find.text('DOANH THU · 7 NGÀY QUA'), findsOneWidget);
    expect(find.text('305.000đ'), findsOneWidget); // doanh thu 7 ngày (tháng này chỉ nằm trong dòng phụ)
  });

  testWidgets('Google Analytics: số liệu landing + app, bảng nguồn, đổi 7/30/90 ngày', (tester) async {
    _desktopSize(tester);

    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _admin(requests)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Google Analytics'));
    await tester.pumpAndSettle();

    expect(find.text('1.234'), findsOneWidget); // người xem landing, có dấu chấm ngăn nghìn
    expect(find.text('26% người xem bấm tải'), findsOneWidget); // 321 / 1234
    expect(find.text('+40 người mới trong 30 ngày'), findsOneWidget);
    expect(find.text('facebook'), findsOneWidget);
    expect(find.text('Mua VIP thành công'), findsOneWidget);
    expect(find.text('Mở Google Analytics'), findsOneWidget); // nút trong trang (menu trái không lặp lại)

    await tester.tap(find.text('90 ngày'));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/admin/analytics');
    expect(requests.last.url.queryParameters['days'], '90');
  });

  testWidgets('Google Analytics chưa kết nối: hiện lời nhắn và các bước, không hiện số 0', (tester) async {
    _desktopSize(tester);

    final backend = fakeBackend(user: {...gamerJson(), 'role': 'Admin'});
    final auth = createAuth((req) async {
      if (req.url.path == '/api/admin/analytics') {
        return jsonResponse({'available': false, 'message': 'Chưa đặt GoogleAnalytics:PropertyId.', 'days': 30});
      }
      return backend(req);
    });
    await auth.login('admin@blush.vn', '123456');
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Google Analytics'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa kết nối Google Analytics'), findsOneWidget);
    expect(find.text('Chưa đặt GoogleAnalytics:PropertyId.'), findsOneWidget);
    expect(find.text('Người xem landing page'), findsNothing);
  });

  testWidgets('Tổng quan có box đánh giá; Lịch sử đánh giá: lọc theo số sao, xem ai chấm mấy sao', (tester) async {
    _desktopSize(tester);

    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _admin(requests)));
    await tester.pumpAndSettle();

    // Box nguồn người dùng: số đã trả lời + từng kênh kèm %
    expect(find.text('Nguồn người dùng'), findsOneWidget);
    expect(find.text('8/10 gamer đã trả lời (80%)'), findsOneWidget);
    expect(find.text('4 · 50%'), findsOneWidget); // Facebook 4/8
    expect(find.text('0'), findsNWidgets(2)); // YouTube, Khác: chưa ai chọn nhưng vẫn hiện

    // Box ở Tổng quan: điểm trung bình + số lượt
    expect(find.text('Đánh giá từ người dùng'), findsOneWidget);
    expect(find.text('4,3'), findsOneWidget);
    expect(find.text('6 lượt đánh giá'), findsNWidgets(2)); // thẻ Đánh giá trung bình + khung Đánh giá

    await tester.ensureVisible(find.text('Xem lịch sử')); // box nằm cuối trang, cuộn tới rồi mới bấm
    await tester.tap(find.text('Xem lịch sử'));
    await tester.pumpAndSettle();
    expect(find.text('3 đánh giá'), findsOneWidget);
    expect(find.text('Khánh Linh'), findsOneWidget);
    expect(find.text('Ghép đội nhanh, rất hợp gu!'), findsOneWidget);
    expect(find.text('Không để lại góp ý'), findsOneWidget);
    expect(find.textContaining('đã sửa'), findsOneWidget); // Đăng Khoa sửa đánh giá sau 1 ngày

    await tester.tap(find.widgetWithText(ChoiceChip, '3★ (1)'));
    await tester.pumpAndSettle();
    expect(requests.last.url.queryParameters['stars'], '3');
    expect(find.text('1 đánh giá 3 sao'), findsOneWidget);
    expect(find.text('Bảo Nam'), findsOneWidget);
    expect(find.text('Khánh Linh'), findsNothing);
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
    expect(find.byTooltip('Xác nhận đã nhận tiền'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Đang chờ'));
    await tester.pumpAndSettle();
    expect(requests.last.url.queryParameters['status'], 'Pending');

    await tester.tap(find.byTooltip('Xác nhận đã nhận tiền'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Xác nhận'));
    await tester.pumpAndSettle();
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/api/admin/payments/transactions/179116082433973/confirm');
    expect(find.byTooltip('Xác nhận đã nhận tiền'), findsNothing);
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
