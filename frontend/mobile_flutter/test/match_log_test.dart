import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/match_log_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

Future<AuthService> _gamer(List<http.Request> requests) async {
  final backend = fakeBackend();
  final auth = createAuth((req) async {
    requests.add(req);
    return backend(req);
  });
  await auth.login('gamer@blush.vn', '123456');
  return auth;
}

Widget _wrap(AuthService auth) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: const MaterialApp(home: MatchLogScreen()),
    );

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('trận người khác ghi: xác nhận gọi API, thẻ chuyển sang "Đã xác nhận"', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests)));
    await tester.pumpAndSettle();

    expect(find.text('Chờ bạn xác nhận'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Xác nhận'));
    await tester.pumpAndSettle();

    expect(requests.last.url.path, '/api/matches/mt1/confirm');
    expect(jsonDecode(requests.last.body), {'confirm': true});
    expect(find.text('Đã xác nhận'), findsWidgets);
  });

  testWidgets('ghi trận mới: chọn đồng đội, game, kết quả rồi gửi', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ghi trận mới'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(SegmentedButton<bool>), matching: find.text('Thua')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi cho đồng đội xác nhận'));
    await tester.pumpAndSettle();

    final create = requests.lastWhere((r) => r.method == 'POST' && r.url.path == '/api/matches');
    expect(jsonDecode(create.body), {'teammateId': 'u-toxic', 'gameId': 1, 'result': 'Loss'});
    expect(find.text('Chờ ToxicGamer99 xác nhận'), findsOneWidget);
  });

  testWidgets('khai rank từ danh sách rank của game', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Chưa khai')); // chưa khai rank
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chưa khai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cao Thủ').last);
    await tester.pumpAndSettle();

    expect(requests.last.url.path, '/api/matches/rank');
    expect(jsonDecode(requests.last.body), {'gameId': 1, 'rank': 'Cao Thủ'});
  });
}
