import 'package:flutter/material.dart';
import 'package:glam_time/models/professional_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/appointment_model.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import 'manage_services.dart';
import 'financial_dashboard.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AppointmentsPage(),
    const ManageServices(),
    const FinancialDashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    // Passamos o ID selecionado para a página de agendamentos se necessário
    // Ou melhor, mantemos o estado do filtro na AppointmentsPage
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_cut),
            label: 'Serviços',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Financeiro',
          ),
        ],
      ),
    );
  }
}

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  String _selectedProfessionalId = 'Todos';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dbService = DatabaseService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Agenda GlamTime',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textDark),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vinda de volta!',
                  style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                ),
                Text(
                  'Próximos Agendamentos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Seletor de Profissional
                StreamBuilder<List<ProfessionalModel>>(
                  stream: dbService.professionals,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final professionals = snapshot.data!;
                    return SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: professionals.length + 1,
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final prof = isAll ? null : professionals[index - 1];
                          final id = isAll ? 'Todos' : prof!.id;
                          final name = isAll ? 'Todos' : prof!.name;
                          final isSelected = _selectedProfessionalId == id;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textDark,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedProfessionalId = id);
                                }
                              },
                              selectedColor: AppTheme.primary,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
              stream: dbService.allAppointments,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                var appointments = snapshot.data!;

                // Filtrar por profissional
                if (_selectedProfessionalId != 'Todos') {
                  appointments = appointments
                      .where((a) => a.professionalId == _selectedProfessionalId)
                      .toList();
                }

                // Ordenar por data
                appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                if (appointments.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt = appointments[index];
                    final isCancelled = appt.status == 'cancelled';
                    final isCompleted = appt.status == 'completed';

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: _buildAppointmentItem(
                              appt,
                              isCancelled,
                              isCompleted,
                              dbService,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBlockTimeDialog(context, dbService),
        backgroundColor: AppTheme.textDark,
        icon: const Icon(Icons.block, color: Colors.white),
        label: const Text(
          'Bloquear Horário',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppTheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum agendamento encontrado.',
            style: TextStyle(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(
    AppointmentModel appt,
    bool isCancelled,
    bool isCompleted,
    DatabaseService dbService,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCancelled
                ? Colors.red.withOpacity(0.1)
                : isCompleted
                ? Colors.green.withOpacity(0.1)
                : AppTheme.accent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCancelled
                ? Icons.close
                : isCompleted
                ? Icons.check
                : Icons.person,
            color: isCancelled
                ? Colors.red
                : isCompleted
                ? Colors.green
                : AppTheme.textDark,
          ),
        ),
        title: Text(
          appt.userName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            decoration: (isCancelled || isCompleted)
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
                    Icons.spa_outlined,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appt.serviceName,
                      style: const TextStyle(color: AppTheme.textLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy • HH:mm').format(appt.dateTime),
                    style: const TextStyle(color: AppTheme.textLight),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: (isCancelled || isCompleted)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCancelled ? Colors.red : Colors.green).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCancelled ? 'CANCELADO' : 'CONCLUÍDO',
                  style: TextStyle(
                    color: isCancelled ? Colors.red : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    onPressed: () =>
                        dbService.updateAppointmentStatus(appt.id, 'completed'),
                    tooltip: 'Concluir',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.redAccent,
                    ),
                    onPressed: () async {
                      await dbService.updateAppointmentStatus(
                        appt.id,
                        'cancelled',
                      );
                      await NotificationService().sendCancellationNotification(
                        appt,
                      );
                    },
                    tooltip: 'Cancelar',
                  ),
                ],
              ),
      ),
    );
  }

  void _showBlockTimeDialog(BuildContext context, DatabaseService db) async {
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Bloquear Horário',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecione o dia e horário que deseja bloquear para agendamentos.',
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primary,
                ),
                title: Text(DateFormat('dd/MM/yyyy').format(selectedDate!)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate!,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time, color: AppTheme.primary),
                title: Text(selectedTime!.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime!,
                  );
                  if (time != null) setDialogState(() => selectedTime = time);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: AppTheme.textLight),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final blockDateTime = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );

                final blockAppt = AppointmentModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: 'admin_block',
                  userName: 'BLOQUEIO',
                  serviceName: 'Indisponível',
                  dateTime: blockDateTime,
                  totalPrice: 0,
                  durationInMinutes: 60,
                  status: 'confirmed',
                  userPhone: '',
                  serviceId: '',
                  professionalId: '',
                  professionalName: '',
                );

                await db.addAppointment(blockAppt);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'BLOQUEAR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
