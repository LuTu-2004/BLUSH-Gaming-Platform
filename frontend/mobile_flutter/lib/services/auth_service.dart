import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';
import 'google_auth.dart';
import 'token_storage.dart';

/// Quản lý đăng nhập: gọi API backend, lưu token, giữ thông tin người dùng hiện tại.
/// Màn hình nào cần user thì `context.watch<AuthService>().currentUser`.
class AuthService extends ChangeNotifier {
  final ApiClient api;
  final TokenStorage _storage;
  final GoogleAuth _google;

  AuthService({required this.api, TokenStorage? storage, GoogleAuth? google})
      : _storage = storage ?? TokenStorage(),
        _google = google ?? GoogleAuth();

  UserModel? _currentUser;
  bool _isRestoring = true;
  bool _isNewUser = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// true trong lúc mở app đang kiểm tra token cũ -> hiện màn chờ
  bool get isRestoring => _isRestoring;

  /// true nếu vừa đăng ký / lần đầu đăng nhập Google (bước 3 sẽ chuyển sang màn Khảo sát)
  bool get isNewUser => _isNewUser;

  /// Gọi 1 lần khi mở app: nếu còn token cũ thì đăng nhập lại luôn.
  Future<void> restoreSession() async {
    try {
      final token = await _storage.read();
      if (token == null) return;
      api.accessToken = token;
      _currentUser = UserModel.fromJson(await api.get('auth/me'));
    } on ApiException {
      // Token hết hạn hoặc mất mạng -> bắt đăng nhập lại
      api.accessToken = null;
      await _storage.clear();
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final data = await api.post('auth/login', {'email': email.trim(), 'password': password});
    await _handleAuthResponse(data);
  }

  Future<void> register({required String displayName, required String email, required String password}) async {
    final data = await api.post('auth/register', {
      'displayName': displayName.trim(),
      'email': email.trim(),
      'password': password,
    });
    await _handleAuthResponse(data);
  }

  /// Trả về false nếu người dùng bấm hủy hộp thoại Google.
  Future<bool> loginWithGoogle() async {
    final idToken = await _google.getIdToken();
    if (idToken == null) return false;
    final data = await api.post('auth/google', {'idToken': idToken});
    await _handleAuthResponse(data);
    return true;
  }

  Future<void> logout() async {
    api.accessToken = null;
    _currentUser = null;
    _isNewUser = false;
    await _storage.clear();
    await _google.signOut();
    notifyListeners();
  }

  /// Cập nhật user từ dữ liệu backend trả về (VD: sau khi điểm danh)
  void updateUserFromJson(Map<String, dynamic> json) {
    _currentUser = UserModel.fromJson(json);
    notifyListeners();
  }

  Future<void> _handleAuthResponse(dynamic data) async {
    final token = data['accessToken'] as String;
    api.accessToken = token;
    await _storage.save(token);
    _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    _isNewUser = data['isNewUser'] as bool? ?? false;
    _isRestoring = false;
    notifyListeners();
  }

  // ── Các hàm dưới đây mới đổi dữ liệu trên máy, CHƯA lưu lên backend ─────────
  // TODO: thay bằng API khi backend có endpoint tương ứng.

  void addReward({int coins = 0, int exp = 0}) {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(coins: user.coins + coins, exp: user.exp + exp);
    notifyListeners();
  }

  void activateVip() {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(isVip: true);
    notifyListeners();
  }

  void updateProfile({required String bio, required String sundayAnswer, required String overthinkAnswer}) {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(bio: bio, sundayAnswer: sundayAnswer, overthinkAnswer: overthinkAnswer);
    notifyListeners();
  }
}
