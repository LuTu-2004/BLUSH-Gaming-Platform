import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blush_mobile_app/services/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lưu / đọc / xóa token trong kho mã hóa, không ghi ra SharedPreferences', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final storage = TokenStorage();

    await storage.save('jwt-moi');
    await storage.saveDeviceToken('device-1');
    expect(await storage.read(), 'jwt-moi');
    expect(await storage.readDeviceToken(), 'device-1');
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);

    await storage.clear();
    expect(await storage.read(), isNull);
    expect(await storage.readDeviceToken(), 'device-1'); // đăng xuất vẫn giữ "tin cậy thiết bị"
  });

  test('token của bản app cũ (SharedPreferences) được chuyển sang kho mã hóa rồi xóa bản cũ', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'access_token': 'jwt-cu', 'trusted_device_token': 'device-cu'});
    final storage = TokenStorage();

    expect(await storage.read(), 'jwt-cu'); // không bắt đăng nhập lại sau khi cập nhật app
    expect(await storage.readDeviceToken(), 'device-cu');
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    expect(await const FlutterSecureStorage().read(key: 'access_token'), 'jwt-cu');
  });
}
