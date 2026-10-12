// Khớp QuestDto ở backend (GET api/quest): bảng Quests + tiến độ UserQuests của kỳ hiện tại
class QuestModel {
  final int id;
  final String title;
  final String desc;
  final String type; // 'Daily' | 'Weekly' | 'Seasonal'
  final int current;
  final int target;
  final int rewardCoins;
  final int rewardExp;
  final bool isDone;
  bool isClaimed;

  QuestModel({
    required this.id,
    required this.title,
    required this.desc,
    this.type = 'Daily',
    required this.current,
    required this.target,
    required this.rewardCoins,
    required this.rewardExp,
    bool? isDone,
    this.isClaimed = false,
  }) : isDone = isDone ?? current >= target;

  factory QuestModel.fromJson(Map<String, dynamic> json) => QuestModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        desc: json['description'] as String? ?? '',
        type: json['type'] as String? ?? 'Daily',
        current: json['current'] as int? ?? 0,
        target: json['target'] as int? ?? 1,
        rewardCoins: json['rewardCoins'] as int? ?? 0,
        rewardExp: json['rewardExp'] as int? ?? 0,
        isDone: json['isCompleted'] as bool? ?? false,
        isClaimed: json['isClaimed'] as bool? ?? false,
      );

  double get progress => (current / target).clamp(0, 1).toDouble();
}
