import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin/admin_home.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Se o usuário não está logado, mostra tela de login
    if (authProvider.userModel == null) {
      return const LoginScreen();
    } else {
      // Se logado, verifica se é admin ou cliente
      if (authProvider.userModel!.isAdmin) {
        return const AdminHome();
      }
      return const HomeScreen();
    }
  }
}
