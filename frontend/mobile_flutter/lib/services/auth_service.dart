import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserModel? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  UserModel? get currentUser => _currentUser;

  void loginDemo(String email) {
    _isLoggedIn = true;
    _currentUser = UserModel(
      id: '33333333-3333-3333-3333-333333333333',
      fullName: 'Lưu Phước Nhật Tú',
      email: email,
      age: 20,
      mbti: 'INFJ',
      bio: 'Mê game tấu hài & ca hát voice chat',
      level: 12,
      exp: 1250,
      coins: 340,
      isVip: true,
    );
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }
}
