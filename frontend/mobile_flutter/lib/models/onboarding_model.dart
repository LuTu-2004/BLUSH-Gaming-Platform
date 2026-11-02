// Khớp backend/Dtos/OnboardingDtos.cs

/// 1 lựa chọn dạng mã + nhãn (mục đích, khung giờ, khu vực, phong cách chơi)
class OptionItem {
  final String code;
  final String label;

  const OptionItem(this.code, this.label);

  factory OptionItem.fromJson(Map<String, dynamic> json) => OptionItem(json['code'] as String, json['label'] as String);
}

/// Tỉnh/thành + miền nó thuộc về (North | Central | South | Overseas)
class RegionOption extends OptionItem {
  final String zone;

  const RegionOption(super.code, super.label, this.zone);

  factory RegionOption.fromJson(Map<String, dynamic> json) =>
      RegionOption(json['code'] as String, json['label'] as String, json['zone'] as String? ?? '');
}

class GameOption {
  final int id;
  final String name;
  final String? genre;
  final List<String> positions; // rỗng = game không chia vị trí (VD: Đấu Trường Chân Lý)
  final List<String> ranks; // thấp -> cao, rỗng = game không có bảng rank

  const GameOption({required this.id, required this.name, this.genre, this.positions = const [], this.ranks = const []});

  factory GameOption.fromJson(Map<String, dynamic> json) => GameOption(
        id: json['id'] as int,
        name: json['name'] as String,
        genre: json['genre'] as String?,
        positions: (json['positions'] as List? ?? const []).cast<String>(),
        ranks: (json['ranks'] as List? ?? const []).cast<String>(),
      );
}

class HobbyOption {
  final int id;
  final String name;

  const HobbyOption(this.id, this.name);

  factory HobbyOption.fromJson(Map<String, dynamic> json) => HobbyOption(json['id'] as int, json['name'] as String);
}

/// Dữ liệu để vẽ các bước onboarding (GET api/onboarding/options)
class OnboardingOptions {
  final List<GameOption> games;
  final List<OptionItem> purposes;
  final List<OptionItem> playTimes;
  final List<RegionOption> regions;
  final List<OptionItem> zones; // miền: nhóm danh sách tỉnh, lọc bảng xếp hạng
  final List<HobbyOption> hobbies;
  // Phong cách chơi (bước 3), backend cũ không gửi thì rỗng -> ẩn câu hỏi
  final List<OptionItem> teamRoles;
  final List<OptionItem> talkLevels;
  final List<OptionItem> banterLevels;

  const OnboardingOptions({
    required this.games,
    required this.purposes,
    required this.playTimes,
    required this.regions,
    this.zones = const [],
    required this.hobbies,
    this.teamRoles = const [],
    this.talkLevels = const [],
    this.banterLevels = const [],
  });

  /// Tên tỉnh/thành theo mã, không có thì trả lại mã
  String regionLabel(String code) => regions.where((r) => r.code == code).firstOrNull?.label ?? code;

  factory OnboardingOptions.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List? ?? const []).map((e) => parse(e as Map<String, dynamic>)).toList();
    return OnboardingOptions(
      games: list('games', GameOption.fromJson),
      purposes: list('purposes', OptionItem.fromJson),
      playTimes: list('playTimes', OptionItem.fromJson),
      regions: list('regions', RegionOption.fromJson),
      zones: list('zones', OptionItem.fromJson),
      hobbies: list('hobbies', HobbyOption.fromJson),
      teamRoles: list('teamRoles', OptionItem.fromJson),
      talkLevels: list('talkLevels', OptionItem.fromJson),
      banterLevels: list('banterLevels', OptionItem.fromJson),
    );
  }
}

/// Game người dùng chọn + vị trí + rank + mục đích
class GameChoice {
  String? position;
  String? rank; // null = chưa khai
  String purpose; // 'Tryhard' | 'Fun' | 'Event'

  GameChoice({this.position, this.rank, this.purpose = 'Fun'});
}

/// Câu trả lời onboarding. Màn hình sửa trực tiếp các trường rồi gửi [toJson] lên backend.
class OnboardingAnswers {
  final Map<int, GameChoice> games; // gameId -> lựa chọn (giữ thứ tự chọn)
  final Set<String> playTimes;
  String? region;
  bool? usesMic; // null = tùy trận
  String? teamRole; // phong cách chơi: null = chưa chọn
  String? talkLevel;
  String? banterLevel;
  final Set<int> hobbyIds;
  String teammateWish;
  DateTime? dateOfBirth; // chỉ gửi khi tài khoản chưa có ngày sinh (đăng nhập Google lần đầu)

  OnboardingAnswers({
    Map<int, GameChoice>? games,
    Set<String>? playTimes,
    this.region,
    this.usesMic,
    this.teamRole,
    this.talkLevel,
    this.banterLevel,
    Set<int>? hobbyIds,
    this.teammateWish = '',
    this.dateOfBirth,
  })  : games = games ?? {},
        playTimes = playTimes ?? {},
        hobbyIds = hobbyIds ?? {};

  factory OnboardingAnswers.fromJson(Map<String, dynamic> json) {
    final region = json['region'] as String?;
    return OnboardingAnswers(
      games: {
        for (final g in (json['games'] as List? ?? const []).cast<Map<String, dynamic>>())
          g['gameId'] as int: GameChoice(
            position: g['position'] as String?,
            rank: g['rank'] as String?,
            purpose: g['purpose'] as String? ?? 'Fun',
          ),
      },
      playTimes: (json['playTimes'] as List? ?? const []).cast<String>().toSet(),
      region: region == null || region.isEmpty ? null : region,
      usesMic: json['usesMic'] as bool?,
      teamRole: json['teamRole'] as String?,
      talkLevel: json['talkLevel'] as String?,
      banterLevel: json['banterLevel'] as String?,
      hobbyIds: (json['hobbyIds'] as List? ?? const []).cast<int>().toSet(),
      teammateWish: json['teammateWish'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'games': [
          for (final e in games.entries) {'gameId': e.key, 'position': e.value.position, 'rank': e.value.rank, 'purpose': e.value.purpose},
        ],
        'playTimes': playTimes.toList(),
        'region': region,
        'usesMic': usesMic,
        'teamRole': teamRole,
        'talkLevel': talkLevel,
        'banterLevel': banterLevel,
        'hobbyIds': hobbyIds.toList(),
        'teammateWish': teammateWish.trim(),
        if (dateOfBirth case final dob?) 'dateOfBirth': dob.toIso8601String().substring(0, 10),
      };
}
