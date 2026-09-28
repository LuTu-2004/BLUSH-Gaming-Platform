class ZoneModel {
  final int id;
  final String zoneName;
  final String game;
  final String purpose;
  final String description;
  final int onlineCount;
  final bool isVipOnly;

  const ZoneModel({
    required this.id,
    required this.zoneName,
    required this.game,
    required this.purpose,
    required this.description,
    required this.onlineCount,
    required this.isVipOnly,
  });
}
