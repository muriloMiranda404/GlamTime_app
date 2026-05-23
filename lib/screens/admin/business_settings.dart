import 'package:flutter/material.dart';
import '../../models/professional_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class BusinessSettings extends StatefulWidget {
  const BusinessSettings({super.key});

  @override
  State<BusinessSettings> createState() => _BusinessSettingsState();
}

class _BusinessSettingsState extends State<BusinessSettings> {
  final _dbService = DatabaseService();
  ProfessionalModel? _professional;
  bool _isLoading = true;

  final List<String> _daysOfWeek = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final professionals = await _dbService.professionals.first;
    if (professionals.isNotEmpty) {
      setState(() {
        _professional = professionals.first;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_professional == null) return;
    await _dbService.updateProfessional(_professional!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    }
  }

  Future<void> _createInitialProfessional() async {
    setState(() => _isLoading = true);
    final newProf = ProfessionalModel(
      id: 'admin_prof',
      name: 'Minha Agenda',
      photoUrl: '',
      specialty: 'Geral',
      services: [],
      workingHours: {
        '1': {'isOpen': true, 'start': '08:00', 'end': '18:00'},
        '2': {'isOpen': true, 'start': '08:00', 'end': '18:00'},
        '3': {'isOpen': true, 'start': '08:00', 'end': '18:00'},
        '4': {'isOpen': true, 'start': '08:00', 'end': '18:00'},
        '5': {'isOpen': true, 'start': '08:00', 'end': '18:00'},
        '6': {'isOpen': true, 'start': '08:00', 'end': '18:00'},
        '7': {'isOpen': false, 'start': '08:00', 'end': '18:00'},
      },
      slotIntervalMinutes: 100,
    );

    await _dbService.addProfessional(newProf);
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_professional == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configurações')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_outlined, size: 64, color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text('Nenhum perfil profissional encontrado.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createInitialProfessional,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('CRIAR MEU PERFIL AGORA', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Horário'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            _buildIntervalSetting(),
            const SizedBox(height: 24),
            const Text(
              'Horários de Trabalho',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(7, (index) => _buildDayToggle(index + 1)),
          ],
        ),
      ),
    )
    );
  }

  Widget _buildIntervalSetting() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Intervalo entre Agendamentos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<int>(
                    value: _professional!.slotIntervalMinutes,
                    isExpanded: true,
                    items: [30, 60, 90, 100, 120].map((int value) {
                      final hours = value ~/ 60;
                      final minutes = value % 60;
                      final label = hours > 0 
                          ? '${hours}h${minutes > 0 ? ' ${minutes}min' : ''}' 
                          : '${minutes}min';
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _professional = ProfessionalModel(
                            id: _professional!.id,
                            name: _professional!.name,
                            photoUrl: _professional!.photoUrl,
                            specialty: _professional!.specialty,
                            services: _professional!.services,
                            workingHours: _professional!.workingHours,
                            slotIntervalMinutes: val,
                            commissionRate: _professional!.commissionRate,
                            isActive: _professional!.isActive,
                          );
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayToggle(int dayIndex) {
    final dayKey = dayIndex.toString();
    final dayData = _professional!.workingHours[dayKey] ?? {
      'isOpen': true,
      'start': '08:00',
      'end': '18:00',
    };
    final bool isOpen = dayData['isOpen'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  _daysOfWeek[dayIndex - 1],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Switch(
                  value: isOpen,
                  onChanged: (val) {
                    final newHours = Map<String, dynamic>.from(_professional!.workingHours);
                    newHours[dayKey] = {
                      ...dayData,
                      'isOpen': val,
                    };
                    setState(() {
                      _professional = ProfessionalModel(
                        id: _professional!.id,
                        name: _professional!.name,
                        photoUrl: _professional!.photoUrl,
                        specialty: _professional!.specialty,
                        services: _professional!.services,
                        workingHours: newHours,
                        slotIntervalMinutes: _professional!.slotIntervalMinutes,
                        commissionRate: _professional!.commissionRate,
                        isActive: _professional!.isActive,
                      );
                    });
                  },
                ),
              ],
            ),
            if (isOpen)
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      'Início',
                      dayData['start'],
                      (time) => _updateDayTime(dayKey, 'start', time),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      'Fim',
                      dayData['end'],
                      (time) => _updateDayTime(dayKey, 'end', time),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, String time, Function(String) onTimePicked) {
    return InkWell(
      onTap: () async {
        final parts = time.split(':');
        final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final picked = await showTimePicker(context: context, initialTime: initialTime);
        if (picked != null) {
          final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimePicked(formatted);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateDayTime(String dayKey, String field, String time) {
    final newHours = Map<String, dynamic>.from(_professional!.workingHours);
    final dayData = Map<String, dynamic>.from(newHours[dayKey] ?? {});
    dayData[field] = time;
    newHours[dayKey] = dayData;
    setState(() {
      _professional = ProfessionalModel(
        id: _professional!.id,
        name: _professional!.name,
        photoUrl: _professional!.photoUrl,
        specialty: _professional!.specialty,
        services: _professional!.services,
        workingHours: newHours,
        slotIntervalMinutes: _professional!.slotIntervalMinutes,
        commissionRate: _professional!.commissionRate,
        isActive: _professional!.isActive,
      );
    });
  }
}
