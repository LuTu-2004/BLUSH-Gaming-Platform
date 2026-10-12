import '../api/api_client.dart';
import '../models/chat_model.dart';
import 'auth_service.dart';

/// Chặn người dùng (api/blocks). Chặn có tác dụng cả 2 chiều: không chat, không gợi ý ghép đội với nhau.
/// Dùng: `BlockService(context.read<AuthService>())`
class BlockService {
  final AuthService auth;

  BlockService(this.auth);

  ApiClient get _api => auth.api;

  Future<List<ChatUser>> getBlocked() async =>
      (await _api.get('blocks') as List).map((e) => ChatUser.fromJson(e as Map<String, dynamic>)).toList();

  Future<String> block(String userId) async => (await _api.post('blocks/$userId'))['message'] as String;

  Future<String> unblock(String userId) async => (await _api.delete('blocks/$userId'))['message'] as String;
}
