import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/staff_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';
import 'package:blush_mobile_app/widgets/report_user_sheet.dart';

import 'test_helpers.dart';

Future<AuthService> _login(List<http.Request> requests, {String role = 'Staff'}) async {
  final backend = fakeBackend(user: {...gamerJson(), 'role': role});
  final auth = createAuth((req) async {
    requests.add(req);
    return backend(req);
  });
  await auth.login('staff@blush.vn', '123456');
  return auth;
}

Widget _wrap(AuthService auth, Widget home) => MultiProvider(
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

  testWidgets('Staff: mở ra thấy báo cáo đang chờ, tạm khóa phải xác nhận rồi gọi API', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _login(requests), const StaffScreen()));
    await tester.pumpAndSettle();

    final list = requests.lastWhere((r) => r.url.path == '/api/staff/reports');
    expect(list.url.queryParameters['status'], 'Pending');
    expect(find.text('Mức cao'), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // tổng số báo cáo

    await tester.tap(find.text('Tạm khóa 3 ngày'));
    await tester.pumpAndSettle();
    expect(find.text('Tạm khóa 3 ngày?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Tạm khóa'));
    await tester.pumpAndSettle();

    final resolve = requests.firstWhere((r) => r.url.path == '/api/staff/reports/7/resolve');
    expect(jsonDecode(resolve.body), {'action': 'Suspend'});
    expect(requests.last.url.path, '/api/staff/reports'); // tải lại danh sách + số liệu
  });

  testWidgets('Staff: thêm, bật/tắt, xóa câu hỏi phá băng', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _login(requests), const StaffScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Câu hỏi phá băng'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Câu hỏi'), 'Cosplay tướng nào?');
    await tester.enterText(find.widgetWithText(TextField, 'Lựa chọn A'), 'Đỡ đòn');
    await tester.enterText(find.widgetWithText(TextField, 'Lựa chọn B'), 'Sát thủ');
    await tester.tap(find.text('Thêm câu hỏi'));
    await tester.pumpAndSettle();
    final create = requests.lastWhere((r) => r.method == 'POST' && r.url.path == '/api/staff/icebreakers');
    expect(jsonDecode(create.body), {'category': 'Strategy', 'question': 'Cosplay tướng nào?', 'optionA': 'Đỡ đòn', 'optionB': 'Sát thủ'});

    await tester.ensureVisible(find.text('Vào sảnh bạn thích?', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(find.text('Danh sách câu hỏi (2 đang bật)'), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/staff/icebreakers/2/active');
    expect(jsonDecode(requests.last.body), {'isActive': true});
    expect(find.text('Danh sách câu hỏi (3 đang bật)'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(requests.last.method, 'DELETE');
    expect(requests.last.url.path, '/api/staff/icebreakers/2');
    expect(find.text('Vào sảnh bạn thích?'), findsNothing);
  });

  testWidgets('Báo cáo vi phạm: phải chọn lý do mới gửi được', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    final auth = await _login(requests, role: 'User');
    await tester.pumpWidget(_wrap(
      auth,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => ReportUserSheet.show(context, userId: 'u-toxic', displayName: 'ToxicGamer99'),
            child: const Text('mo'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('mo'));
    await tester.pumpAndSettle();

    final send = find.widgetWithText(ElevatedButton, 'Gửi báo cáo');
    expect(tester.widget<ElevatedButton>(send).onPressed, isNull);

    await tester.tap(find.text('Chửi thề, xúc phạm'));
    await tester.enterText(find.byType(TextField), '  chửi cả team  ');
    await tester.pumpAndSettle();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(jsonDecode(requests.last.body), {'reportedUserId': 'u-toxic', 'reasonCode': 'Toxic', 'detail': 'chửi cả team'});
    expect(find.text('Gửi báo cáo'), findsNothing); // bảng đã đóng
    expect(find.text('Đã gửi báo cáo. Cảm ơn bạn, Staff sẽ xem xét sớm.'), findsOneWidget);
  });
}
