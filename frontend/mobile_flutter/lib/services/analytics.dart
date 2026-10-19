import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Google Analytics (GA4) qua Firebase: xem trên Firebase console → Analytics, hoặc analytics.google.com.
/// Chỉ chạy trên Android, sau khi PushMessaging.init đã khởi tạo Firebase. Web / test / lỗi khởi tạo
/// thì mọi hàm bỏ qua, không bao giờ làm hỏng luồng chính của app.
///
/// Sự kiện ghi lại (tên theo chuẩn GA4 khi có):
///   login / sign_up (method: email | google), survey_saved, start_chat, answer_icebreaker,
///   begin_checkout, purchase, rate_app (stars), select_acquisition_source (source),
///   screen_view khi đổi tab ở khung chính
class Analytics {
  static FirebaseAnalytics? _ga;

  /// Gọi 1 lần trong main(), SAU PushMessaging.init (cần Firebase đã khởi tạo)
  static void init() {
    if (kIsWeb || Firebase.apps.isEmpty) return;
    _ga = FirebaseAnalytics.instance;
  }

  static Future<void> _run(Future<void> Function(FirebaseAnalytics ga) action) async {
    final ga = _ga;
    if (ga == null) return;
    try {
      await action(ga);
    } catch (e) {
      debugPrint('Analytics lỗi (bỏ qua): $e');
    }
  }

  /// Sau đăng nhập / đăng ký: gắn mã người dùng (id nội bộ, không phải email) + vai trò, VIP
  static Future<void> loggedIn(UserModel user, {required bool isNewUser, required String method}) => _run((ga) async {
        await ga.setUserId(id: user.id);
        await ga.setUserProperty(name: 'role', value: user.role);
        await ga.setUserProperty(name: 'is_vip', value: user.isVip ? 'yes' : 'no');
        isNewUser ? await ga.logSignUp(signUpMethod: method) : await ga.logLogin(loginMethod: method);
      });

  static Future<void> loggedOut() => _run((ga) => ga.setUserId(id: null));

  static Future<void> screen(String name) => _run((ga) => ga.logScreenView(screenName: name));

  static Future<void> surveySaved() => _run((ga) => ga.logEvent(name: 'survey_saved'));

  static Future<void> startChat() => _run((ga) => ga.logEvent(name: 'start_chat'));

  static Future<void> answerIceBreaker() => _run((ga) => ga.logEvent(name: 'answer_icebreaker'));

  static Future<void> beginCheckout({required String packageCode, required int amount, required String method}) => _run(
        (ga) => ga.logBeginCheckout(
          currency: 'VND',
          value: amount.toDouble(),
          items: [AnalyticsEventItem(itemId: packageCode, price: amount.toDouble())],
          parameters: {'payment_method': method},
        ),
      );

  static Future<void> purchase({required int orderCode, required String packageCode, required int amount}) => _run(
        (ga) => ga.logPurchase(
          currency: 'VND',
          value: amount.toDouble(),
          transactionId: '$orderCode',
          items: [AnalyticsEventItem(itemId: packageCode, price: amount.toDouble())],
        ),
      );

  static Future<void> rateApp(int stars) => _run((ga) => ga.logEvent(name: 'rate_app', parameters: {'stars': stars}));

  /// Cũng lưu thành thuộc tính người dùng: lọc báo cáo GA theo kênh người đó biết BLUSH
  static Future<void> acquisitionSource(String source) => _run((ga) async {
        await ga.setUserProperty(name: 'acquisition_source', value: source);
        await ga.logEvent(name: 'select_acquisition_source', parameters: {'source': source});
      });
}
