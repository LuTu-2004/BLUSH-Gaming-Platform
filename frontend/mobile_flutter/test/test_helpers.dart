import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:blush_mobile_app/api/api_client.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/google_auth.dart';
import 'package:blush_mobile_app/services/token_storage.dart';

// Dữ liệu giống backend trả về cho tài khoản gamer@blush.vn
Map<String, dynamic> gamerJson({int exp = 1150, int coins = 340, String? lastCheckInDate, bool onboardingCompleted = true}) => {
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
      'onboardingCompleted': onboardingCompleted,
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

// Giống GET api/onboarding/options
final Map<String, dynamic> onboardingOptionsJson = {
  'games': [
    {'id': 1, 'name': 'Liên Quân Mobile', 'genre': 'MOBA 5v5', 'positions': ['Đường Caesar', 'Đi rừng', 'Đường giữa', 'Xạ thủ', 'Trợ thủ']},
    {'id': 2, 'name': 'Valorant', 'genre': 'FPS Tactical', 'positions': ['Duelist', 'Initiator', 'Controller', 'Sentinel']},
    {'id': 4, 'name': 'Đấu Trường Chân Lý', 'genre': 'Auto Battler', 'positions': []},
  ],
  'purposes': [
    {'code': 'Tryhard', 'label': 'Leo rank nghiêm túc'},
    {'code': 'Fun', 'label': 'Chơi vui, giải trí'},
    {'code': 'Event', 'label': 'Săn sự kiện'},
  ],
  'playTimes': [
    {'code': 'Morning', 'label': 'Sáng (6h - 12h)'},
    {'code': 'Afternoon', 'label': 'Chiều (12h - 18h)'},
    {'code': 'Evening', 'label': 'Tối (18h - 23h)'},
    {'code': 'LateNight', 'label': 'Khuya (23h - 2h)'},
    {'code': 'Weekend', 'label': 'Cuối tuần'},
  ],
  'regions': [
    {'code': 'HCM', 'label': 'TP. Hồ Chí Minh'},
    {'code': 'HN', 'label': 'Hà Nội'},
  ],
  'hobbies': [
    {'id': 1, 'name': 'Voice Chat'},
    {'id': 2, 'name': 'K-Pop'},
    {'id': 3, 'name': 'Anime'},
  ],
};

// Giống GET api/onboarding của tài khoản gamer
final Map<String, dynamic> onboardingAnswersJson = {
  'games': [
    {'gameId': 1, 'position': 'Đường giữa', 'purpose': 'Fun'},
    {'gameId': 2, 'position': null, 'purpose': 'Tryhard'},
  ],
  'playTimes': ['Evening'],
  'region': 'HCM',
  'usesMic': true,
  'hobbyIds': [1],
  'mbti': 'INFJ',
  'teammateWish': null,
};

// Giống GET api/match/suggestions (tên rất dài để bắt lỗi tràn chữ)
final List<Map<String, dynamic>> matchSuggestionsJson = [
  {
    'userId': 'a0000000-0000-0000-0000-000000000003',
    'displayName': 'Nguyễn Hoàng Minh Thùy Trang Rất Dài',
    'avatarEmoji': '⚔️',
    'age': 20,
    'mbti': 'INTP',
    'bio': 'Cày sảnh giải trí sau giờ học, thích voice chat ca hát, tối nào cũng online đến khuya.',
    'region': 'HCM',
    'usesMic': true,
    'isVip': false,
    'gameId': 1,
    'gameName': 'Liên Quân Mobile',
    'position': 'Đường giữa',
    'purpose': 'Fun',
    'hobbies': ['Anime', 'Âm nhạc', 'Voice Chat'],
    'score': 95,
    'reason': 'Cùng chơi Liên Quân Mobile · cùng mục tiêu chơi vui, giải trí · cùng hay chơi buổi tối, khuya · cùng ở TP. Hồ Chí Minh',
  },
  {
    'userId': 'a0000000-0000-0000-0000-000000000008',
    'displayName': 'Đăng Khoa',
    'avatarEmoji': '🛡️',
    'age': null,
    'mbti': null,
    'bio': null,
    'region': 'HN',
    'usesMic': null,
    'isVip': true,
    'gameId': 2,
    'gameName': 'Valorant',
    'position': null,
    'purpose': 'Tryhard',
    'hobbies': [],
    'score': 60,
    'reason': 'Cùng chơi Valorant',
  },
];

/// Giả lập backend: trả dữ liệu theo đường dẫn API
MockClientHandler fakeBackend({Map<String, dynamic>? user}) => (req) async {
      final path = req.url.path.replaceFirst('/api/', '');
      return switch (path) {
        'onboarding/options' => jsonResponse(onboardingOptionsJson),
        'onboarding' when req.method == 'GET' => jsonResponse(onboardingAnswersJson),
        'onboarding' => jsonResponse(gamerJson()), // lưu xong -> onboardingCompleted = true
        'match/suggestions' => jsonResponse(matchSuggestionsJson),
        _ => jsonResponse(authResponse(user ?? gamerJson())),
      };
    };

/// AuthService đã đăng nhập sẵn tài khoản gamer (dùng cho test giao diện)
Future<AuthService> loggedInGamer({bool onboardingCompleted = true}) async {
  final auth = createAuth(fakeBackend(user: gamerJson(onboardingCompleted: onboardingCompleted)));
  await auth.login('gamer@blush.vn', '123456');
  return auth;
}

// Font mặc định trong test vẽ mỗi chữ thành ô vuông (rộng hơn chữ thật),
// nên nạp font Roboto có sẵn trong Flutter SDK để đo kích thước giống điện thoại thật.
Future<void> loadRobotoFromSdk() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final dir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final name in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf', 'roboto-italic.ttf']) {
    final file = File('$dir/$name');
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
  }
  await loader.load();
}
