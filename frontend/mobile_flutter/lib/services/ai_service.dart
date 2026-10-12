import '../api/api_client.dart';
import 'auth_service.dart';

// Khớp backend/Dtos/AiDtos.cs

class AiUsage {
  final String tier; // Free | Basic | Pro
  final int usedToday;
  final int? dailyLimit; // null = không giới hạn số lượt

  const AiUsage({required this.tier, required this.usedToday, this.dailyLimit});

  int? get remainingToday => dailyLimit == null ? null : (dailyLimit! - usedToday).clamp(0, dailyLimit!);

  /// "Còn 2 lượt AI hôm nay" / "Không giới hạn lượt AI mỗi ngày"
  String get label => remainingToday == null ? 'Không giới hạn lượt AI mỗi ngày' : 'Còn $remainingToday lượt AI hôm nay';

  factory AiUsage.fromJson(Map<String, dynamic> json) => AiUsage(
        tier: json['tier'] as String? ?? 'Free',
        usedToday: json['usedToday'] as int? ?? 0,
        dailyLimit: json['dailyLimit'] as int?,
      );
}

class AiSuggestions {
  final String logId;
  final List<String> suggestions;
  final AiUsage usage;

  const AiSuggestions({required this.logId, required this.suggestions, required this.usage});

  factory AiSuggestions.fromJson(Map<String, dynamic> json) => AiSuggestions(
        logId: json['logId'] as String,
        suggestions: (json['suggestions'] as List? ?? const []).cast<String>(),
        usage: AiUsage.fromJson(json['usage'] as Map<String, dynamic>),
      );
}

class AiExplanation {
  final String logId;
  final String explanation;
  final AiUsage usage;

  const AiExplanation({required this.logId, required this.explanation, required this.usage});

  factory AiExplanation.fromJson(Map<String, dynamic> json) => AiExplanation(
        logId: json['logId'] as String,
        explanation: json['explanation'] as String? ?? '',
        usage: AiUsage.fromJson(json['usage'] as Map<String, dynamic>),
      );
}

/// Gọi API AI (backend/Controllers/AiController.cs). Lỗi:
///   e.code == 'AI_QUOTA_EXCEEDED' -> hết lượt (gợi ý nâng cấp VIP)
///   e.code == 'AI_UNAVAILABLE'    -> AI chưa bật / đang bận (dùng nội dung có sẵn, không bị trừ lượt)
class AiService {
  static const quotaExceeded = 'AI_QUOTA_EXCEEDED';
  static const unavailable = 'AI_UNAVAILABLE';

  final AuthService auth;

  AiService(this.auth);

  ApiClient get _api => auth.api;

  Future<AiSuggestions> suggestMessages(String roomId) async =>
      AiSuggestions.fromJson(await _api.post('ai/chat/$roomId/suggest') as Map<String, dynamic>);

  Future<AiExplanation> explainMatch(String userId) async =>
      AiExplanation.fromJson(await _api.post('ai/match/$userId/explain') as Map<String, dynamic>);

  Future<String> report(String logId, {String? reason}) async =>
      (await _api.post('ai/logs/$logId/report', {'reason': reason}))['message'] as String;
}
