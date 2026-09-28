// Khớp bảng Quests + UserQuests trong database/script_database.sql
class QuestModel {
  final int id;
  final String title;
  final String desc;
  final int current;
  final int target;
  final int rewardCoins;
  final int rewardExp;
  bool isClaimed;

  QuestModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.current,
    required this.target,
    required this.rewardCoins,
    required this.rewardExp,
    this.isClaimed = false,
  });

  bool get isDone => current >= target;
  double get progress => (current / target).clamp(0, 1).toDouble();
}
