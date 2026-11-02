import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';
import 'package:blush_mobile_app/widgets/rate_app.dart';

import 'test_helpers.dart';

/// Backend giả có thêm GET/POST api/ratings/me
Future<AuthService> _auth(List<http.Request> requests, {bool shouldAsk = true}) async {
  final backend = fakeBackend();
  final auth = createAuth((req) async {
    requests.add(req);
    if (req.url.path == '/api/ratings/me') {
      if (req.method == 'GET') return jsonResponse({'stars': null, 'comment': null, 'updatedAt': null, 'shouldAsk': shouldAsk});
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return jsonResponse({'stars': body['stars'], 'comment': body['comment'], 'updatedAt': '2026-10-19T06:45:55', 'shouldAsk': false});
    }
    return backend(req);
  });
  await auth.login('gamer@blush.vn', '123456');
  return auth;
}

/// Trang trống có 2 nút: tự hỏi đánh giá / mục đánh giá trong Hồ sơ
Widget _app(AuthService auth) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(onPressed: () => askForRatingOnce(context), child: const Text('Mở app')),
                const RateAppTile(),
              ],
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(loadRobotoFromSdk);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Hồ sơ: chọn sao, chấm thấp thì gợi ý nói chỗ chưa ổn, gửi xong hiện số sao đã chấm', (tester) async {
    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _auth(requests)));
    await tester.pumpAndSettle();
    expect(find.text('Cho BLUSH biết bạn thấy app thế nào'), findsOneWidget);

    await tester.tap(find.text('Đánh giá BLUSH'));
    await tester.pumpAndSettle();
    // Chưa chọn sao thì chưa gửi được; tự mở từ Hồ sơ thì không có nút "Để sau"
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Gửi đánh giá')).onPressed, isNull);
    expect(find.text('Để sau'), findsNothing);

    await tester.tap(find.byTooltip('2 sao'));
    await tester.pump();
    expect(find.text('Chưa ổn'), findsOneWidget);
    expect(find.text('Điều gì khiến bạn chưa hài lòng? (không bắt buộc)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Ghép đội còn chậm  ');
    await tester.tap(find.text('Gửi đánh giá'));
    await tester.pumpAndSettle();

    final sent = requests.lastWhere((r) => r.method == 'POST' && r.url.path == '/api/ratings/me');
    expect(jsonDecode(sent.body), {'stars': 2, 'comment': 'Ghép đội còn chậm'});
    expect(find.text('Cảm ơn bạn đã đánh giá BLUSH!'), findsOneWidget);
    expect(find.text('Bạn đã chấm 2★ · Bấm để sửa'), findsOneWidget);
  });

  testWidgets('Tự hỏi đúng 1 lần: bấm "Để sau" thì lần mở app sau không hỏi nữa', (tester) async {
    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _auth(requests)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mở app'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn thấy BLUSH thế nào?'), findsOneWidget);

    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn thấy BLUSH thế nào?'), findsNothing);

    await tester.tap(find.text('Mở app'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn thấy BLUSH thế nào?'), findsNothing);
  });

  testWidgets('Backend báo chưa nên hỏi (mới dùng / đã đánh giá) thì không hỏi', (tester) async {
    final requests = <http.Request>[];
    await tester.pumpWidget(_app(await _auth(requests, shouldAsk: false)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mở app'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn thấy BLUSH thế nào?'), findsNothing);
  });
}
