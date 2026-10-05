import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:blush_mobile_app/models/payment_model.dart';
import 'package:blush_mobile_app/screens/checkout_screen.dart';
import 'package:blush_mobile_app/screens/payment_flow_screens.dart';
import 'package:blush_mobile_app/screens/vip_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

/// Ghi lại các request app đã gửi để kiểm tra
class _Recorder {
  final List<http.Request> requests = [];
  bool called(String method, String path) => requests.any((r) => r.method == method && r.url.path == '/api/$path');
}

Future<AuthService> _gamerWithBackend(_Recorder recorder, {Future<http.Response?> Function(http.Request)? override}) async {
  final backend = fakeBackend();
  final auth = createAuth((req) async {
    recorder.requests.add(req);
    return await override?.call(req) ?? await backend(req);
  });
  await auth.login('gamer@blush.vn', '123456');
  return auth;
}

Widget _app(AuthService auth, Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: MaterialApp(home: home),
    );

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(loadRobotoFromSdk);

  group('định dạng', () {
    test('formatVnd', () {
      expect(formatVnd(0), '0đ');
      expect(formatVnd(29000), '29.000đ');
      expect(formatVnd(1290000), '1.290.000đ');
    });

    test('giờ từ backend không có "Z" được hiểu là UTC', () {
      final d = parseServerDate('2026-10-05T07:00:00')!;
      expect(d.toUtc(), DateTime.utc(2026, 10, 5, 7));
      expect(parseServerDate('2026-10-05T07:00:00Z')!.toUtc(), DateTime.utc(2026, 10, 5, 7));
      expect(parseServerDate(null), isNull);
    });

    test('gói 3 tháng: tính giá mỗi tháng', () {
      final pkg = VipPackage.fromJson(vipPackagesJson[2]);
      expect(pkg.months, 3);
      expect(pkg.periodLabel, '/ 3 tháng');
      expect(pkg.monthlyPrice, 43000);
    });
  });

  testWidgets('chọn gói -> MoMo giả lập -> xác nhận -> thành công, cập nhật lại user', (tester) async {
    _phoneSize(tester);
    final recorder = _Recorder();
    final auth = await _gamerWithBackend(recorder);
    await tester.pumpWidget(_app(auth, const VipScreen()));
    await tester.pumpAndSettle();

    // 3 gói từ API, chọn gói 3 tháng (cuối danh sách)
    expect(find.text('BLUSH Pass Pro 3 tháng'), findsOneWidget);
    expect(find.text('Chỉ 43.000đ mỗi tháng'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Chọn gói này').last, 200);
    await tester.tap(find.text('Chọn gói này').last);
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutScreen), findsOneWidget);

    // MoMo được chọn sẵn (phương thức đầu tiên dùng được)
    await tester.tap(find.widgetWithText(ElevatedButton, 'Thanh toán'));
    await tester.pumpAndSettle();
    final checkoutReq = recorder.requests.lastWhere((r) => r.url.path == '/api/payment/checkout');
    expect(jsonDecode(checkoutReq.body), {'packageCode': 'quarter_pro', 'method': 'MoMo'});
    expect(find.byType(MockGatewayScreen), findsOneWidget);
    expect(find.text('Cổng Ví MoMo'), findsOneWidget);

    await tester.tap(find.text('Xác nhận thanh toán 129.000đ'));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán thành công'), findsOneWidget);
    expect(recorder.called('GET', 'auth/me'), isTrue); // lấy lại user để thấy VIP mới

    await tester.tap(find.text('Về trang chủ'));
    await tester.pumpAndSettle();
    expect(find.byType(VipScreen), findsOneWidget); // về màn đầu tiên
  });

  testWidgets('phương thức chưa hỗ trợ thì không chọn được', (tester) async {
    _phoneSize(tester);
    // Backend chạy thật mà chưa có key PayOS -> VietQR không dùng được
    final auth = await _gamerWithBackend(_Recorder(), override: (req) async {
      if (req.url.path != '/api/payment/methods') return null;
      return jsonResponse([paymentMethodsJson[0], {...paymentMethodsJson[1], 'isAvailable': false}]);
    });
    await tester.pumpWidget(_app(auth, CheckoutScreen(package: VipPackage.fromJson(vipPackagesJson[0]))));
    await tester.pumpAndSettle();

    expect(find.text('Chưa hỗ trợ'), findsOneWidget);
    await tester.tap(find.text('Chuyển khoản VietQR'));
    await tester.pump();
    final radios = tester.widgetList<Icon>(find.byIcon(Icons.radio_button_checked));
    expect(radios.length, 1);
    // vẫn là MoMo được chọn
    expect(find.descendant(of: find.ancestor(of: find.text('Ví MoMo'), matching: find.byType(Row)).first, matching: find.byIcon(Icons.radio_button_checked)), findsOneWidget);
  });

  testWidgets('giả lập thất bại -> "Thử lại" quay về chọn phương thức', (tester) async {
    _phoneSize(tester);
    final auth = await _gamerWithBackend(_Recorder());
    await tester.pumpWidget(_app(auth, CheckoutScreen(package: VipPackage.fromJson(vipPackagesJson[1]))));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Thanh toán'));
    await tester.pumpAndSettle();
    expect(find.text('Cổng Ví MoMo'), findsOneWidget);

    await tester.tap(find.text('Giả lập giao dịch thất bại'));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán thất bại'), findsOneWidget);
    expect(find.text('Giao dịch bị từ chối (giả lập)'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutScreen), findsOneWidget);
  });

  testWidgets('VietQR: app tự hỏi trạng thái, ngân hàng xác nhận thì sang màn thành công', (tester) async {
    _phoneSize(tester);
    var polls = 0;
    final auth = await _gamerWithBackend(_Recorder(), override: (req) async {
      if (req.method == 'GET' && req.url.path == '/api/payment/transactions/$testOrderCode') {
        polls++;
        // Lần hỏi thứ 2 thì ngân hàng đã báo nhận tiền
        return jsonResponse(transactionJson(status: polls >= 2 ? 'Paid' : 'Pending', method: 'VietQR'));
      }
      return null;
    });
    await tester.pumpWidget(_app(auth, BankTransferScreen(checkout: CheckoutResult.fromJson(checkoutJson('VietQR')))));
    await tester.pump();

    expect(find.text('BLUSH $testOrderCode'), findsOneWidget); // nội dung chuyển khoản
    expect(find.text('Đang chờ ngân hàng xác nhận...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('Thanh toán thành công'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(polls, 2);
    expect(find.text('Thanh toán thành công'), findsOneWidget);
  });

  testWidgets('VietQR qua PayOS: vẽ QR trong app, có nút mở trang PayOS, không có nút giả lập', (tester) async {
    _phoneSize(tester);
    final auth = await _gamerWithBackend(_Recorder());
    await tester.pumpWidget(_app(auth, BankTransferScreen(checkout: CheckoutResult.fromJson(checkoutJson('VietQR', isMock: false)))));
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('CSQ1A2B3 BLUSH VIP'), findsOneWidget); // nội dung do PayOS tạo
    expect(find.text('Mở trang thanh toán PayOS'), findsOneWidget);
    expect(find.text('Giả lập: ngân hàng đã nhận tiền'), findsNothing);
  });

  testWidgets('hủy giao dịch phải xác nhận lại', (tester) async {
    _phoneSize(tester);
    final recorder = _Recorder();
    final auth = await _gamerWithBackend(recorder);
    await tester.pumpWidget(_app(auth, MockGatewayScreen(checkout: CheckoutResult.fromJson(checkoutJson('MoMo')))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hủy giao dịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục thanh toán'));
    await tester.pumpAndSettle();
    expect(recorder.called('POST', 'payment/transactions/$testOrderCode/cancel'), isFalse);

    await tester.tap(find.text('Hủy giao dịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy giao dịch').last);
    await tester.pumpAndSettle();
    expect(recorder.called('POST', 'payment/transactions/$testOrderCode/cancel'), isTrue);
    expect(find.text('Giao dịch đã hủy'), findsOneWidget);
  });
}
