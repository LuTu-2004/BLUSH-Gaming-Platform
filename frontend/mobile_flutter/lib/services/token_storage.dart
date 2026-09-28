import 'package:shared_preferences/shared_preferences.dart';

/// Lưu token trên máy.
/// - access token: để lần sau mở app không phải đăng nhập lại (xóa khi đăng xuất)
/// - device token: "tin cậy thiết bị 30 ngày" cho xác thực 2 bước (GIỮ LẠI khi đăng xuất)
/// TODO: khi phát hành thật nên đổi sang flutter_secure_storage (mã hóa token trên máy).
class TokenStorage {
  static const _key = 'access_token';
  static const _deviceKey = 'trusted_device_token';

  Future<String?> read() async => (await SharedPreferences.getInstance()).getString(_key);

  Future<void> save(String token) async => (await SharedPreferences.getInstance()).setString(_key, token);

  Future<void> clear() async => (await SharedPreferences.getInstance()).remove(_key);

  Future<String?> readDeviceToken() async => (await SharedPreferences.getInstance()).getString(_deviceKey);

  Future<void> saveDeviceToken(String token) async => (await SharedPreferences.getInstance()).setString(_deviceKey, token);

  Future<void> clearDeviceToken() async => (await SharedPreferences.getInstance()).remove(_deviceKey);
}
