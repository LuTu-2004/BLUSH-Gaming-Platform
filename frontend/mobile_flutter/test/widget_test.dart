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

      await expectLater(
        auth.register(displayName: 'A', email: 'a@b.vn', password: '1', dateOfBirth: DateTime(2004, 1, 1)),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Mật khẩu quá ngắn')),
      );
    });

    test('đăng ký: gửi ngày sinh dạng yyyy-MM-dd, CHƯA đăng nhập (chờ nhập mã)', () async {
      late Map<String, dynamic> sentBody;
      final auth = createAuth((req) async {
        expect(req.url.path, '/api/auth/register');
        sentBody = jsonDecode(req.body);
        return jsonResponse({'message': 'Đã gửi mã', 'email': 'moi@gmail.com'});
      });

      await auth.register(displayName: 'Moi', email: 'moi@gmail.com', password: 'abc123', dateOfBirth: DateTime(2004, 3, 5));

      expect(sentBody['dateOfBirth'], '2004-03-05');
      expect(auth.isLoggedIn, isFalse);
    });

    test('đăng ký dưới 16 tuổi: hiện đúng lời nhắn của backend', () async {
      final auth = createAuth((_) async => jsonResponse({'message': 'BLUSH dành cho người từ 16 tuổi trở lên.'}, 400));

      await expectLater(
        auth.register(displayName: 'Nho', email: 'nho@gmail.com', password: 'abc123', dateOfBirth: DateTime(2015, 1, 1)),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('16 tuổi'))),
      );
    });

    test('nhập đúng mã OTP thì đăng nhập luôn', () async {
      final storage = MemoryTokenStorage();
      final auth = createAuth((req) async {
        expect(req.url.path, '/api/auth/verify-email');
        expect(jsonDecode(req.body)['code'], '123456');
        return jsonResponse(authResponse(gamerJson(), isNewUser: true));
      }, storage: storage);

      await auth.verifyEmail('gamer@blush.vn', '123456');
      expect(auth.isLoggedIn, isTrue);
      expect(auth.isNewUser, isTrue);
      expect(storage.token, 'fake-jwt-token');
    });

    test('đăng nhập khi chưa xác minh email: nhận được mã lỗi EMAIL_NOT_VERIFIED', () async {
      final auth = createAuth((_) async => jsonResponse({'message': 'Email chưa được xác minh.', 'code': 'EMAIL_NOT_VERIFIED'}, 403));

      await expectLater(auth.login('moi@gmail.com', 'abc123'), throwsA(isA<ApiException>().having((e) => e.isEmailNotVerified, 'isEmailNotVerified', isTrue)));
      expect(auth.isLoggedIn, isFalse);
    });

    test('2 bước: đăng nhập báo TWO_FACTOR_REQUIRED, nhập mã + tin cậy thiết bị thì lưu device token', () async {
      final storage = MemoryTokenStorage();
      final auth = createAuth((req) async {
        if (req.url.path.endsWith('auth/login')) {
          return jsonResponse({'message': 'Nhập mã 2 bước', 'code': 'TWO_FACTOR_REQUIRED'}, 403);
        }
        expect(req.url.path, '/api/auth/login-2fa');
        final body = jsonDecode(req.body);
        expect(body['rememberDevice'], isTrue);
        return jsonResponse({...authResponse(gamerJson()), 'deviceToken': 'thiet-bi-tin-cay'});
      }, storage: storage);

      await expectLater(auth.login('gamer@blush.vn', '123456'), throwsA(isA<ApiException>().having((e) => e.isTwoFactorRequired, 'isTwoFactorRequired', isTrue)));
      expect(auth.isLoggedIn, isFalse);

      await auth.loginWithTwoFactor('gamer@blush.vn', '112233', rememberDevice: true);
      expect(auth.isLoggedIn, isTrue);
      expect(storage.deviceToken, 'thiet-bi-tin-cay');
    });

    test('2 bước: đăng nhập gửi kèm device token đã lưu, đăng xuất vẫn giữ token thiết bị', () async {
      final storage = MemoryTokenStorage(null, 'thiet-bi-tin-cay');
      late Map<String, dynamic> sentBody;
      final auth = createAuth((req) async {
        sentBody = jsonDecode(req.body);
        return jsonResponse(authResponse(gamerJson()));
      }, storage: storage);

      await auth.login('gamer@blush.vn', '123456');
      expect(sentBody['deviceToken'], 'thiet-bi-tin-cay');

      await auth.logout();
      expect(storage.deviceToken, 'thiet-bi-tin-cay');
    });

    test('tắt 2 bước thì xóa token thiết bị trên máy', () async {
      final storage = MemoryTokenStorage(null, 'thiet-bi-tin-cay');
      final auth = createAuth((req) async {
        if (req.url.path.endsWith('auth/login')) return jsonResponse(authResponse(gamerJson()));
        expect(req.url.path, '/api/auth/two-factor');
        return jsonResponse({...gamerJson(), 'twoFactorEnabled': false});
      }, storage: storage);
      await auth.login('gamer@blush.vn', '123456');

      await auth.setTwoFactor(enabled: false, password: '123456');
      expect(storage.deviceToken, isNull);
      expect(auth.currentUser!.twoFactorEnabled, isFalse);
    });

    test('quên mật khẩu -> đặt lại mật khẩu', () async {
      final calls = <String>[];
      final auth = createAuth((req) async {
        calls.add(req.url.path);
        return jsonResponse({'message': req.url.path.endsWith('forgot-password') ? 'Đã gửi mã' : 'Đặt lại thành công'});
      });

      expect(await auth.forgotPassword('gamer@blush.vn'), 'Đã gửi mã');
      expect(await auth.resetPassword(email: 'gamer@blush.vn', code: '654321', newPassword: 'moi123'), 'Đặt lại thành công');
      expect(calls, ['/api/auth/forgot-password', '/api/auth/reset-password']);
      expect(auth.isLoggedIn, isFalse); // đặt lại xong phải tự đăng nhập bằng mật khẩu mới
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
