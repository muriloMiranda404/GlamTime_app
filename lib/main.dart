import 'package:flutter/material.dart';
import 'package:glam_time/screens/firebase_error_screen.dart';
import 'package:glam_time/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'screens/wrapper.dart';
import 'screens/my_appointments_screen.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';

bool firebaseOk = false;
void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp();
      firebaseOk = true;
    } catch (e) {
      debugPrint("Erro na inicialização automática do Firebase: $e");
      try {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyACOm1cKvLSfzvnmpQHyQmKqKXsAGwkWVI',
            appId: '1:729328356052:android:70b1355e0fee6c8c0b4941',
            messagingSenderId: '729328356052',
            projectId: 'glamtime-8bfea',
            storageBucket: 'glamtime-8bfea.firebasestorage.app',
          ),
        );
        firebaseOk = true;
        debugPrint("Firebase inicializado com sucesso via opções manuais.");
      } catch (e2) {
        firebaseOk = false;
        debugPrint("Firebase não pôde ser configurado. Modo demonstração.");
      }
    }

    // propaga o estado para o DatabaseService
    if (firebaseOk) {
      DatabaseService.markFirebaseInitialized();
    }

    try {
      final notificationService = NotificationService();
      await notificationService.init();
    } catch (e) {
      debugPrint("Erro ao inicializar notificações: $e");
    }

    runApp(MyApp(firebaseOk: firebaseOk));
}

class MyApp extends StatelessWidget {
  final bool firebaseOk;
  const MyApp({super.key, required this.firebaseOk});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'GlamTime',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: firebaseOk ? const Wrapper() : const FirebaseErrorScreen(),
        routes: {'/my_appointments': (context) => const MyAppointmentsScreen()},
      ),
    );
  }
}