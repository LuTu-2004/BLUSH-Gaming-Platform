import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/quest_model.dart';
import 'auth_service.dart';

// Giữ danh sách nhiệm vụ để Dashboard và màn Nhiệm Vụ dùng CHUNG một dữ liệu.
// Dữ liệu lấy từ backend (GET api/quest), tiến độ do backend tự cộng khi người dùng làm hành động tương ứng.
class QuestService extends ChangeNotifier {
  static const int checkInCoins = 15;
  static const int checkInExp = 50;

  List<QuestModel> _quests = [];
  bool _isLoading = false;
  String? _error;

  List<QuestModel> get dailyQuests => _ofType('Daily');
  List<QuestModel> get weeklyQuests => _ofType('Weekly');
  List<QuestModel> get seasonalQuests => _ofType('Seasonal');
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _quests.isNotEmpty;

  List<QuestModel> _ofType(String type) => _quests.where((q) => q.type == type).toList();

  int get completedCount => dailyQuests.where((q) => q.isDone).length;
  int get totalCount => dailyQuests.length;
  double get dailyProgress => totalCount == 0 ? 0 : completedCount / totalCount;

  /// Tải lại danh sách nhiệm vụ. Lỗi thì giữ dữ liệu cũ và ghi vào [error].
  Future<void> load(AuthService auth) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await auth.api.get('quest') as List;
      _quests = data.map((e) => QuestModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Điểm danh qua backend (POST api/quest/claim-daily). Trả về lời nhắn để hiện cho người dùng.
  /// Ném ApiException nếu lỗi (VD: hôm nay đã điểm danh rồi).
  Future<String> checkIn(AuthService auth) async {
    final data = await auth.api.post('quest/claim-daily');
    auth.updateUserFromJson(data['user'] as Map<String, dynamic>);
    return data['message'] as String;
  }

  /// Nhận quà nhiệm vụ (POST api/quest/{id}/claim): backend cộng Coins/EXP rồi trả về user mới.
  /// Ném ApiException nếu lỗi (VD: chưa hoàn thành, đã nhận rồi).
  Future<String> claim(QuestModel quest, AuthService auth) async {
    final data = await auth.api.post('quest/${quest.id}/claim');
    auth.updateUserFromJson(data['user'] as Map<String, dynamic>);
    quest.isClaimed = true;
    notifyListeners();
    return data['message'] as String;
  }
}
