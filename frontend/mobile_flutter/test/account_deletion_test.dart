import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/main.dart';
import 'package:blush_mobile_app/screens/landing_screen.dart';
import 'package:blush_mobile_app/screens/profile_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

/// Backend giả có thêm POST api/account/delete
AuthService _auth(List<http.Request> requests, {Map<String, dynamic>? user, String? googleToken, MemoryTokenStorage? storage}) {
  final backend = fakeBackend(user: user);
  return createAuth(
    (req) async {
      requests.add(req);
      if (req.url.path == '/api/account/delete') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        if (body['password'] == 'sai') return jsonResponse({'message': 'Mật khẩu không đúng.'}, 400);
        return jsonResponse({'message': 'Tài khoản và dữ liệu cá nhân của bạn đã được xóa.'});
      }
      return backend(req);
    },
    google: FakeGoogleAuth(googleToken),
    storage: storage,
  );
}

Widget _app(AuthService auth) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: const BlushApp(),
    );

void main() {
  setUpAll(loadRobotoFromSdk);

  test('tài khoản có mật khẩu: gửi mật khẩu, xóa xong thì đăng xuất và xóa token trên máy', () async {
    final requests = <http.Request>[];
    final storage = MemoryTokenStorage();
    final auth = _auth(requests, storage: storage);
    await auth.login('gamer@blush.vn', '123456');

    expect(await auth.deleteAccount(password: '123456'), isTrue);
    expect(jsonDecode(requests.last.body), {'password': '123456'});
    expect(auth.isLoggedIn, isFalse);
    expect(storage.token, isNull);
  });

  test('tài khoản chỉ dùng Google: xác nhận bằng hộp thoại Google, bấm hủy thì không xóa', () async {
    final requests = <http.Request>[];
    final googleUser = {...gamerJson(), 'hasPassword': false};

    final cancelled = _auth(requests, user: googleUser);
    await cancelled.login('gamer@blush.vn', '123456');
    expect(await cancelled.deleteAccount(), isFalse);
    expect(requests.where((r) => r.url.path == '/api/account/delete'), isEmpty);
    expect(cancelled.isLoggedIn, isTrue);

    final confirmed = _auth(requests, user: googleUser, googleToken: 'google-id-token');
    await confirmed.login('gamer@blush.vn', '123456');
    expect(await confirmed.deleteAccount(), isTrue);
    expect(jsonDecode(requests.last.body), {'googleIdToken': 'google-id-token'});
    expect(confirmed.isLoggedIn, isFalse);
  });

  testWidgets('Hồ sơ: xóa tài khoản phải xác nhận + nhập mật khẩu, xong về màn Landing', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final requests = <http.Request>[];
    final auth = _auth(requests);
    await auth.login('gamer@blush.vn', '123456');
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ').last);
    await tester.pumpAndSettle();

    final deleteButton = find.text('Xóa tài khoản');
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text('Xóa tài khoản vĩnh viễn?'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(requests.last.url.path, '/api/account/delete');
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.text('Tài khoản của bạn đã được xóa.'), findsOneWidget);
  });

  testWidgets('Hồ sơ: sai mật khẩu thì báo lỗi, vẫn đăng nhập', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = _auth([]);
    await auth.login('gamer@blush.vn', '123456');
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xóa tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'sai');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu không đúng.'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);
  });

  testWidgets('Staff/Admin không thấy nút xóa tài khoản', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = _auth([], user: {...gamerJson(), 'role': 'Staff'});
    await auth.login('staff@blush.vn', '123456');
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ').last);
    await tester.pumpAndSettle();

    expect(find.text('Xóa tài khoản', skipOffstage: false), findsNothing);
  });
}
