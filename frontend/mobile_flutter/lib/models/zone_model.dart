class ZoneModel {
  final int id;
  final String zoneName;
  final String game;
  final String purpose;
  final String description;
  final int onlineCount;
  final bool isVipOnly;

  ZoneModel({
    required this.id,
    required this.zoneName,
    required this.game,
    required this.purpose,
    required this.description,
    required this.onlineCount,
    required this.isVipOnly,
  });
}

class QuestModel {
  final int id;
  final String title;
  final String desc;
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
    required this.current,
    required this.target,
    required this.rewardCoins,
    required this.rewardExp,
    required this.isDone,
    this.isClaimed = false,
  });
}
