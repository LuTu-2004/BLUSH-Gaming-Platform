import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

/// Lỗi đăng nhập Google, [message] hiện thẳng cho người dùng
class GoogleAuthException implements Exception {
  final String message;
  GoogleAuthException(this.message);

  @override
  String toString() => message;
}

/// Mở hộp thoại chọn tài khoản Google và lấy ID Token để gửi cho backend kiểm tra.
/// Tách riêng class này để khi viết test có thể thay bằng bản giả.
class GoogleAuth {
  bool _initialized = false;

  /// Trả về ID Token, hoặc null nếu người dùng bấm hủy.
  Future<String?> getIdToken() async {
    if (AppConfig.googleWebClientId.isEmpty) {
      throw GoogleAuthException('Đăng nhập Google chưa được cấu hình (thiếu GOOGLE_WEB_CLIENT_ID, xem README).');
    }

    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      // serverClientId = Web client ID -> ID Token được cấp cho backend của mình
      await signIn.initialize(serverClientId: AppConfig.googleWebClientId);
      _initialized = true;
    }
    if (!signIn.supportsAuthenticate()) {
      throw GoogleAuthException('Thiết bị này chưa hỗ trợ đăng nhập Google (dùng Android hoặc iOS).');
    }

    try {
      final account = await signIn.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw GoogleAuthException('Đăng nhập Google thất bại: ${e.description ?? e.code.name}');
    }
  }

  Future<void> signOut() async {
    if (_initialized) await GoogleSignIn.instance.signOut();
  }
}
