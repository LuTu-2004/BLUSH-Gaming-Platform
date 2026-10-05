import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/main.dart';
import 'package:blush_mobile_app/models/onboarding_model.dart';
import 'package:blush_mobile_app/screens/main_navigation_screen.dart';
import 'package:blush_mobile_app/screens/onboarding_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

Widget _app(AuthService auth) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: const BlushApp(),
    );

/// Bấm nút ở thanh dưới cùng (Tiếp tục / Hoàn tất)
ElevatedButton _bottomButton(WidgetTester tester) => tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);

void main() {
  setUpAll(loadRobotoFromSdk);

  group('UserModel.needsOnboarding', () {
    test('gamer chưa làm khảo sát -> cần làm', () async {
      final auth = await loggedInGamer(onboardingCompleted: false);
      expect(auth.currentUser!.needsOnboarding, isTrue);
    });

    test('Staff/Admin không bị bắt làm khảo sát', () async {
      final auth = createAuth(fakeBackend(user: {...gamerJson(onboardingCompleted: false), 'role': 'Admin'}));
      await auth.login('admin@blush.vn', '123456');
      expect(auth.currentUser!.needsOnboarding, isFalse);
    });

    test('backend cũ chưa có trường onboardingCompleted -> coi như đã làm', () async {
      final auth = createAuth(fakeBackend(user: gamerJson()..remove('onboardingCompleted')));
      await auth.login('gamer@blush.vn', '123456');
      expect(auth.currentUser!.needsOnboarding, isFalse);
    });
  });

  test('OnboardingAnswers đọc từ JSON rồi gửi lại đúng định dạng backend', () {
    final answers = OnboardingAnswers.fromJson(onboardingAnswersJson);
    expect(answers.games.keys, [1, 2]);
    expect(answers.games[1]!.position, 'Đường giữa');
    expect(answers.region, 'HCM');

    final json = answers.toJson();
    expect(json['games'], [
      {'gameId': 1, 'position': 'Đường giữa', 'purpose': 'Fun'},
      {'gameId': 2, 'position': null, 'purpose': 'Tryhard'},
    ]);
    expect(json['teammateWish'], '');
  });

  testWidgets('gamer mới: làm đủ 4 bước rồi vào trang chủ', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Map<String, dynamic>? savedBody;
    final backend = fakeBackend(user: gamerJson(onboardingCompleted: false));
    final auth = createAuth((req) async {
      if (req.method == 'POST' && req.url.path == '/api/onboarding') savedBody = jsonDecode(req.body);
      return backend(req);
    });
    await auth.login('gamer@blush.vn', '123456');

    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Bước 1: chưa chọn game thì chưa được tiếp tục
    expect(_bottomButton(tester).onPressed, isNull);
    await tester.tap(find.text('Valorant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duelist'));
    await tester.tap(find.text('Leo rank nghiêm túc'));
    await tester.pumpAndSettle();
    expect(_bottomButton(tester).onPressed, isNotNull);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    // Bước 2: khung giờ (không bắt buộc)
    await tester.tap(find.text('Tối (18h - 23h)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    // Bước 3: bắt buộc chọn khu vực
    expect(_bottomButton(tester).onPressed, isNull);
    await tester.tap(find.text('Hà Nội'));
    await tester.tap(find.text('Có, hay bật mic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    // Bước 4: sở thích + mô tả rồi hoàn tất
    await tester.tap(find.text('Anime'));
    await tester.enterText(find.byType(TextField), '  chill, không toxic  ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn tất'));
    await tester.pumpAndSettle();

    expect(savedBody, {
      'games': [
        {'gameId': 2, 'position': 'Duelist', 'purpose': 'Tryhard'},
      ],
      'playTimes': ['Evening'],
      'region': 'HN',
      'usesMic': true,
      'hobbyIds': [3],
      'teammateWish': 'chill, không toxic',
    });
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });

  testWidgets('quay lại bước trước vẫn giữ lựa chọn', (tester) async {
    final auth = await loggedInGamer(onboardingCompleted: false);
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Liên Quân Mobile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bước trước'));
    await tester.pumpAndSettle();

    expect(find.text('Chơi vui, giải trí'), findsOneWidget); // phần chọn mục đích của game đã chọn vẫn mở
    expect(_bottomButton(tester).onPressed, isNotNull);
  });
}
