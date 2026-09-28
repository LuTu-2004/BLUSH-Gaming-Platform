// Khớp với UserDto trả về từ backend (backend/Dtos/UserDto.cs)
class UserModel {
  final String id;
  final String email;
  final String role; // 'User' | 'Staff' | 'Admin'
  final String displayName;
  final DateTime? dateOfBirth;
  final String mbti;
  final String bio;
  final String? avatarUrl;
  final String avatarEmoji;
  final String sundayAnswer;
  final String overthinkAnswer;
  final int exp;
  final int coins;
  final bool isVip;
  final DateTime? lastCheckInDate;
  final bool hasPassword; // false = chỉ đăng nhập Google
  final bool twoFactorEnabled;

  const UserModel({
    required this.id,
    required this.email,
    this.role = 'User',
    required this.displayName,
    this.dateOfBirth,
    this.mbti = '',
    this.bio = '',
    this.avatarUrl,
    this.avatarEmoji = '🎮',
    this.sundayAnswer = '',
    this.overthinkAnswer = '',
    this.exp = 0,
    this.coins = 0,
    this.isVip = false,
    this.lastCheckInDate,
    this.hasPassword = true,
    this.twoFactorEnabled = false,
  });

  // Quy tắc tài liệu: mỗi 100 EXP = +1 Level (giống cột CurrentLevel trong SQL)
  int get level => exp ~/ 100 + 1;

  bool get isStaffOrAdmin => role == 'Staff' || role == 'Admin';

  /// Tuổi tính từ ngày sinh; null nếu chưa khai báo (VD: mới đăng nhập Google)
  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    final hadBirthday = now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    return now.year - dob.year - (hadBirthday ? 0 : 1);
  }

  /// Đã điểm danh hôm nay chưa (so theo giờ Việt Nam giống backend)
  bool get checkedInToday {
    final last = lastCheckInDate;
    if (last == null) return false;
    final vnNow = DateTime.now().toUtc().add(const Duration(hours: 7));
    return last.year == vnNow.year && last.month == vnNow.month && last.day == vnNow.day;
  }

  UserModel copyWith({
    String? bio,
    String? sundayAnswer,
    String? overthinkAnswer,
    int? exp,
    int? coins,
    bool? isVip,
  }) {
    return UserModel(
      id: id,
      email: email,
      role: role,
      displayName: displayName,
      dateOfBirth: dateOfBirth,
      mbti: mbti,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl,
      avatarEmoji: avatarEmoji,
      sundayAnswer: sundayAnswer ?? this.sundayAnswer,
      overthinkAnswer: overthinkAnswer ?? this.overthinkAnswer,
      exp: exp ?? this.exp,
      coins: coins ?? this.coins,
      isVip: isVip ?? this.isVip,
      lastCheckInDate: lastCheckInDate,
      hasPassword: hasPassword,
      twoFactorEnabled: twoFactorEnabled,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'User',
      displayName: json['displayName'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] as String? ?? ''),
      mbti: json['mbti'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      avatarEmoji: json['avatarEmoji'] as String? ?? '🎮',
      sundayAnswer: json['sundayAnswer'] as String? ?? '',
      overthinkAnswer: json['overthinkAnswer'] as String? ?? '',
      exp: json['exp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      isVip: json['isVip'] as bool? ?? false,
      lastCheckInDate: DateTime.tryParse(json['lastCheckInDate'] as String? ?? ''),
      hasPassword: json['hasPassword'] as bool? ?? true,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
    );
  }
}
