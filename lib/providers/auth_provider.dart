import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.user.listen((UserModel? user) {
      _userModel = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final success = await _authService.signInWithEmailAndPassword(
      email,
      password,
    );
    if (success) {
      _userModel = await _authService.getUserData(''); // Busca o usuário logado
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    _isLoading = true;
    notifyListeners();
    final user = await _authService.registerWithEmailAndPassword(
      name,
      email,
      password,
      phone,
    );
    if (user != null) {
      _userModel = user;
    }
    _isLoading = false;
    notifyListeners();
    return user != null;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }
}
