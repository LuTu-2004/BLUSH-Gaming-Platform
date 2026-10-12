import '../models/payment_model.dart';
import 'auth_service.dart';

// Khớp backend/Dtos/BadgeDtos.cs. Tên AppBadge để không trùng widget Badge của Flutter.
class AppBadge {
  final String code;
  final String name;
  final String icon; // emoji
  final String? description; // điều kiện nhận
  final bool earned;
  final DateTime? earnedAt;

  const AppBadge({required this.code, required this.name, required this.icon, this.description, this.earned = false, this.earnedAt});

  factory AppBadge.fromJson(Map<String, dynamic> json) => AppBadge(
        code: json['code'] as String,
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '🏅',
        description: json['description'] as String?,
        earned: json['earned'] as bool? ?? false,
        earnedAt: parseServerDate(json['earnedAt']),
      );
}

/// GET api/badges/me: mọi huy hiệu (đã nhận xếp trước). Gọi là backend tự kiểm tra + trao huy hiệu mới.
class BadgeService {
  final AuthService auth;

  BadgeService(this.auth);

  Future<List<AppBadge>> getMine() async =>
      (await auth.api.get('badges/me') as List).map((e) => AppBadge.fromJson(e as Map<String, dynamic>)).toList();
}
