import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class FirebaseErrorScreen extends StatelessWidget {
  const FirebaseErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 80,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Sem conexão com o servidor',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível conectar ao banco de dados. Verifique sua conexão com a internet e reinicie o aplicativo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}