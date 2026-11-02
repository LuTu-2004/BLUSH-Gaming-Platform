import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/api/api_client.dart';
import 'package:blush_mobile_app/screens/match_feed_screen.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

// Trang lỗi dạng chữ mà ASP.NET trả khi lỗi 500 ở chế độ dev (VD thiếu cột DB)
const _devErrorPage = "Microsoft.Data.SqlClient.SqlException (0x80131904): Invalid column name 'BanterLevel'.";

ApiClient _client(int status, String body) =>
    ApiClient(httpClient: MockClient((_) async => http.Response.bytes(utf8.encode(body), status)), baseUrl: 'http://test/api');

void main() {
  setUpAll(loadRobotoFromSdk);

  test('lỗi 500 trả chữ (không phải JSON) -> ApiException dễ hiểu, không phải FormatException', () async {
    await expectLater(
      _client(500, _devErrorPage).get('onboarding'),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Máy chủ đang gặp lỗi, vui lòng thử lại sau.')
          .having((e) => e.statusCode, 'statusCode', 500)),
    );
  });

  test('200 nhưng nội dung không phải JSON -> ApiException', () async {
    await expectLater(_client(200, '<html>proxy</html>').get('quest'), throwsA(isA<ApiException>()));
  });

  test('lỗi có JSON vẫn lấy câu báo lỗi của backend', () async {
    await expectLater(
      _client(400, '{"message":"Khu vực không hợp lệ."}').get('onboarding'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Khu vực không hợp lệ.')),
    );
  });

  testWidgets('Đồng đội: backend lỗi 500 dạng chữ -> hiện lỗi + nút Thử lại thay vì quay vòng mãi', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final backend = fakeBackend();
    final auth = createAuth((req) async =>
        req.url.path == '/api/match/suggestions' ? http.Response(_devErrorPage, 500) : await backend(req));
    await auth.login('gamer@blush.vn', '123456');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => QuestService()),
        ],
        child: const MaterialApp(home: Scaffold(body: MatchFeedScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Máy chủ đang gặp lỗi, vui lòng thử lại sau.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
