import '../api/api_client.dart';
import '../models/rating_model.dart';
import 'auth_service.dart';

/// Đánh giá app BLUSH 1-5 sao (api/ratings). Mỗi người 1 đánh giá, gửi lại = sửa.
/// Dùng: `RatingService(context.read<AuthService>())`
class RatingService {
  final AuthService auth;

  RatingService(this.auth);

  ApiClient get _api => auth.api;

  Future<MyRating> getMine() async => MyRating.fromJson(await _api.get('ratings/me') as Map<String, dynamic>);

  Future<MyRating> submit(int stars, String comment) async => MyRating.fromJson(
        await _api.post('ratings/me', {'stars': stars, if (comment.trim().isNotEmpty) 'comment': comment.trim()}) as Map<String, dynamic>,
      );
}
