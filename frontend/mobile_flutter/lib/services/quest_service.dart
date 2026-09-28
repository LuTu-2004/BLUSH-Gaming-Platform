import 'package:flutter/material.dart';
import '../models/quest_model.dart';
import 'auth_service.dart';

// Giữ danh sách nhiệm vụ để Dashboard và màn Nhiệm Vụ dùng CHUNG một dữ liệu.
class QuestService extends ChangeNotifier {
  static const int checkInCoins = 15;
  static const int checkInExp = 50;

  // TODO: lấy danh sách nhiệm vụ từ backend (bảng Quests + UserQuests)
  final List<QuestModel> dailyQuests = [
    QuestModel(id: 1, title: 'Ghép đội 1 lần', desc: 'Sử dụng AI Matching để tìm đồng đội hợp cạ', current: 1, target: 1, rewardCoins: 10, rewardExp: 25, isClaimed: true),
    QuestModel(id: 2, title: 'Đăng 1 bài trên Feed', desc: 'Chia sẻ chiến tích hoặc chiến thuật trên phân khu', current: 0, target: 1, rewardCoins: 15, rewardExp: 30),
    QuestModel(id: 3, title: 'Like 5 bài viết', desc: 'Tương tác xây dựng cộng đồng game thủ sôi nổi', current: 3, target: 5, rewardCoins: 5, rewardExp: 15),
    QuestModel(id: 4, title: 'Chơi 3 trận cùng nhóm BLUSH', desc: 'Vào trận cùng đồng đội từ sảnh đấu BLUSH', current: 3, target: 3, rewardCoins: 20, rewardExp: 50),
  ];

  int get completedCount => dailyQuests.where((q) => q.isDone).length;
  int get totalCount => dailyQuests.length;
  double get dailyProgress => totalCount == 0 ? 0 : completedCount / totalCount;

  /// Điểm danh qua backend (POST api/quest/claim-daily). Trả về lời nhắn để hiện cho người dùng.
  /// Ném ApiException nếu lỗi (VD: hôm nay đã điểm danh rồi).
  Future<String> checkIn(AuthService auth) async {
    final data = await auth.api.post('quest/claim-daily');
    auth.updateUserFromJson(data['user'] as Map<String, dynamic>);
    return data['message'] as String;
  }

  void claim(QuestModel quest, AuthService auth) {
    if (!quest.isDone || quest.isClaimed) return;
    quest.isClaimed = true;
    auth.addReward(coins: quest.rewardCoins, exp: quest.rewardExp);
    notifyListeners();
  }
}
