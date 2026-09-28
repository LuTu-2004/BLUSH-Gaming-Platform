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

  /// Ném ApiException:
  /// - `e.isEmailNotVerified` -> chuyển sang màn xác minh email
  /// - `e.isTwoFactorRequired` -> chuyển sang màn nhập mã 2 bước, rồi gọi [loginWithTwoFactor]
  Future<void> login(String email, String password) async {
    final data = await api.post('auth/login', {
      'email': email.trim(),
      'password': password,
      // Máy đã được tin cậy từ lần trước -> backend bỏ qua bước nhập mã
      'deviceToken': await _storage.readDeviceToken(),
    });
    await _handleAuthResponse(data);
  }

  /// Bước 2 của đăng nhập 2 bước. [rememberDevice] = "Tin cậy thiết bị này 30 ngày".
  Future<void> loginWithTwoFactor(String email, String code, {required bool rememberDevice}) async {
    final data = await api.post('auth/login-2fa', {
      'email': email.trim(),
      'code': code.trim(),
      'rememberDevice': rememberDevice,
      'deviceName': 'BLUSH app',
    });
    final deviceToken = data['deviceToken'] as String?;
    if (deviceToken != null) await _storage.saveDeviceToken(deviceToken);
    await _handleAuthResponse(data);
  }

  /// Bật 2 bước - bước 1: kiểm tra mật khẩu, backend gửi mã xác nhận về email.
  Future<void> startEnableTwoFactor(String password) async {
    await api.post('auth/two-factor/enable', {'password': password});
  }

  /// Bật 2 bước - bước 2: nhập mã nhận được -> bật.
  Future<void> confirmEnableTwoFactor(String code) async {
    final data = await api.post('auth/two-factor/confirm', {'code': code.trim()});
    updateUserFromJson(data as Map<String, dynamic>);
  }

  /// Tắt 2 bước (nhập lại mật khẩu).
  Future<void> disableTwoFactor(String password) async {
    final data = await api.post('auth/two-factor/disable', {'password': password});
    // Backend đã hủy các thiết bị tin cậy -> xóa luôn token trên máy
    await _storage.clearDeviceToken();
    updateUserFromJson(data as Map<String, dynamic>);
  }

  /// Tạo tài khoản và gửi mã OTP về email. CHƯA đăng nhập: phải gọi [verifyEmail] với mã nhận được.
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
    required DateTime dateOfBirth,
  }) async {
    await api.post('auth/register', {
      'displayName': displayName.trim(),
      'email': email.trim(),
      'password': password,
      'dateOfBirth': formatDate(dateOfBirth),
    });
  }

  /// Nhập đúng mã OTP -> xác minh email và đăng nhập luôn.
  Future<void> verifyEmail(String email, String code) async {
    final data = await api.post('auth/verify-email', {'email': email.trim(), 'code': code.trim()});
    await _handleAuthResponse(data);
  }

  /// [purpose]: 'VerifyEmail' hoặc 'ResetPassword'
  Future<void> resendOtp(String email, String purpose) async {
    await api.post('auth/resend-otp', {'email': email.trim(), 'purpose': purpose});
  }

  Future<String> forgotPassword(String email) async {
    final data = await api.post('auth/forgot-password', {'email': email.trim()});
    return data['message'] as String;
  }

  Future<String> resetPassword({required String email, required String code, required String newPassword}) async {
    final data = await api.post('auth/reset-password', {
      'email': email.trim(),
      'code': code.trim(),
      'newPassword': newPassword,
    });
    return data['message'] as String;
  }

  /// Ngày dạng "2006-01-10" như backend yêu cầu
  static String formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
