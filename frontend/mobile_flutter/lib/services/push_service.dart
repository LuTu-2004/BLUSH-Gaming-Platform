import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../config/firebase_config.dart';

/// Thông báo đẩy qua Firebase Cloud Messaging (backend/Controllers/DevicesController.cs).
/// Hiện chỉ bật trên Android (iOS cần tài khoản Apple Developer + APNs).
/// App đang mở thì Android không hiện thông báo hệ thống: số trên 🔔 / 💬 đã cập nhật qua SignalR.
class PushMessaging {
  /// null = không phải Android / khởi tạo Firebase lỗi / đang chạy test -> app chạy như chưa có push
  static PushMessaging? instance;

  final FirebaseMessaging _fcm;
  String? _token;
  StreamSubscription<String>? _refreshSub;

  PushMessaging._(this._fcm);

  /// Gọi 1 lần trong main() trước runApp
  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Firebase.initializeApp(options: FirebaseConfig.android);
      instance = PushMessaging._(FirebaseMessaging.instance);
    } catch (e) {
      debugPrint('Không khởi tạo được Firebase, tắt thông báo đẩy: $e');
    }
  }

  /// Sau khi đăng nhập: xin quyền (Android 13+ hiện hộp thoại) rồi gửi mã của máy này lên backend.
  /// Lỗi thì bỏ qua: thiếu thông báo đẩy không được chặn việc dùng app.
  Future<void> register(ApiClient api) async {
    try {
      final settings = await _fcm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      _token = await _fcm.getToken();
      if (_token != null) await _send(api, _token!);
      // Firebase thỉnh thoảng cấp mã mới (cài lại app, xóa dữ liệu...) -> báo backend
      _refreshSub ??= _fcm.onTokenRefresh.listen((token) {
        _token = token;
        _send(api, token).catchError((_) {});
      });
    } catch (e) {
      debugPrint('Đăng ký thông báo đẩy thất bại: $e');
    }
  }

  /// Gọi lúc đăng xuất, TRƯỚC khi xóa token đăng nhập (backend cần biết máy này của ai để gỡ)
  Future<void> unregister(ApiClient api) async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await api.post('devices/unregister', {'token': token}).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Mất mạng thì thôi: backend tự xóa mã khi đăng nhập tài khoản khác trên máy này
    }
  }

  /// Nơi cần mở khi người dùng bấm thông báo lúc app đang chạy nền ('chat:<userId>', 'zone:2', 'vip'...)
  Stream<String> get openedLinks => FirebaseMessaging.onMessageOpenedApp
      .map((m) => m.data['link'])
      .where((link) => link is String && link.isNotEmpty)
      .cast<String>();

  /// App đang tắt hẳn, mở lên do bấm thông báo -> nơi cần mở (chỉ trả về 1 lần)
  Future<String?> takeInitialLink() async {
    final link = (await _fcm.getInitialMessage())?.data['link'];
    return link is String && link.isNotEmpty ? link : null;
  }

  Future<void> _send(ApiClient api, String token) => api.post('devices', {'token': token, 'platform': 'android'});
}
