// Khớp backend/Dtos/OnboardingDtos.cs

/// 1 lựa chọn dạng mã + nhãn (mục đích, khung giờ, khu vực)
class OptionItem {
  final String code;
  final String label;

  const OptionItem(this.code, this.label);

  factory OptionItem.fromJson(Map<String, dynamic> json) => OptionItem(json['code'] as String, json['label'] as String);
}

class GameOption {
  final int id;
  final String name;
  final String? genre;
  final List<String> positions; // rỗng = game không chia vị trí (VD: Đấu Trường Chân Lý)

  const GameOption({required this.id, required this.name, this.genre, this.positions = const []});

  factory GameOption.fromJson(Map<String, dynamic> json) => GameOption(
        id: json['id'] as int,
        name: json['name'] as String,
        genre: json['genre'] as String?,
        positions: (json['positions'] as List? ?? const []).cast<String>(),
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
  final List<OptionItem> regions;
  final List<HobbyOption> hobbies;

  const OnboardingOptions({required this.games, required this.purposes, required this.playTimes, required this.regions, required this.hobbies});

  factory OnboardingOptions.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List? ?? const []).map((e) => parse(e as Map<String, dynamic>)).toList();
    return OnboardingOptions(
      games: list('games', GameOption.fromJson),
      purposes: list('purposes', OptionItem.fromJson),
      playTimes: list('playTimes', OptionItem.fromJson),
      regions: list('regions', OptionItem.fromJson),
      hobbies: list('hobbies', HobbyOption.fromJson),
    );
  }
}

/// Game người dùng chọn + vị trí + mục đích
class GameChoice {
  String? position;
  String purpose; // 'Tryhard' | 'Fun' | 'Event'

  GameChoice({this.position, this.purpose = 'Fun'});
}

/// Câu trả lời onboarding. Màn hình sửa trực tiếp các trường rồi gửi [toJson] lên backend.
class OnboardingAnswers {
  final Map<int, GameChoice> games; // gameId -> lựa chọn (giữ thứ tự chọn)
  final Set<String> playTimes;
  String? region;
  bool? usesMic; // null = tùy trận
  final Set<int> hobbyIds;
  String teammateWish;

  OnboardingAnswers({
    Map<int, GameChoice>? games,
    Set<String>? playTimes,
    this.region,
    this.usesMic,
    Set<int>? hobbyIds,
    this.teammateWish = '',
  })  : games = games ?? {},
        playTimes = playTimes ?? {},
        hobbyIds = hobbyIds ?? {};

  factory OnboardingAnswers.fromJson(Map<String, dynamic> json) {
    final region = json['region'] as String?;
    return OnboardingAnswers(
      games: {
        for (final g in (json['games'] as List? ?? const []).cast<Map<String, dynamic>>())
          g['gameId'] as int: GameChoice(position: g['position'] as String?, purpose: g['purpose'] as String? ?? 'Fun'),
      },
      playTimes: (json['playTimes'] as List? ?? const []).cast<String>().toSet(),
      region: region == null || region.isEmpty ? null : region,
      usesMic: json['usesMic'] as bool?,
      hobbyIds: (json['hobbyIds'] as List? ?? const []).cast<int>().toSet(),
      teammateWish: json['teammateWish'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'games': [
          for (final e in games.entries) {'gameId': e.key, 'position': e.value.position, 'purpose': e.value.purpose},
        ],
        'playTimes': playTimes.toList(),
        'region': region,
        'usesMic': usesMic,
        'hobbyIds': hobbyIds.toList(),
        'teammateWish': teammateWish.trim(),
      };
}
