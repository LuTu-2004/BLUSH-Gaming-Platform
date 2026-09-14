class UserModel {
  final String id;
  final String fullName;
  final String email;
  final int age;
  final String mbti;
  final String bio;
  final int level;
  final int exp;
  final int coins;
  final bool isVip;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.age,
    required this.mbti,
    required this.bio,
    required this.level,
    required this.exp,
    required this.coins,
    required this.isVip,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 18,
      mbti: json['mbti'] ?? 'INFJ',
      bio: json['bio'] ?? '',
      level: json['currentLevel'] ?? json['level'] ?? 1,
      exp: json['exp'] ?? 0,
      coins: json['coins'] ?? 0,
      isVip: json['isVip'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'age': age,
      'mbti': mbti,
      'bio': bio,
      'currentLevel': level,
      'exp': exp,
      'coins': coins,
      'isVip': isVip,
    };
  }
}
