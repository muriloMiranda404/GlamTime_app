import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          linux: initializationSettingsLinux,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Lógica ao clicar na notificação
      },
    );

    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> scheduleAppointmentNotifications(
    AppointmentModel appointment,
  ) async {
    if (!await _areNotificationsEnabled()) return;

    // 1. Confirmação Imediata (Agendamento feito)
    await _showImmediateNotification(
      id: appointment.id.hashCode,
      title: 'Agendamento Realizado! ✨',
      body:
          'Seu horário para ${appointment.serviceName} foi agendado com sucesso para ${appointment.dateTime.day}/${appointment.dateTime.month}.',
    );

    // 2. Lembrete 24 horas antes
    final twentyFourHoursBefore = appointment.dateTime.subtract(
      const Duration(hours: 24),
    );
    if (twentyFourHoursBefore.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: appointment.id.hashCode + 1,
        title: 'Lembrete: Seu momento GlamTime amanhã! 🌸',
        body:
            'Faltam 24 horas para o seu atendimento de ${appointment.serviceName}. Esperamos por você!',
        scheduledDate: twentyFourHoursBefore,
      );
    }

    // 3. Lembrete 1 hora antes
    final oneHourBefore = appointment.dateTime.subtract(
      const Duration(hours: 1),
    );
    if (oneHourBefore.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: appointment.id.hashCode + 2,
        title: 'Falta apenas 1 hora! 💖',
        body:
            'Seu atendimento de ${appointment.serviceName} começa em 1 hora. Até logo!',
        scheduledDate: oneHourBefore,
      );
    }
  }

  Future<void> sendCancellationNotification(
    AppointmentModel appointment,
  ) async {
    if (!await _areNotificationsEnabled()) return;

    await _showImmediateNotification(
      id: appointment.id.hashCode + 3,
      title: 'Agendamento Cancelado 😔',
      body:
          'Seu agendamento para ${appointment.serviceName} foi cancelado. Esperamos ver você em breve!',
    );

    // Cancela lembretes agendados
    await _notificationsPlugin.cancel(id: appointment.id.hashCode + 1);
    await _notificationsPlugin.cancel(id: appointment.id.hashCode + 2);
  }

  Future<void> sendRescheduleNotification(AppointmentModel appointment) async {
    if (!await _areNotificationsEnabled()) return;

    await _showImmediateNotification(
      id: appointment.id.hashCode + 4,
      title: 'Horário Reagendado 🕒',
      body:
          'Seu agendamento para ${appointment.serviceName} foi alterado para um novo horário.',
    );

    // Reagenda os lembretes
    await scheduleAppointmentNotifications(appointment);
  }

  Future<void> _showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'glamtime_immediate',
          'Confirmações e Avisos',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'glamtime_reminders',
          'Lembretes de Agendamento',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
