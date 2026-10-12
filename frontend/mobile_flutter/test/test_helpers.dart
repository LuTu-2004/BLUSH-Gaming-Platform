import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:blush_mobile_app/api/api_client.dart';
import 'package:blush_mobile_app/models/chat_model.dart';
import 'package:blush_mobile_app/models/notification_model.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/chat_service.dart';
import 'package:blush_mobile_app/services/google_auth.dart';
import 'package:blush_mobile_app/services/token_storage.dart';

// Dữ liệu giống backend trả về cho tài khoản gamer@blush.vn
Map<String, dynamic> gamerJson({int exp = 1150, int coins = 340, String? lastCheckInDate, bool onboardingCompleted = true}) => {
      'id': '33333333-3333-3333-3333-333333333333',
      'email': 'gamer@blush.vn',
      'role': 'User',
      'displayName': 'Lưu Phước Nhật Tú',
      'dateOfBirth': '2006-01-10',
      'mbti': 'INFJ',
      'bio': 'Mê game tấu hài & ca hát voice chat',
      'avatarEmoji': '🎮',
      'currentLevel': exp ~/ 100 + 1,
      'exp': exp,
      'coins': coins,
      'isVip': false,
      'lastCheckInDate': lastCheckInDate,
      'onboardingCompleted': onboardingCompleted,
    };

Map<String, dynamic> authResponse(Map<String, dynamic> user, {bool isNewUser = false}) => {
      'accessToken': 'fake-jwt-token',
      'expiresAt': '2030-01-01T00:00:00Z',
      'isNewUser': isNewUser,
      'user': user,
    };

http.Response jsonResponse(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Lưu token trong bộ nhớ thay vì SharedPreferences
class MemoryTokenStorage extends TokenStorage {
  String? token;
  String? deviceToken;
  MemoryTokenStorage([this.token, this.deviceToken]);

  @override
  Future<String?> read() async => token;
  @override
  Future<void> save(String token) async => this.token = token;
  @override
  Future<void> clear() async => token = null;
  @override
  Future<String?> readDeviceToken() async => deviceToken;
  @override
  Future<void> saveDeviceToken(String token) async => deviceToken = token;
  @override
  Future<void> clearDeviceToken() async => deviceToken = null;
}

/// Giả lập hộp thoại Google: trả về [idToken] (null = người dùng bấm hủy)
class FakeGoogleAuth extends GoogleAuth {
  final String? idToken;
  FakeGoogleAuth(this.idToken);

  @override
  Future<String?> getIdToken() async => idToken;
  @override
  Future<void> signOut() async {}
}

/// SignalR giả: test không mở kết nối mạng thật. Test đẩy tin "thời gian thực" bằng [push] / [pushRoom].
class FakeChatRealtime implements ChatRealtime {
  static FakeChatRealtime? last; // kết nối mà màn chat vừa mở
  final _messages = StreamController<ChatMessage>.broadcast();
  final _rooms = StreamController<ChatRoom>.broadcast();
  final _notifications = StreamController<AppNotification>.broadcast();

  FakeChatRealtime(AuthService _) {
    last = this;
  }

  @override
  Stream<ChatMessage> get messages => _messages.stream;
  @override
  Stream<ChatRoom> get rooms => _rooms.stream;
  @override
  Stream<AppNotification> get notifications => _notifications.stream;
  @override
  bool get connected => true;
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}

  void push(Map<String, dynamic> message) => _messages.add(ChatMessage.fromJson(message));
  void pushRoom(Map<String, dynamic> room) => _rooms.add(ChatRoom.fromJson(room));
  void pushNotification(Map<String, dynamic> n) => _notifications.add(AppNotification.fromJson(n));
}

AuthService createAuth(MockClientHandler handler, {TokenStorage? storage, GoogleAuth? google}) {
  ChatRealtime.factory = FakeChatRealtime.new; // mọi test dùng SignalR giả
  return AuthService(
    api: ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api'),
    storage: storage ?? MemoryTokenStorage(),
    google: google ?? FakeGoogleAuth(null),
  );
}

// Giống GET api/onboarding/options
final Map<String, dynamic> onboardingOptionsJson = {
  'games': [
    {'id': 1, 'name': 'Liên Quân Mobile', 'genre': 'MOBA 5v5', 'positions': ['Đường Caesar', 'Đi rừng', 'Đường giữa', 'Xạ thủ', 'Trợ thủ']},
    {'id': 2, 'name': 'Valorant', 'genre': 'FPS Tactical', 'positions': ['Duelist', 'Initiator', 'Controller', 'Sentinel']},
    {'id': 4, 'name': 'Đấu Trường Chân Lý', 'genre': 'Auto Battler', 'positions': []},
  ],
  'purposes': [
    {'code': 'Tryhard', 'label': 'Leo rank nghiêm túc'},
    {'code': 'Fun', 'label': 'Chơi vui, giải trí'},
    {'code': 'Event', 'label': 'Săn sự kiện'},
  ],
  'playTimes': [
    {'code': 'Morning', 'label': 'Sáng (6h - 12h)'},
    {'code': 'Afternoon', 'label': 'Chiều (12h - 18h)'},
    {'code': 'Evening', 'label': 'Tối (18h - 23h)'},
    {'code': 'LateNight', 'label': 'Khuya (23h - 2h)'},
    {'code': 'Weekend', 'label': 'Cuối tuần'},
  ],
  'regions': [
    {'code': 'HCM', 'label': 'TP. Hồ Chí Minh'},
    {'code': 'HN', 'label': 'Hà Nội'},
  ],
  'hobbies': [
    {'id': 1, 'name': 'Voice Chat'},
    {'id': 2, 'name': 'K-Pop'},
    {'id': 3, 'name': 'Anime'},
  ],
};

// Giống GET api/onboarding của tài khoản gamer
final Map<String, dynamic> onboardingAnswersJson = {
  'games': [
    {'gameId': 1, 'position': 'Đường giữa', 'purpose': 'Fun'},
    {'gameId': 2, 'position': null, 'purpose': 'Tryhard'},
  ],
  'playTimes': ['Evening'],
  'region': 'HCM',
  'usesMic': true,
  'hobbyIds': [1],
  'teammateWish': null,
};

// Giống GET api/match/suggestions (tên rất dài để bắt lỗi tràn chữ)
final List<Map<String, dynamic>> matchSuggestionsJson = [
  {
    'userId': 'a0000000-0000-0000-0000-000000000003',
    'displayName': 'Nguyễn Hoàng Minh Thùy Trang Rất Dài',
    'avatarEmoji': '⚔️',
    'age': 20,
    'mbti': 'INTP',
    'bio': 'Cày sảnh giải trí sau giờ học, thích voice chat ca hát, tối nào cũng online đến khuya.',
    'region': 'HCM',
    'usesMic': true,
    'isVip': false,
    'gameId': 1,
    'gameName': 'Liên Quân Mobile',
    'position': 'Đường giữa',
    'purpose': 'Fun',
    'hobbies': ['Anime', 'Âm nhạc', 'Voice Chat'],
    'score': 95,
    'reason': 'Cùng chơi Liên Quân Mobile · cùng mục tiêu chơi vui, giải trí · cùng hay chơi buổi tối, khuya · cùng ở TP. Hồ Chí Minh',
  },
  {
    'userId': 'a0000000-0000-0000-0000-000000000008',
    'displayName': 'Đăng Khoa',
    'avatarEmoji': '🛡️',
    'age': null,
    'mbti': null,
    'bio': null,
    'region': 'HN',
    'usesMic': null,
    'isVip': true,
    'gameId': 2,
    'gameName': 'Valorant',
    'position': null,
    'purpose': 'Tryhard',
    'hobbies': [],
    'score': 60,
    'reason': 'Cùng chơi Valorant',
  },
];

// Giống GET api/quest: 1 nhiệm vụ xong chưa nhận, 1 đang làm, 1 đã nhận, 1 nhiệm vụ tuần
List<Map<String, dynamic>> questsJson() => [
      {'id': 1, 'code': 'daily_match', 'title': 'Ghép đội 1 lần', 'description': 'Sử dụng AI Matching để tìm đồng đội', 'type': 'Daily', 'target': 1, 'current': 1, 'rewardCoins': 10, 'rewardExp': 25, 'isCompleted': true, 'isClaimed': false, 'periodStart': '2026-10-12'},
      {'id': 3, 'code': 'daily_feed_like', 'title': 'Like 5 bài viết', 'description': 'Tương tác xây dựng cộng đồng', 'type': 'Daily', 'target': 5, 'current': 3, 'rewardCoins': 5, 'rewardExp': 15, 'isCompleted': false, 'isClaimed': false, 'periodStart': '2026-10-12'},
      {'id': 4, 'code': 'daily_play_team', 'title': 'Chơi 3 trận cùng nhóm BLUSH', 'description': null, 'type': 'Daily', 'target': 3, 'current': 3, 'rewardCoins': 20, 'rewardExp': 50, 'isCompleted': true, 'isClaimed': true, 'periodStart': '2026-10-12'},
      {'id': 5, 'code': 'weekly_win_streak', 'title': 'Đạt chuỗi 3 trận thắng', 'description': 'Thắng liên tiếp 3 trận cùng đồng đội', 'type': 'Weekly', 'target': 3, 'current': 0, 'rewardCoins': 100, 'rewardExp': 250, 'isCompleted': false, 'isClaimed': false, 'periodStart': '2026-10-12'},
    ];

// Giống GET api/leaderboard: 2 người bằng EXP cùng hạng 2, gamer đứng thứ 4 (tên rất dài để bắt lỗi tràn chữ)
Map<String, dynamic> leaderboardJson({bool includeMe = true}) {
  Map<String, dynamic> entry(int rank, String id, String name, int exp, {String? mbti, String? game, bool isMe = false, bool isVip = false}) => {
        'rank': rank, 'userId': id, 'displayName': name, 'avatarEmoji': '🎮', 'avatarUrl': null, 'mbti': mbti,
        'region': 'HCM', 'level': exp ~/ 100 + 1, 'exp': exp, 'gameName': game, 'isMe': isMe, 'isVip': isVip,
      };
  final me = entry(4, '33333333-3333-3333-3333-333333333333', 'Lưu Phước Nhật Tú', 1150, mbti: 'INFJ', game: 'Valorant', isMe: true);
  return {
    'items': [
      entry(1, 'a1', 'Hùng Dũng', 3100, mbti: 'ESTP', game: 'LMHT'),
      entry(2, 'a2', 'Nguyễn Hoàng Minh Thùy Trang Rất Dài', 2700, game: 'Liên Quân Mobile'),
      entry(2, 'a3', 'Khánh Linh', 2700, mbti: 'ENFP'),
      if (includeMe) me,
      entry(5, 'a5', 'Bảo Nam', 900, mbti: 'ISTP', game: 'PUBG Mobile', isVip: true),
    ],
    'me': includeMe ? me : null,
  };
}

// Giống 1 dòng GET api/admin/users. id của gamer trùng gamerJson; admin đang đăng nhập dùng id này nên không có menu thao tác
Map<String, dynamic> adminUserJson({String id = 'u-toxic', String email = 'toxic@gmail.com', String name = 'ToxicGamer99', String role = 'User', String status = 'Active', bool isVip = false}) => {
      'id': id, 'email': email, 'displayName': name, 'avatarUrl': null, 'role': role, 'status': status,
      'suspendedUntil': status == 'Suspended' ? '2026-10-19T06:00:00' : null, 'isVip': isVip, 'level': 5, 'exp': 450,
      'createdAt': '2026-10-01T00:00:00', 'lastLoginAt': null,
    };

Map<String, dynamic> adminUsersJson() => {
      'items': [
        adminUserJson(id: '33333333-3333-3333-3333-333333333333', email: 'admin@blush.vn', name: 'Super Admin', role: 'Admin', isVip: true),
        adminUserJson(),
        adminUserJson(id: 'u-ban', email: 'mot.email.rat.dai.cua.sinh.vien@daihoc.edu.vn', name: 'Nguyễn Hoàng Minh Thùy Trang Rất Dài', status: 'Banned'),
      ],
      'total': 3,
      'page': 1,
      'pageSize': 20,
      'stats': {'total': 11, 'vip': 2, 'locked': 1},
    };

// Giống api/reports/reasons, api/staff/reports, api/staff/icebreakers
final List<Map<String, dynamic>> reportReasonsJson = [
  {'code': 'Toxic', 'label': 'Chửi thề, xúc phạm'},
  {'code': 'Spam', 'label': 'Spam, quảng cáo'},
];

Map<String, dynamic> reportJson({int id = 7, String status = 'Pending', String? action}) => {
      'id': id, 'reporterId': 'r1', 'reporterName': 'Lưu Phước Nhật Tú', 'reportedUserId': 'u-toxic',
      'reportedUserName': 'Nguyễn Hoàng Minh Thùy Trang Rất Dài', 'reportedUserEmail': 'mot.email.rat.dai.cua.sinh.vien@daihoc.edu.vn',
      'reason': 'Chửi thề, xúc phạm: chửi cả team suốt trận', 'severity': 'High', 'status': status, 'actionTaken': action,
      'resolvedByName': action == null ? null : 'Hùng Moderator', 'resolvedAt': null, 'createdAt': '2026-10-12T03:00:00',
    };

final List<Map<String, dynamic>> iceBreakersJson = [
  {'id': 1, 'category': 'Strategy', 'question': 'Team thua 10 mạng đầu game, bạn sẽ?', 'optionA': 'Thủ trụ chờ late game', 'optionB': 'All-in lật kèo', 'optionAIcon': '🛡️', 'optionBIcon': '⚔️', 'isActive': true, 'createdAt': '2026-10-01T00:00:00'},
  {'id': 2, 'category': 'Lobby Style', 'question': 'Vào sảnh bạn thích?', 'optionA': 'Bật mic tấu hài', 'optionB': 'Im lặng tập trung', 'optionAIcon': '🎤', 'optionBIcon': '🎧', 'isActive': false, 'createdAt': '2026-10-01T00:00:00'},
];

// Giống api/chat: phòng giữa gamer (3333...) và ToxicGamer99 (u-toxic)
const chatRoomId = 'room-1';
const gamerId = '33333333-3333-3333-3333-333333333333';

Map<String, dynamic> chatMessageJson(String id, String content, {String? senderId = 'u-toxic', String createdAt = '2026-10-12T03:00:00'}) =>
    {'id': id, 'roomId': chatRoomId, 'senderId': senderId, 'content': content, 'createdAt': createdAt};

Map<String, dynamic> chatRoomJson({String? myChoice, bool theyAnswered = true, String? theirChoice, Map<String, dynamic>? last}) => {
      'id': chatRoomId,
      'other': {'id': 'u-toxic', 'displayName': 'Nguyễn Hoàng Minh Thùy Trang Rất Dài', 'avatarEmoji': '🌸', 'avatarUrl': null},
      'iceBreaker': {
        'question': 'Team thua 10 mạng đầu game, bạn sẽ?', 'optionA': 'Thủ trụ chờ late game', 'optionB': 'All-in lật kèo',
        'optionAIcon': '🛡️', 'optionBIcon': '⚔️', 'myChoice': myChoice, 'theyAnswered': theyAnswered, 'theirChoice': theirChoice,
      },
      'lastMessage': last,
      'createdAt': '2026-10-12T02:00:00',
    };

// Giống api/zones, api/zones/feed, api/posts/{id}/comments
Map<String, dynamic> zoneJson({int id = 2, String name = 'Chúa Tryhard Liên Quân', bool isVipOnly = false, bool isMember = true, bool canAccess = true}) => {
      'id': id, 'name': name, 'gameId': 1, 'gameName': 'Liên Quân Mobile', 'purpose': 'Tryhard', 'purposeLabel': 'Leo rank nghiêm túc',
      'description': 'Leo rank nghiêm túc, chơi theo meta', 'isVipOnly': isVipOnly, 'memberCount': 12, 'isMember': isMember, 'canAccess': canAccess,
    };

List<Map<String, dynamic>> zonesJson() => [
      zoneJson(),
      zoneJson(id: 1, name: 'Hội Tấu Hài Liên Quân', isMember: false),
      zoneJson(id: 7, name: 'Sảnh kín BLUSH Pass Pro', isVipOnly: true, isMember: false, canAccess: false),
    ];

Map<String, dynamic> postJson(String id, String content, {String authorId = 'u-toxic', String author = 'Nguyễn Hoàng Minh Thùy Trang Rất Dài', bool canDelete = false, int likes = 2, bool liked = false}) => {
      'id': id, 'zoneId': 2, 'zoneName': 'Chúa Tryhard Liên Quân',
      'author': {'id': authorId, 'displayName': author, 'avatarEmoji': '🌸', 'avatarUrl': null, 'isVip': true},
      'content': content, 'createdAt': '2026-10-12T03:00:00', 'likeCount': likes, 'commentCount': 1, 'likedByMe': liked, 'canDelete': canDelete,
    };

List<Map<String, dynamic>> postsJson() => [
      postJson('p1', 'Tối nay ai leo rank Liên Quân không? Thiếu 1 trợ thủ!'),
      postJson('p2', 'Bài của mình nè', authorId: gamerId, author: 'Lưu Phước Nhật Tú', canDelete: true, likes: 0),
    ];

// Giống api/notifications
Map<String, dynamic> notificationJson(String id, String type, String title, {String? body, String? link, bool isRead = false}) =>
    {'id': id, 'type': type, 'title': title, 'body': body, 'link': link, 'createdAt': '2026-10-12T03:00:00', 'isRead': isRead};

List<Map<String, dynamic>> notificationsJson() => [
      notificationJson('n1', 'PostLiked', 'Khánh Linh đã thả tim bài viết của bạn', body: 'Tối nay leo rank không?', link: 'zone:2'),
      notificationJson('n2', 'Warning', 'Cảnh báo từ đội kiểm duyệt BLUSH', body: 'Bạn bị báo cáo: Chửi thề, xúc phạm.'),
      notificationJson('n3', 'VipActivated', 'Đã kích hoạt BLUSH Pass', link: 'vip', isRead: true),
    ];

// Giống api/matches
Map<String, dynamic> matchJson(String id, {required String reporterId, required String teammateId, String status = 'Pending', String result = 'Win', bool canConfirm = false}) {
  Map<String, dynamic> user(String uid) => uid == gamerId
      ? {'id': gamerId, 'displayName': 'Lưu Phước Nhật Tú', 'avatarEmoji': '🎮', 'avatarUrl': null}
      : {'id': uid, 'displayName': 'ToxicGamer99', 'avatarEmoji': '😈', 'avatarUrl': null};
  return {
    'id': id, 'gameName': 'Liên Quân Mobile', 'result': result, 'status': status,
    'reporter': user(reporterId), 'teammate': user(teammateId), 'canConfirm': canConfirm, 'createdAt': '2026-10-12T03:00:00',
  };
}

// Giống GET api/payment/packages
final List<Map<String, dynamic>> vipPackagesJson = [
  {'code': 'month_basic', 'name': 'BLUSH Pass', 'price': 29000.0, 'durationDays': 30, 'aiTokenLimit': 50000, 'description': 'Gói cơ bản', 'badge': null},
  {'code': 'month_pro', 'name': 'BLUSH Pass Pro', 'price': 49000.0, 'durationDays': 30, 'aiTokenLimit': 150000, 'description': 'Gói Pro', 'badge': 'PHỔ BIẾN NHẤT 🔥'},
  {'code': 'quarter_pro', 'name': 'BLUSH Pass Pro 3 tháng', 'price': 129000.0, 'durationDays': 90, 'aiTokenLimit': 150000, 'description': 'Gói Pro 3 tháng', 'badge': 'TIẾT KIỆM 12%'},
];

// Giống GET api/payment/methods
final List<Map<String, dynamic>> paymentMethodsJson = [
  {'code': 'MoMo', 'name': 'Ví MoMo', 'description': 'Mở app MoMo hoặc quét mã để thanh toán', 'isAvailable': true},
  {'code': 'VietQR', 'name': 'Chuyển khoản VietQR', 'description': 'Quét mã bằng app ngân hàng bất kỳ', 'isAvailable': true},
];

const testOrderCode = 179115999459205;

// Giống POST api/payment/checkout. isMock = false: VietQR đi qua PayOS (có chuỗi QR + link trang PayOS)
Map<String, dynamic> checkoutJson(String method, {bool isMock = true}) => {
      'orderCode': testOrderCode,
      'amount': 129000.0,
      'packageCode': 'quarter_pro',
      'packageName': 'BLUSH Pass Pro 3 tháng',
      'method': method,
      'status': 'Pending',
      'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String().replaceAll('Z', ''),
      'isMock': isMock,
      'paymentUrl': isMock ? null : (method == 'VietQR' ? 'https://pay.payos.vn/web/plink' : 'https://test-payment.momo.vn/pay/BLUSH$testOrderCode'),
      'qrData': !isMock && method == 'VietQR' ? '00020101021238570010A000000727012700069704220113V3CAS03888888880208QRIBFTTA53037045406129000' : null,
      'qrImageUrl': null, // test không tải ảnh mạng
      'bankTransfer': method == 'VietQR'
          ? isMock
              ? {'bankName': 'MB Bank', 'accountNo': '0388888888', 'accountName': 'BLUSH GAMING', 'content': 'BLUSH $testOrderCode'}
              : {'bankName': 'MB Bank', 'accountNo': 'V3CAS0388888888', 'accountName': 'NGUYEN VAN A', 'content': 'CSQ1A2B3 BLUSH VIP'}
          : null,
    };

// Giống GET api/payment/transactions/{orderCode}
Map<String, dynamic> transactionJson({required String status, String method = 'MoMo'}) => {
      'orderCode': testOrderCode,
      'amount': 129000.0,
      'packageCode': 'quarter_pro',
      'packageName': 'BLUSH Pass Pro 3 tháng',
      'method': method,
      'status': status,
      'failureReason': status == 'Failed' ? 'Giao dịch bị từ chối (giả lập)' : null,
      'createdAt': '2026-10-05T07:00:00.123',
      'paidAt': status == 'Paid' ? '2026-10-05T07:01:00.456' : null,
      'expiresAt': '2026-10-05T07:15:00',
    };

// Giống GET api/admin/payments/summary
Map<String, dynamic> paymentSummaryJson({int days = 30}) => {
      'days': days,
      'revenueToday': 129000.0,
      'revenueThisMonth': 305000.0,
      'revenueInRange': days == 7 ? 305000.0 : 1223000.0,
      'transactionCount': 33,
      'paidCount': 27,
      'pendingCount': 1,
      'successRate': 81.8,
      'activeVipCount': 2,
      'totalUsers': 9,
      'newUsersInRange': 9,
      'daily': [
        for (var i = 0; i < days; i++)
          {
            'date': DateTime(2026, 10, 5).subtract(Duration(days: days - 1 - i)).toIso8601String().substring(0, 10),
            'revenue': i == days - 3 ? 236000.0 : (i % 3) * 29000.0,
            'count': i % 3,
          },
      ],
      'byMethod': [
        {'key': 'VietQR', 'label': 'Chuyển khoản VietQR', 'revenue': 443000.0, 'count': 7},
        {'key': 'MoMo', 'label': 'Ví MoMo', 'revenue': 390000.0, 'count': 10},
      ],
      'byPackage': [
        {'key': 'month_pro', 'label': 'BLUSH Pass Pro', 'revenue': 588000.0, 'count': 12},
        {'key': 'month_basic', 'label': 'BLUSH Pass', 'revenue': 377000.0, 'count': 13},
        {'key': 'quarter_pro', 'label': 'BLUSH Pass Pro 3 tháng', 'revenue': 258000.0, 'count': 2},
      ],
    };

// Giống GET api/admin/payments/transactions (email rất dài để bắt lỗi tràn chữ)
final List<Map<String, dynamic>> adminTransactionsJson = [
  {
    'orderCode': 179116082433973,
    'userEmail': 'mot.email.rat.dai.cua.sinh.vien@daihoc.edu.vn',
    'userDisplayName': 'Nguyễn Hoàng Minh Thùy Trang Rất Dài',
    'amount': 129000.0,
    'packageName': 'BLUSH Pass Pro 3 tháng',
    'method': 'VietQR',
    'status': 'Pending',
    'failureReason': null,
    'gatewayTransactionId': null,
    'createdAt': '2026-10-05T07:00:00',
    'paidAt': null,
  },
  {
    'orderCode': 179116082433001,
    'userEmail': 'linh@demo.blush.vn',
    'userDisplayName': 'Khánh Linh',
    'amount': 49000.0,
    'packageName': 'BLUSH Pass Pro',
    'method': 'MoMo',
    'status': 'Failed',
    'failureReason': 'Thanh toán không thành công',
    'gatewayTransactionId': null,
    'createdAt': '2026-10-04T07:00:00',
    'paidAt': null,
  },
];

/// Giả lập backend: trả dữ liệu theo đường dẫn API
MockClientHandler fakeBackend({Map<String, dynamic>? user}) => (req) async {
      final path = req.url.path.replaceFirst('/api/', '');
      return switch (path) {
        'onboarding/options' => jsonResponse(onboardingOptionsJson),
        'onboarding' when req.method == 'GET' => jsonResponse(onboardingAnswersJson),
        'onboarding' => jsonResponse(gamerJson()), // lưu xong -> onboardingCompleted = true
        'match/suggestions' => jsonResponse(matchSuggestionsJson),
        'quest' => jsonResponse(questsJson()),
        'leaderboard' => jsonResponse(leaderboardJson(includeMe: req.url.queryParameters['region'] != 'HN')),
        'profile' => jsonResponse({...gamerJson(), ...(jsonDecode(req.body) as Map<String, dynamic>)}),
        _ when path.startsWith('quest/') && path.endsWith('/claim') => jsonResponse({
            'message': 'Hoàn thành nhiệm vụ!',
            'addedCoins': 10,
            'addedExp': 25,
            'user': gamerJson(coins: 350, exp: 1175),
          }),
        'payment/packages' => jsonResponse(vipPackagesJson),
        'payment/methods' => jsonResponse(paymentMethodsJson),
        'payment/checkout' => jsonResponse(checkoutJson(jsonDecode(req.body)['method'] as String)),
        'payment/transactions' => jsonResponse([transactionJson(status: 'Paid'), transactionJson(status: 'Pending', method: 'VietQR'), transactionJson(status: 'Failed')]),
        'auth/me' => jsonResponse(user ?? gamerJson()),
        'admin/payments/summary' => jsonResponse(paymentSummaryJson(days: int.parse(req.url.queryParameters['days'] ?? '30'))),
        'admin/payments/transactions' => jsonResponse({'items': adminTransactionsJson, 'total': 25, 'page': 1, 'pageSize': 20}),
        'admin/users' => jsonResponse(adminUsersJson()),
        'zones' => jsonResponse(zonesJson()),
        'notifications' => jsonResponse(notificationsJson()),
        'matches/options' => jsonResponse({
            'teammates': [{'id': 'u-toxic', 'displayName': 'ToxicGamer99', 'avatarEmoji': '😈', 'avatarUrl': null}],
            'games': [{'gameId': 1, 'gameName': 'Liên Quân Mobile', 'rank': null, 'ranks': ['Đồng', 'Bạc', 'Kim Cương', 'Cao Thủ']}],
          }),
        'matches/rank' => jsonResponse({'gameId': 1, 'gameName': 'Liên Quân Mobile', 'rank': jsonDecode(req.body)['rank'], 'ranks': ['Đồng', 'Bạc', 'Kim Cương', 'Cao Thủ']}),
        'matches' when req.method == 'GET' => jsonResponse([
            matchJson('mt1', reporterId: 'u-toxic', teammateId: gamerId, canConfirm: true),
            matchJson('mt2', reporterId: gamerId, teammateId: 'u-toxic', status: 'Confirmed', result: 'Loss'),
          ]),
        'matches' => jsonResponse(matchJson('mt9', reporterId: gamerId, teammateId: 'u-toxic', result: jsonDecode(req.body)['result'] as String)),
        _ when path.startsWith('matches/') && path.endsWith('/confirm') => jsonResponse(
            matchJson('mt1', reporterId: 'u-toxic', teammateId: gamerId, status: jsonDecode(req.body)['confirm'] == true ? 'Confirmed' : 'Rejected')),
        'badges/me' => jsonResponse([
            {'code': 'local_mvp', 'name': 'Local MVP', 'icon': '👑', 'description': 'Top 3 EXP trong khu vực của bạn', 'earned': true, 'earnedAt': '2026-10-12T03:00:00'},
            {'code': 'friendly', 'name': 'Hòa đồng', 'icon': '💬', 'description': 'Viết 20 bình luận trong các Zone', 'earned': false, 'earnedAt': null},
          ]),
        'notifications/summary' => jsonResponse({'unreadNotifications': 2, 'unreadChats': 1}),
        _ when path.startsWith('notifications/') => http.Response('', 204),
        'zones/feed' => jsonResponse(postsJson()),
        _ when path.startsWith('zones/') && path.endsWith('/join') => jsonResponse(zoneJson(id: 1, name: 'Hội Tấu Hài Liên Quân', isMember: req.method == 'POST')),
        _ when path.startsWith('zones/') && path.endsWith('/posts') && req.method == 'POST' => jsonResponse(
            postJson('p9', jsonDecode(req.body)['content'] as String, authorId: gamerId, author: 'Lưu Phước Nhật Tú', canDelete: true, likes: 0)),
        _ when path.startsWith('zones/') && path.endsWith('/posts') => jsonResponse(postsJson()),
        _ when path.startsWith('posts/') && path.endsWith('/like') => jsonResponse({'liked': req.method == 'POST', 'likeCount': req.method == 'POST' ? 3 : 2}),
        _ when path.startsWith('posts/') && path.endsWith('/comments') && req.method == 'POST' => jsonResponse({
            'id': 'c9', 'postId': 'p1', 'author': {'id': gamerId, 'displayName': 'Lưu Phước Nhật Tú', 'avatarEmoji': '🎮', 'avatarUrl': null, 'isVip': false},
            'content': jsonDecode(req.body)['content'], 'createdAt': '2026-10-12T03:10:00', 'canDelete': true,
          }),
        _ when path.startsWith('posts/') && path.endsWith('/comments') => jsonResponse([
            {'id': 'c1', 'postId': 'p1', 'author': {'id': 'u-x', 'displayName': 'Khánh Linh', 'avatarEmoji': '🌸', 'avatarUrl': null, 'isVip': false},
             'content': 'Mình đi rừng nha', 'createdAt': '2026-10-12T03:05:00', 'canDelete': false},
          ]),
        _ when path.startsWith('posts/') && req.method == 'DELETE' => jsonResponse({'message': 'Đã gỡ bài viết.'}),
        'blocks' => jsonResponse([
            {'id': 'u-toxic', 'displayName': 'ToxicGamer99', 'avatarEmoji': '😈', 'avatarUrl': null},
          ]),
        _ when path.startsWith('blocks/') && req.method == 'DELETE' => jsonResponse({'message': 'Đã bỏ chặn.'}),
        _ when path.startsWith('blocks/') => jsonResponse({'message': 'Đã chặn. Hai bạn sẽ không nhắn tin hay được ghép đội với nhau.'}),
        'chat/rooms' when req.method == 'GET' => jsonResponse([chatRoomJson(last: chatMessageJson('m2', 'Chào bạn, leo rank không?'))]),
        'chat/rooms' => jsonResponse(chatRoomJson()),
        _ when path.endsWith('/icebreaker') => jsonResponse(chatRoomJson(myChoice: jsonDecode(req.body)['choice'] as String, theirChoice: 'B')),
        _ when path.endsWith('/messages') && req.method == 'GET' => jsonResponse([
            chatMessageJson('m1', 'Hai bạn chọn khác nhau. Thử thuyết phục đối phương xem!', senderId: null, createdAt: '2026-10-12T02:59:00'),
            chatMessageJson('m2', 'Chào bạn, leo rank không?'),
          ]),
        _ when path.endsWith('/messages') => jsonResponse(chatMessageJson('m3', jsonDecode(req.body)['content'] as String, senderId: gamerId, createdAt: '2026-10-12T03:01:00')),
        _ when path.startsWith('chat/rooms/') => jsonResponse(chatRoomJson()),
        'reports/reasons' => jsonResponse(reportReasonsJson),
        'reports' => jsonResponse({'message': 'Đã gửi báo cáo. Cảm ơn bạn, Staff sẽ xem xét sớm.'}),
        'staff/reports' => jsonResponse({'items': [reportJson()], 'total': 1, 'page': 1, 'pageSize': 20, 'stats': {'total': 5, 'pending': 1, 'resolved': 4}}),
        _ when path.startsWith('staff/reports/') => jsonResponse(reportJson(status: 'Resolved', action: jsonDecode(req.body)['action'] as String)),
        'staff/icebreakers/categories' => jsonResponse([{'code': 'Strategy', 'label': 'Chiến thuật'}, {'code': 'Lobby Style', 'label': 'Phong cách sảnh'}]),
        'staff/icebreakers' when req.method == 'GET' => jsonResponse(iceBreakersJson),
        'staff/icebreakers' => jsonResponse({...iceBreakersJson[0], ...(jsonDecode(req.body) as Map<String, dynamic>), 'id': 9, 'isActive': true}),
        _ when path.startsWith('staff/icebreakers/') && req.method == 'DELETE' => jsonResponse({'message': 'Đã xóa câu hỏi.'}),
        _ when path.startsWith('staff/icebreakers/') => jsonResponse({...iceBreakersJson[1], 'isActive': jsonDecode(req.body)['isActive']}),
        _ when path.startsWith('admin/users/') && path.endsWith('/status') => jsonResponse(adminUserJson(status: jsonDecode(req.body)['status'] as String)),
        _ when path.startsWith('admin/users/') && path.endsWith('/role') => jsonResponse(adminUserJson(role: jsonDecode(req.body)['role'] as String)),
        _ when path.startsWith('admin/payments/transactions/') => jsonResponse({...adminTransactionsJson[0], 'status': 'Paid'}),
        _ when path.startsWith('payment/mock/') => jsonResponse(transactionJson(status: jsonDecode(req.body)['success'] == true ? 'Paid' : 'Failed')),
        _ when path.endsWith('/cancel') => jsonResponse(transactionJson(status: 'Cancelled')),
        _ when path.startsWith('payment/transactions/') => jsonResponse(transactionJson(status: 'Pending')),
        _ => jsonResponse(authResponse(user ?? gamerJson())),
      };
    };

/// AuthService đã đăng nhập sẵn tài khoản gamer (dùng cho test giao diện)
Future<AuthService> loggedInGamer({bool onboardingCompleted = true}) async {
  final auth = createAuth(fakeBackend(user: gamerJson(onboardingCompleted: onboardingCompleted)));
  await auth.login('gamer@blush.vn', '123456');
  return auth;
}

// Font mặc định trong test vẽ mỗi chữ thành ô vuông (rộng hơn chữ thật),
// nên nạp font Roboto có sẵn trong Flutter SDK để đo kích thước giống điện thoại thật.
Future<void> loadRobotoFromSdk() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final dir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final name in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf', 'roboto-italic.ttf']) {
    final file = File('$dir/$name');
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
  }
  await loader.load();
}
