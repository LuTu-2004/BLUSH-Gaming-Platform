import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:blush_mobile_app/api/api_client.dart';
import 'package:blush_mobile_app/config/app_config.dart';

import 'test_helpers.dart';

void main() {
  test('ảnh backend trả về dạng /uploads/... được ghép với địa chỉ backend, ảnh Google giữ nguyên', () {
    final origin = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api$'), '');
    expect(AppConfig.resolveUrl('/uploads/avatars/a.jpg'), '$origin/uploads/avatars/a.jpg');
    expect(AppConfig.resolveUrl('https://lh3.googleusercontent.com/x'), 'https://lh3.googleusercontent.com/x');
  });

  test('đổi ảnh: gửi multipart trường "file" kèm token, cập nhật ảnh của người dùng', () async {
    final requests = <http.Request>[];
    final backend = fakeBackend();
    final auth = createAuth((req) async {
      requests.add(req);
      if (req.url.path == '/api/profile/avatar' && req.method == 'POST') {
        return jsonResponse({...gamerJson(), 'avatarUrl': '/uploads/avatars/new.jpg'});
      }
      return backend(req);
    });
    await auth.login('gamer@blush.vn', '123456');

    await auth.uploadAvatar([0xFF, 0xD8, 0xFF], 'anh.jpg');

    final upload = requests.last;
    expect(upload.method, 'POST');
    expect(upload.headers['Authorization'], 'Bearer fake-jwt-token');
    expect(upload.headers['content-type'], startsWith('multipart/form-data'));
    final body = String.fromCharCodes(upload.bodyBytes);
    expect(body, contains('name="file"; filename="anh.jpg"'));
    expect(auth.currentUser!.avatarUrl, '/uploads/avatars/new.jpg');
  });

  test('gỡ ảnh: gọi DELETE, người dùng không còn ảnh', () async {
    final backend = fakeBackend(user: {...gamerJson(), 'avatarUrl': '/uploads/avatars/old.jpg'});
    String? method;
    final auth = createAuth((req) async {
      if (req.url.path == '/api/profile/avatar') {
        method = req.method;
        return jsonResponse(gamerJson());
      }
      return backend(req);
    });
    await auth.login('gamer@blush.vn', '123456');

    await auth.removeAvatar();

    expect(method, 'DELETE');
    expect(auth.currentUser!.avatarUrl, isNull);
  });

  test('ảnh bị backend từ chối -> ném ApiException với câu báo lỗi của backend', () async {
    final backend = fakeBackend();
    final auth = createAuth((req) async {
      if (req.url.path == '/api/profile/avatar') {
        return jsonResponse({'message': 'File không phải ảnh hoặc ảnh bị lỗi (dùng JPG, PNG hoặc WebP).'}, 400);
      }
      return backend(req);
    });
    await auth.login('gamer@blush.vn', '123456');

    expect(
      () => auth.uploadAvatar([1, 2, 3], 'x.txt'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('không phải ảnh'))),
    );
  });
}
