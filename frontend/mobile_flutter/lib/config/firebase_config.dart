import 'package:firebase_core/firebase_core.dart';

/// Cấu hình Firebase (project `blush-510011`), chép từ android/app/google-services.json.
/// Đây là thông tin công khai của app (nằm sẵn trong file APK), KHÔNG phải key bí mật.
/// Đổi project Firebase thì tải lại google-services.json rồi sửa các giá trị dưới đây cho khớp.
class FirebaseConfig {
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCk3UvgaSB5wb2DnYXreVkNQzmT3xKfrqE',
    appId: '1:584719392292:android:70f3d5b49c8ed9b8c342b1',
    messagingSenderId: '584719392292',
    projectId: 'blush-510011',
    storageBucket: 'blush-510011.firebasestorage.app',
  );
}
