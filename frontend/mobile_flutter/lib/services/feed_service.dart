import '../api/api_client.dart';
import '../models/feed_model.dart';
import 'auth_service.dart';

/// Gọi API Zone + Feed (backend/Controllers/ZonesController.cs, PostsController.cs).
/// Dùng: `FeedService(context.read<AuthService>())`
class FeedService {
  static const pageSize = 20; // khớp FeedService.PageSize ở backend

  final AuthService auth;

  FeedService(this.auth);

  ApiClient get _api => auth.api;

  Future<List<Zone>> getZones() async => (await _api.get('zones') as List).map((e) => Zone.fromJson(e as Map<String, dynamic>)).toList();

  Future<Zone> join(int zoneId) async => Zone.fromJson(await _api.post('zones/$zoneId/join') as Map<String, dynamic>);

  Future<Zone> leave(int zoneId) async => Zone.fromJson(await _api.delete('zones/$zoneId/join') as Map<String, dynamic>);

  /// [zoneId] null = bảng tin các Zone mình tham gia. [before] = tải bài cũ hơn.
  Future<List<Post>> getPosts({int? zoneId, DateTime? before}) async {
    final path = zoneId == null ? 'zones/feed' : 'zones/$zoneId/posts';
    final query = before == null ? '' : '?before=${Uri.encodeQueryComponent(before.toUtc().toIso8601String())}';
    return (await _api.get('$path$query') as List).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Post> createPost(int zoneId, String content) async =>
      Post.fromJson(await _api.post('zones/$zoneId/posts', {'content': content.trim()}) as Map<String, dynamic>);

  Future<void> deletePost(String postId) => _api.delete('posts/$postId');

  /// Trả về số tim mới
  Future<int> setLike(String postId, bool like) async {
    final data = like ? await _api.post('posts/$postId/like') : await _api.delete('posts/$postId/like');
    return data['likeCount'] as int;
  }

  Future<List<Comment>> getComments(String postId) async =>
      (await _api.get('posts/$postId/comments') as List).map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();

  Future<Comment> addComment(String postId, String content) async =>
      Comment.fromJson(await _api.post('posts/$postId/comments', {'content': content.trim()}) as Map<String, dynamic>);

  Future<void> deleteComment(String commentId) => _api.delete('comments/$commentId');
}
