import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu token trên máy, đã mã hóa (Android Keystore / iOS Keychain qua flutter_secure_storage).
/// - access token: để lần sau mở app không phải đăng nhập lại (xóa khi đăng xuất)
/// - device token: "tin cậy thiết bị 30 ngày" cho xác thực 2 bước (GIỮ LẠI khi đăng xuất)
/// Bản cũ lưu ở SharedPreferences (không mã hóa): lần đọc đầu tiên tự chuyển sang kho mã hóa rồi xóa bản cũ.
class TokenStorage {
  static const _key = 'access_token';
  static const _deviceKey = 'trusted_device_token';

  final FlutterSecureStorage _secure;

  TokenStorage({FlutterSecureStorage? secure}) : _secure = secure ?? const FlutterSecureStorage();

  Future<String?> read() => _read(_key);

  Future<void> save(String token) => _secure.write(key: _key, value: token);

  Future<void> clear() => _secure.delete(key: _key);

  Future<String?> readDeviceToken() => _read(_deviceKey);

  Future<void> saveDeviceToken(String token) => _secure.write(key: _deviceKey, value: token);

  Future<void> clearDeviceToken() => _secure.delete(key: _deviceKey);

  Future<String?> _read(String key) async {
    final value = await _secure.read(key: key);
    if (value != null) return value;

    // Chuyển token của bản app cũ sang kho mã hóa (chỉ xảy ra 1 lần)
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(key);
    if (legacy == null) return null;
    await _secure.write(key: key, value: legacy);
    await prefs.remove(key);
    return legacy;
  }
}
