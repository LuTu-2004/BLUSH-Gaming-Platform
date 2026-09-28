import 'package:shared_preferences/shared_preferences.dart';

/// Lưu JWT token để lần sau mở app không phải đăng nhập lại.
/// TODO: khi phát hành thật nên đổi sang flutter_secure_storage (mã hóa token trên máy).
class TokenStorage {
  static const _key = 'access_token';

  Future<String?> read() async => (await SharedPreferences.getInstance()).getString(_key);

  Future<void> save(String token) async => (await SharedPreferences.getInstance()).setString(_key, token);

  Future<void> clear() async => (await SharedPreferences.getInstance()).remove(_key);
}
