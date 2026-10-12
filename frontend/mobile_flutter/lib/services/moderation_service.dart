import '../api/api_client.dart';
import '../models/moderation_model.dart';
import '../models/onboarding_model.dart';
import 'auth_service.dart';

/// Báo cáo vi phạm (mọi người chơi) + khu kiểm duyệt (Staff/Admin).
/// Dùng: `ModerationService(context.read<AuthService>())`
class ModerationService {
  static const pageSize = 20;

  final AuthService auth;

  ModerationService(this.auth);

  ApiClient get _api => auth.api;

  // ── Người chơi ───────────────────────────────────────────────

  Future<List<OptionItem>> getReportReasons() async =>
      (await _api.get('reports/reasons') as List).map((e) => OptionItem.fromJson(e as Map<String, dynamic>)).toList();

  /// Trả về lời cảm ơn từ backend. Ném ApiException nếu lỗi (VD: đã báo cáo người này rồi).
  Future<String> reportUser(String userId, String reasonCode, String detail) async {
    final data = await _api.post('reports', {'reportedUserId': userId, 'reasonCode': reasonCode, 'detail': detail.trim()});
    return data['message'] as String;
  }

  // ── Staff ────────────────────────────────────────────────────

  /// [status] null = tất cả, 'Pending' | 'Resolved'
  Future<ReportPage> getReports({String? status, int page = 1}) async {
    final query = ['page=$page', 'pageSize=$pageSize', if (status != null) 'status=$status'].join('&');
    return ReportPage.fromJson(await _api.get('staff/reports?$query') as Map<String, dynamic>);
  }

  /// [action] = 'Warn' | 'Suspend' (tạm khóa 3 ngày) | 'Dismiss'
  Future<ModerationReport> resolveReport(int id, String action) async =>
      ModerationReport.fromJson(await _api.post('staff/reports/$id/resolve', {'action': action}) as Map<String, dynamic>);

  Future<List<IceBreaker>> getIceBreakers() async =>
      (await _api.get('staff/icebreakers') as List).map((e) => IceBreaker.fromJson(e as Map<String, dynamic>)).toList();

  Future<List<OptionItem>> getIceBreakerCategories() async =>
      (await _api.get('staff/icebreakers/categories') as List).map((e) => OptionItem.fromJson(e as Map<String, dynamic>)).toList();

  Future<IceBreaker> createIceBreaker({required String category, required String question, required String optionA, required String optionB}) async =>
      IceBreaker.fromJson(await _api.post('staff/icebreakers', {
        'category': category,
        'question': question.trim(),
        'optionA': optionA.trim(),
        'optionB': optionB.trim(),
      }) as Map<String, dynamic>);

  Future<IceBreaker> setIceBreakerActive(int id, bool isActive) async =>
      IceBreaker.fromJson(await _api.post('staff/icebreakers/$id/active', {'isActive': isActive}) as Map<String, dynamic>);

  Future<void> deleteIceBreaker(int id) => _api.delete('staff/icebreakers/$id');
}
