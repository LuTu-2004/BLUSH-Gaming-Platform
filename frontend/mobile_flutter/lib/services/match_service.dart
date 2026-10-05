import '../api/api_client.dart';
import '../models/match_model.dart';
import '../models/onboarding_model.dart';
import 'auth_service.dart';

/// Gọi API khảo sát sau đăng ký + gợi ý đồng đội.
/// Dùng: `MatchService(context.read<AuthService>())`
class MatchService {
  final AuthService auth;

  MatchService(this.auth);

  ApiClient get _api => auth.api;

  Future<OnboardingOptions> getOptions() async =>
      OnboardingOptions.fromJson(await _api.get('onboarding/options') as Map<String, dynamic>);

  /// Câu trả lời đã lưu (để sửa lại trong Hồ sơ)
  Future<OnboardingAnswers> getAnswers() async =>
      OnboardingAnswers.fromJson(await _api.get('onboarding') as Map<String, dynamic>);

  /// Lưu câu trả lời. Backend trả về user mới (onboardingCompleted = true) -> app tự vào trang chủ.
  Future<void> saveAnswers(OnboardingAnswers answers) async {
    final data = await _api.post('onboarding', answers.toJson());
    auth.updateUserFromJson(data as Map<String, dynamic>);
  }

  /// [gameId] null = mọi game mình chơi
  Future<List<MatchSuggestion>> getSuggestions({int? gameId, int limit = 20}) async {
    final query = ['limit=$limit', if (gameId != null) 'gameId=$gameId'].join('&');
    final data = await _api.get('match/suggestions?$query') as List;
    return data.map((e) => MatchSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }
}
