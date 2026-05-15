import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/appointment_model.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dbService = DatabaseService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Meus Agendamentos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: dbService.getAppointments(authProvider.userModel!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 64,
                    color: AppTheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Você ainda não possui agendamentos.',
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                ],
              ),
            );
          }

          final appointments = snapshot.data!;
          appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];
              final isPast = appt.dateTime.isBefore(DateTime.now());
              final canCancel =
                  appt.status != 'cancelled' &&
                  appt.status != 'completed' &&
                  appt.dateTime.difference(DateTime.now()).inHours >= 24;

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: appt.status == 'completed'
                              ? Colors.green.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: appt.status == 'completed'
                              ? Border.all(
                                  color: Colors.green.withOpacity(0.2),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: appt.status == 'cancelled'
                                  ? Colors.red.withOpacity(0.1)
                                  : appt.status == 'completed'
                                  ? Colors.green.withOpacity(0.1)
                                  : AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              appt.status == 'cancelled'
                                  ? Icons.close
                                  : appt.status == 'completed'
                                  ? Icons.check
                                  : Icons.spa_outlined,
                              color: appt.status == 'cancelled'
                                  ? Colors.red
                                  : appt.status == 'completed'
                                  ? Colors.green
                                  : AppTheme.textDark,
                            ),
                          ),
                          title: Text(
                            appt.serviceName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                              decoration: appt.status == 'cancelled'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: AppTheme.textLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy • HH:mm',
                                      ).format(appt.dateTime),
                                      style: const TextStyle(
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                                if (appt.status == 'completed')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Serviço realizado',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          trailing: _buildStatusBadge(
                            appt,
                            isPast,
                            canCancel,
                            context,
                            dbService,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(
    AppointmentModel appt,
    bool isPast,
    bool canCancel,
    BuildContext context,
    DatabaseService db,
  ) {
    if (canCancel) {
      return TextButton(
        onPressed: () => _showCancelDialog(context, db, appt),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: Colors.red.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'CANCELAR',
          style: TextStyle(
            color: Colors.red,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Color badgeColor;
    String statusText;

    if (appt.status == 'cancelled') {
      badgeColor = Colors.red;
      statusText = 'CANCELADO';
    } else if (appt.status == 'completed') {
      badgeColor = Colors.green;
      statusText = 'CONCLUÍDO';
    } else if (isPast) {
      badgeColor = Colors.grey;
      statusText = 'REALIZADO';
    } else {
      badgeColor = Colors.green;
      statusText = 'CONFIRMADO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    DatabaseService db,
    AppointmentModel appt,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar Agendamento?'),
        content: const Text(
          'Tem certeza que deseja cancelar este agendamento? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'VOLTAR',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await db.updateAppointmentStatus(appt.id, 'cancelled');

              // Notifica o usuário do cancelamento e limpa lembretes
              await NotificationService().sendCancellationNotification(appt);

              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'CONFIRMAR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
