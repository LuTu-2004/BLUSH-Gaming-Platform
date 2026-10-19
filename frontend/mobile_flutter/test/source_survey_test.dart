import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';
import 'package:blush_mobile_app/widgets/source_survey.dart';

import 'test_helpers.dart';

/// Backend giả có thêm GET/POST api/onboarding/source
Future<AuthService> _auth(List<http.Request> requests, {String? source}) async {
  final backend = fakeBackend();
  final auth = createAuth((req) async {
    requests.add(req);
    if (req.url.path == '/api/onboarding/source') {
      if (req.method == 'GET') return jsonResponse({'source': source});
      return jsonResponse({'source': (jsonDecode(req.body) as Map<String, dynamic>)['source']});
    }
    return backend(req);
  });
  await auth.login('gamer@blush.vn', '123456');
  return auth;
}

/// Trang trống có nút giả lập "mở app" -> gọi askForSourceOnce, ghi lại kết quả
Widget _app(AuthService auth, List<bool> shown) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(onPressed: () async => shown.add(await askForSourceOnce(context)), child: const Text('Mở app')),
          ),
        ),
      ),
    );

void main() {
  setUpAll(loadRobotoFromSdk);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Chưa trả lời: hỏi, chọn 1 nguồn rồi gửi; lần mở sau không hỏi nữa', (tester) async {
    final requests = <http.Request>[];
    final shown = <bool>[];
    await tester.pumpWidget(_app(await _auth(requests), shown));

    await tester.tap(find.text('Mở app'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn biết BLUSH qua đâu?'), findsOneWidget);
    // Chưa chọn thì chưa gửi được
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Gửi')).onPressed, isNull);

    await tester.tap(find.text('TikTok'));
    await tester.pump();
    await tester.tap(find.text('Gửi'));
    await tester.pumpAndSettle();
    final sent = requests.lastWhere((r) => r.method == 'POST' && r.url.path == '/api/onboarding/source');
    expect(jsonDecode(sent.body), {'source': 'tiktok'});
    expect(find.text('Cảm ơn bạn đã chia sẻ!'), findsOneWidget);
    expect(shown, [true]);

    await tester.tap(find.text('Mở app'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn biết BLUSH qua đâu?'), findsNothing);
    expect(shown, [true, false]);
  });

  testWidgets('Bấm "Bỏ qua": không gửi gì, lần sau cũng không hỏi lại', (tester) async {
    final requests = <http.Request>[];
    final shown = <bool>[];
    await tester.pumpWidget(_app(await _auth(requests), shown));

    await tester.tap(find.text('Mở app'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.method == 'POST' && r.url.path == '/api/onboarding/source'), isEmpty);

    await tester.tap(find.text('Mở app'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn biết BLUSH qua đâu?'), findsNothing);
  });

  testWidgets('Đã trả lời từ trước (máy khác) thì không hỏi', (tester) async {
    final requests = <http.Request>[];
    final shown = <bool>[];
    await tester.pumpWidget(_app(await _auth(requests, source: 'facebook'), shown));

    await tester.tap(find.text('Mở app'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn biết BLUSH qua đâu?'), findsNothing);
    expect(shown, [false]);
  });
}
