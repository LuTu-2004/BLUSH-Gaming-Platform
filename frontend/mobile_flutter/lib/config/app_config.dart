import 'package:flutter/foundation.dart';

// Cấu hình truyền lúc chạy bằng --dart-define, ví dụ:
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5000/api --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Địa chỉ backend .NET.
  /// Mặc định: máy ảo Android dùng 10.0.2.2 (= localhost của máy tính), các nền tảng khác dùng localhost.
  /// Điện thoại thật: truyền IP Wi-Fi của máy chạy backend qua API_BASE_URL.
  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000/api';
    return 'http://localhost:5000/api';
  }

  /// Tuổi tối thiểu dùng app. PHẢI trùng AgePolicy.MinimumAge ở backend
  /// (backend mới là nơi chặn thật, ở đây chỉ để báo lỗi sớm cho người dùng).
  static const int minimumAge = 16;

  /// "Web client ID" trên Google Cloud Console - PHẢI trùng GoogleAuth:WebClientId ở backend.
  /// Client ID không phải bí mật (nằm sẵn trong mọi bản app) nên để mặc định ở đây cho cả nhóm dùng.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '584719392292-c1auq69bq0decbokngeo1f8429da5v21.apps.googleusercontent.com',
  );
}
