import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'screens/wrapper.dart';
import 'screens/my_appointments_screen.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Tenta inicializar o Firebase. Se estiver no Android/iOS com os arquivos corretos, funciona automaticamente.
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Erro na inicialização automática do Firebase: $e");
    try {
      // Fallback para inicialização manual caso o arquivo não seja detectado (comum em Windows ou ambientes de teste)
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyACOm1cKvLSfzvnmpQHyQmKqKXsAGwkWVI',
          appId: '1:729328356052:android:70b1355e0fee6c8c0b4941',
          messagingSenderId: '729328356052',
          projectId: 'glamtime-8bfea',
          storageBucket: 'glamtime-8bfea.firebasestorage.app',
        ),
      );
      debugPrint("Firebase inicializado com sucesso via opções manuais.");
    } catch (e2) {
      debugPrint(
        "Nota: Firebase não pôde ser configurado. O aplicativo funcionará em modo demonstração.",
      );
    }
  }

  try {
    final notificationService = NotificationService();
    await notificationService.init();
  } catch (e) {
    debugPrint("Erro ao inicializar notificações: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'GlamTime',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Wrapper(),
        routes: {'/my_appointments': (context) => const MyAppointmentsScreen()},
      ),
    );
  }
}
