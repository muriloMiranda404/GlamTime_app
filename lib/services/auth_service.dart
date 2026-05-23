import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _userKey = 'logged_user';
  static const String _allUsersKey = 'all_users';

  // Stream simplificada (usando um poller ou apenas retorno imediato para mock)
  Stream<UserModel?> get user async* {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      yield UserModel.fromMap(jsonDecode(userData));
    } else {
      yield null;
    }
  }

  // Cadastro Local
  Future<UserModel?> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Simula uma lista de usuários no "banco de dados" local
      List<String> allUsers = prefs.getStringList(_allUsersKey) ?? [];

      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
        isAdmin: email.contains(
          'admin',
        ), // Se o email tiver 'admin', vira admin
      );

      allUsers.add(jsonEncode(newUser.toMap()));
      await prefs.setStringList(_allUsersKey, allUsers);
      await prefs.setString(_userKey, jsonEncode(newUser.toMap()));

      return newUser;
    } catch (e) {
      return null;
    }
  }

  // Login Híbrido (Email ou Telefone)
  Future<bool> signInWithIdentifier(String identifier, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> allUsers = prefs.getStringList(_allUsersKey) ?? [];

    for (var userStr in allUsers) {
      final userMap = jsonDecode(userStr);
      // Verifica se o identificador bate com email OU telefone
      if (userMap['email'] == identifier || userMap['phone'] == identifier) {
        await prefs.setString(_userKey, userStr);
        return true;
      }
    }
    return false;
  }

  // Logout Local
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<UserModel?> getUserData(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return UserModel.fromMap(jsonDecode(userData));
    }
    return null;
  }
}
