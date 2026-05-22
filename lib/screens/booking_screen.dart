import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import '../models/professional_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class BookingScreen extends StatefulWidget {
  final List<ServiceModel> services;
  const BookingScreen({super.key, required this.services});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  ProfessionalModel? _selectedProfessional;
  String _paymentMethod = 'Dinheiro';
  final _dbService = DatabaseService();
  bool _isChecking = false;

  final List<String> _paymentMethods = ['Dinheiro', 'Débito', 'Crédito', 'Pix'];

  @override
  void initState() {
    super.initState();
    _loadDefaultProfessional();
  }

  Future<void> _loadDefaultProfessional() async {
    try {
      final professionals = await _dbService.professionals.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => [],
      );
      final activeProfs = professionals.where((p) => p.isActive).toList();
      if (activeProfs.isNotEmpty) {
        setState(() {
          _selectedProfessional = activeProfs.first;
        });
      } else {
        // Fallback: se não houver profissionais no banco, cria um padrão temporário para não travar
        setState(() {
          _selectedProfessional = ProfessionalModel(
            id: 'default_prof',
            name: 'Profissional GlamTime',
            photoUrl: '',
            specialty: 'Geral',
            services: [],
            workingHours: {},
          );
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar profissional: $e');
    }
  }

  int get _totalDuration =>
      widget.services.fold(0, (sum, s) => sum + s.durationInMinutes);
  double get _totalPrice => widget.services.fold(0, (sum, s) => sum + s.price);
  String get _serviceNames => widget.services.map((s) => s.name).join(', ');

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma data primeiro')),
      );
      return;
    }

    if (_selectedProfessional == null) {
      await _loadDefaultProfessional();
    }

    final prof = _selectedProfessional!;
    final dayOfWeek = _selectedDate!.weekday.toString();
    final dayConfig = prof.workingHours[dayOfWeek];

    if (dayConfig == null || dayConfig['isOpen'] == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O profissional não trabalha neste dia.')),
        );
      }
      return;
    }

    final startTimeStr = dayConfig['start'] ?? '08:00';
    final endTimeStr = dayConfig['end'] ?? '18:00';
    final interval = prof.slotIntervalMinutes;

    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');

    DateTime current = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final end = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    List<DateTime> availableSlots = [];
    
    // Mostra loading enquanto verifica disponibilidade
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    while (current.isBefore(end)) {
      final isAvail = await _dbService.isTimeSlotAvailable(
        current,
        _totalDuration,
        professionalId: prof.id,
      );
      if (isAvail) {
        availableSlots.add(current);
      }
      current = current.add(Duration(minutes: interval));
    }

    if (mounted) Navigator.pop(context); // Remove loading

    if (availableSlots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não há horários disponíveis para este dia.')),
        );
      }
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Horários Disponíveis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Intervalos de ${prof.slotIntervalMinutes ~/ 60}h${prof.slotIntervalMinutes % 60}min',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: availableSlots.length,
                    itemBuilder: (context, index) {
                      final slot = availableSlots[index];
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTime = TimeOfDay.fromDateTime(slot);
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: AppTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          DateFormat('HH:mm').format(slot),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Agendamento'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumo dos Serviços
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo dos Serviços',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...widget.services.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text('R\$ ${s.price.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'R\$ ${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Duração total estimada: $_totalDuration min',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (_selectedTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Horário previsto: ${_selectedTime!.format(context)} até ${TimeOfDay.fromDateTime(DateTime(0, 0, 0, _selectedTime!.hour, _selectedTime!.minute).add(Duration(minutes: _totalDuration))).format(context)}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Forma de Pagamento
            Text(
              'Forma de Pagamento',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPaymentSelection(),
            const SizedBox(height: 32),

            // Escolha de Horário
            Text(
              'Escolha o melhor horário',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPickerTile(
              title: 'Data',
              value: _selectedDate == null
                  ? 'Selecione o dia'
                  : DateFormat('dd/MM/yyyy').format(_selectedDate!),
              icon: Icons.calendar_today,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            _buildPickerTile(
              title: 'Horário',
              value: _selectedTime == null
                  ? 'Selecione o horário'
                  : _selectedTime!.format(context),
              icon: Icons.access_time,
              onTap: _pickTime,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isChecking ? null : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.primary.withValues(
                  alpha: 0.5,
                ),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppTheme.primary.withValues(alpha: 0.4),
              ),
              child: _isChecking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'CONFIRMAR AGENDAMENTO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _paymentMethod,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
          items: _paymentMethods.map((String method) {
            return DropdownMenuItem<String>(
              value: method,
              child: Row(
                children: [
                  Icon(
                    _getPaymentIcon(method),
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    method,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _paymentMethod = newValue);
            }
          },
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Dinheiro':
        return Icons.payments_outlined;
      case 'Débito':
        return Icons.credit_card_outlined;
      case 'Crédito':
        return Icons.credit_score_outlined;
      case 'Pix':
        return Icons.qr_code_scanner;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPickerTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBooking() async {
    debugPrint('Botão Confirmar Agendamento pressionado');
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma data.')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um horário.')),
      );
      return;
    }

    if (_selectedProfessional == null) {
      // Tenta carregar novamente se estiver nulo
      await _loadDefaultProfessional();
      if (_selectedProfessional == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nenhum profissional disponível. Por favor, contate o administrador.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isChecking = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel!;

      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      debugPrint('Dados para agendamento:');
      debugPrint('Data/Hora: $appointmentDateTime');
      debugPrint(
        'Profissional: ${_selectedProfessional?.name} (ID: ${_selectedProfessional?.id})',
      );
      debugPrint('Usuário: ${user.name} (ID: ${user.id})');

      final isAvailable = await _dbService.isTimeSlotAvailable(
        appointmentDateTime,
        _totalDuration,
        professionalId: _selectedProfessional!.id,
      );

      if (!mounted) return;

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este horário já está ocupado para este profissional. Por favor, escolha outro.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isChecking = false);
        return;
      }

      final appointment = AppointmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        userName: user.name,
        userPhone: user.phone,
        serviceId: widget.services.map((s) => s.id).join(','),
        serviceName: _serviceNames,
        dateTime: appointmentDateTime,
        status: 'pending',
        professionalId: _selectedProfessional!.id,
        professionalName: _selectedProfessional!.name,
        totalPrice: _totalPrice,
        durationInMinutes: _totalDuration,
        paymentMethod: _paymentMethod, // Adicionando o campo
      );

      // Log para depuração
      debugPrint('Tentando salvar agendamento: ${appointment.id}');

      await _dbService.addAppointment(appointment);

      // Agendar notificações locais
      try {
        await NotificationService().scheduleAppointmentNotifications(
          appointment,
        );
      } catch (e) {
        debugPrint('Erro ao agendar notificações: $e');
      }

      if (!mounted) return;

      // Mensagem personalizada de pagamento
      String paymentInfo = _paymentMethod;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text('Sucesso!', textAlign: TextAlign.center),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seu agendamento para $_serviceNames com ${_selectedProfessional!.name} foi realizado com sucesso para ${DateFormat('dd/MM/yyyy HH:mm').format(appointmentDateTime)}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payment,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pagamento: $paymentInfo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao realizar agendamento: $e')),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }
}
