import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:blush_mobile_app/api/api_client.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/google_auth.dart';
import 'package:blush_mobile_app/services/token_storage.dart';

// Dữ liệu giống backend trả về cho tài khoản gamer@blush.vn
Map<String, dynamic> gamerJson({int exp = 1150, int coins = 340, String? lastCheckInDate}) => {
      'id': '33333333-3333-3333-3333-333333333333',
      'email': 'gamer@blush.vn',
      'role': 'User',
      'displayName': 'Lưu Phước Nhật Tú',
      'dateOfBirth': '2006-01-10',
      'mbti': 'INFJ',
      'bio': 'Mê game tấu hài & ca hát voice chat',
      'avatarEmoji': '🎮',
      'currentLevel': exp ~/ 100 + 1,
      'exp': exp,
      'coins': coins,
      'isVip': false,
      'lastCheckInDate': lastCheckInDate,
    };

Map<String, dynamic> authResponse(Map<String, dynamic> user, {bool isNewUser = false}) => {
      'accessToken': 'fake-jwt-token',
      'expiresAt': '2030-01-01T00:00:00Z',
      'isNewUser': isNewUser,
      'user': user,
    };

http.Response jsonResponse(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Lưu token trong bộ nhớ thay vì SharedPreferences
class MemoryTokenStorage extends TokenStorage {
  String? token;
  String? deviceToken;
  MemoryTokenStorage([this.token, this.deviceToken]);

  @override
  Future<String?> read() async => token;
  @override
  Future<void> save(String token) async => this.token = token;
  @override
  Future<void> clear() async => token = null;
  @override
  Future<String?> readDeviceToken() async => deviceToken;
  @override
  Future<void> saveDeviceToken(String token) async => deviceToken = token;
  @override
  Future<void> clearDeviceToken() async => deviceToken = null;
}

/// Giả lập hộp thoại Google: trả về [idToken] (null = người dùng bấm hủy)
class FakeGoogleAuth extends GoogleAuth {
  final String? idToken;
  FakeGoogleAuth(this.idToken);

  @override
  Future<String?> getIdToken() async => idToken;
  @override
  Future<void> signOut() async {}
}

AuthService createAuth(MockClientHandler handler, {TokenStorage? storage, GoogleAuth? google}) => AuthService(
      api: ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api'),
      storage: storage ?? MemoryTokenStorage(),
      google: google ?? FakeGoogleAuth(null),
    );

/// AuthService đã đăng nhập sẵn tài khoản gamer (dùng cho test giao diện)
Future<AuthService> loggedInGamer() async {
  final auth = createAuth((_) async => jsonResponse(authResponse(gamerJson())));
  await auth.login('gamer@blush.vn', '123456');
  return auth;
}
