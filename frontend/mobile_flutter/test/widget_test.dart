import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/api/api_client.dart';
import 'package:blush_mobile_app/main.dart';
import 'package:blush_mobile_app/screens/landing_screen.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

void main() {
  group('AuthService', () {
    test('đăng nhập thành công: lưu token, có thông tin user', () async {
      final storage = MemoryTokenStorage();
      late Map<String, dynamic> sentBody;
      final auth = createAuth((req) async {
        expect(req.url.path, '/api/auth/login');
        sentBody = jsonDecode(req.body);
        return jsonResponse(authResponse(gamerJson()));
      }, storage: storage);

      await auth.login(' gamer@blush.vn ', '123456');

      expect(sentBody['email'], 'gamer@blush.vn'); // đã bỏ khoảng trắng
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser!.displayName, 'Lưu Phước Nhật Tú');
      expect(auth.currentUser!.level, 12);
      expect(storage.token, 'fake-jwt-token');
    });

    test('sai mật khẩu: báo đúng lời nhắn của backend', () async {
      final auth = createAuth((_) async => jsonResponse({'message': 'Email hoặc mật khẩu không đúng.'}, 401));

      await expectLater(
        auth.login('gamer@blush.vn', 'sai'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Email hoặc mật khẩu không đúng.')),
      );
      expect(auth.isLoggedIn, isFalse);
    });

    test('lỗi validation của ASP.NET được đổi thành câu dễ hiểu', () async {
      final auth = createAuth((_) async => jsonResponse({
            'errors': {
              'Password': ['Mật khẩu quá ngắn']
            }
          }, 400));

      await expectLater(auth.register(displayName: 'A', email: 'a@b.vn', password: '1'), throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Mật khẩu quá ngắn')));
    });

    test('Google: gửi ID Token lên backend, đánh dấu người dùng mới', () async {
      late Map<String, dynamic> sentBody;
      final auth = createAuth((req) async {
        expect(req.url.path, '/api/auth/google');
        sentBody = jsonDecode(req.body);
        return jsonResponse(authResponse(gamerJson(), isNewUser: true));
      }, google: FakeGoogleAuth('google-id-token'));

      expect(await auth.loginWithGoogle(), isTrue);
      expect(sentBody['idToken'], 'google-id-token');
      expect(auth.isNewUser, isTrue);
    });

    test('Google: bấm hủy thì không gọi backend', () async {
      final auth = createAuth((_) async => fail('không được gọi API'), google: FakeGoogleAuth(null));
      expect(await auth.loginWithGoogle(), isFalse);
      expect(auth.isLoggedIn, isFalse);
    });

    test('mở app: còn token thì tự đăng nhập lại qua /auth/me', () async {
      final auth = createAuth((req) async {
        expect(req.url.path, '/api/auth/me');
        expect(req.headers['Authorization'], 'Bearer old-token');
        return jsonResponse(gamerJson());
      }, storage: MemoryTokenStorage('old-token'));

      await auth.restoreSession();
      expect(auth.isRestoring, isFalse);
      expect(auth.isLoggedIn, isTrue);
    });

    test('mở app: token hết hạn thì xóa token, về màn đăng nhập', () async {
      final storage = MemoryTokenStorage('expired');
      final auth = createAuth((_) async => jsonResponse({}, 401), storage: storage);

      await auth.restoreSession();
      expect(auth.isLoggedIn, isFalse);
      expect(storage.token, isNull);
    });

    test('đăng xuất xóa token', () async {
      final storage = MemoryTokenStorage();
      final auth = createAuth((_) async => jsonResponse(authResponse(gamerJson())), storage: storage);
      await auth.login('gamer@blush.vn', '123456');

      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(storage.token, isNull);
      expect(auth.api.accessToken, isNull);
    });
  });

  group('QuestService', () {
    test('điểm danh: cập nhật user theo dữ liệu backend trả về', () async {
      final today = DateTime.now().toUtc().add(const Duration(hours: 7)).toIso8601String().substring(0, 10);
      final auth = createAuth((req) async {
        if (req.url.path.endsWith('auth/login')) return jsonResponse(authResponse(gamerJson()));
        expect(req.headers['Authorization'], 'Bearer fake-jwt-token');
        return jsonResponse({
          'message': 'Điểm danh hàng ngày thành công!',
          'user': gamerJson(exp: 1200, coins: 355, lastCheckInDate: today),
        });
      });
      await auth.login('gamer@blush.vn', '123456');
      expect(auth.currentUser!.checkedInToday, isFalse);

      final message = await QuestService().checkIn(auth);

      expect(message, 'Điểm danh hàng ngày thành công!');
      expect(auth.currentUser!.coins, 355);
      expect(auth.currentUser!.level, 13);
      expect(auth.currentUser!.checkedInToday, isTrue);
    });

    test('chỉ nhận quà nhiệm vụ đã hoàn thành', () async {
      final auth = await loggedInGamer();
      final quests = QuestService();
      final notDone = quests.dailyQuests.firstWhere((q) => !q.isDone);
      final doneNotClaimed = quests.dailyQuests.firstWhere((q) => q.isDone && !q.isClaimed);

      quests.claim(notDone, auth);
      expect(auth.currentUser!.coins, 340);

      quests.claim(doneNotClaimed, auth);
      expect(doneNotClaimed.isClaimed, isTrue);
      expect(auth.currentUser!.coins, 340 + doneNotClaimed.rewardCoins);
    });
  });

  testWidgets('chưa đăng nhập thì mở trang Landing', (tester) async {
    final auth = createAuth((_) async => fail('không có token thì không gọi API'));
    await auth.restoreSession();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => QuestService()),
        ],
        child: const BlushApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
