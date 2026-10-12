import '../api/api_client.dart';
import '../models/chat_model.dart';
import '../models/payment_model.dart';
import 'auth_service.dart';

// Khớp backend/Dtos/MatchLogDtos.cs

class MatchLog {
  final String id;
  final String gameName;
  final String result; // Win | Loss
  final String status; // Pending | Confirmed | Rejected
  final ChatUser reporter;
  final ChatUser teammate;
  final bool canConfirm;
  final DateTime createdAt;

  const MatchLog({
    required this.id,
    required this.gameName,
    required this.result,
    required this.status,
    required this.reporter,
    required this.teammate,
    this.canConfirm = false,
    required this.createdAt,
  });

  bool get isWin => result == 'Win';

  factory MatchLog.fromJson(Map<String, dynamic> json) => MatchLog(
        id: json['id'] as String,
        gameName: json['gameName'] as String? ?? '',
        result: json['result'] as String? ?? 'Win',
        status: json['status'] as String? ?? 'Pending',
        reporter: ChatUser.fromJson(json['reporter'] as Map<String, dynamic>),
        teammate: ChatUser.fromJson(json['teammate'] as Map<String, dynamic>),
        canConfirm: json['canConfirm'] as bool? ?? false,
        createdAt: parseServerDate(json['createdAt']) ?? DateTime.now(),
      );
}

class GameRank {
  final int gameId;
  final String gameName;
  final String? rank;
  final List<String> ranks; // thấp -> cao

  const GameRank({required this.gameId, required this.gameName, this.rank, this.ranks = const []});

  factory GameRank.fromJson(Map<String, dynamic> json) => GameRank(
        gameId: json['gameId'] as int,
        gameName: json['gameName'] as String? ?? '',
        rank: json['rank'] as String?,
        ranks: (json['ranks'] as List? ?? const []).cast<String>(),
      );
}

class MatchOptions {
  final List<ChatUser> teammates; // người đã chat cùng
  final List<GameRank> games;

  const MatchOptions({required this.teammates, required this.games});

  factory MatchOptions.fromJson(Map<String, dynamic> json) => MatchOptions(
        teammates: (json['teammates'] as List? ?? const []).map((e) => ChatUser.fromJson(e as Map<String, dynamic>)).toList(),
        games: (json['games'] as List? ?? const []).map((e) => GameRank.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Gọi API Nhật ký trận đấu + rank (backend/Controllers/MatchesController.cs)
class MatchLogService {
  final AuthService auth;

  MatchLogService(this.auth);

  ApiClient get _api => auth.api;

  Future<List<MatchLog>> getMine() async => (await _api.get('matches') as List).map((e) => MatchLog.fromJson(e as Map<String, dynamic>)).toList();

  Future<MatchOptions> getOptions() async => MatchOptions.fromJson(await _api.get('matches/options') as Map<String, dynamic>);

  Future<MatchLog> create({required String teammateId, required int gameId, required bool win}) async =>
      MatchLog.fromJson(await _api.post('matches', {'teammateId': teammateId, 'gameId': gameId, 'result': win ? 'Win' : 'Loss'}) as Map<String, dynamic>);

  Future<MatchLog> confirm(String id, bool confirm) async =>
      MatchLog.fromJson(await _api.post('matches/$id/confirm', {'confirm': confirm}) as Map<String, dynamic>);

  Future<GameRank> setRank(int gameId, String? rank) async =>
      GameRank.fromJson(await _api.post('matches/rank', {'gameId': gameId, 'rank': rank}) as Map<String, dynamic>);
}
