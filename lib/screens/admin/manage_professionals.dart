import 'package:flutter/material.dart';
import '../../models/professional_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class ManageProfessionals extends StatefulWidget {
  const ManageProfessionals({super.key});

  @override
  State<ManageProfessionals> createState() => _ManageProfessionalsState();
}

class _ManageProfessionalsState extends State<ManageProfessionals> {
  final _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Gerenciar Profissionais'),
      ),
      body: StreamBuilder<List<ProfessionalModel>>(
        stream: _dbService.professionals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final professionals = snapshot.data ?? [];
          if (professionals.isEmpty) {
            return const Center(
              child: Text('Nenhum profissional cadastrado.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final p = professionals[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
                    child: p.photoUrl.isEmpty ? const Icon(Icons.person, color: AppTheme.primary) : null,
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.specialty),
                  trailing: Switch(
                    value: p.isActive,
                    onChanged: (val) {
                      _dbService.updateProfessional(ProfessionalModel(
                        id: p.id,
                        name: p.name,
                        photoUrl: p.photoUrl,
                        specialty: p.specialty,
                        services: p.services,
                        workingHours: p.workingHours,
                        isActive: val,
                      ));
                    },
                    activeThumbColor: AppTheme.primary,
                  ),
                  onTap: () => _showProfessionalDialog(p),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProfessionalDialog(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showProfessionalDialog([ProfessionalModel? professional]) {
    final nameController = TextEditingController(text: professional?.name);
    final specialtyController = TextEditingController(text: professional?.specialty);
    final photoController = TextEditingController(text: professional?.photoUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(professional == null ? 'Novo Profissional' : 'Editar Profissional'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specialtyController,
                decoration: const InputDecoration(labelText: 'Especialidade'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: photoController,
                decoration: const InputDecoration(labelText: 'URL da Foto'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newProfessional = ProfessionalModel(
                  id: professional?.id ?? '',
                  name: nameController.text,
                  specialty: specialtyController.text,
                  photoUrl: photoController.text,
                  services: professional?.services ?? [],
                  workingHours: professional?.workingHours ?? {
                    'segunda': ['08:00', '18:00'],
                    'terca': ['08:00', '18:00'],
                    'quarta': ['08:00', '18:00'],
                    'quinta': ['08:00', '18:00'],
                    'sexta': ['08:00', '18:00'],
                    'sabado': ['08:00', '14:00'],
                  },
                );
                if (professional == null) {
                  _dbService.addProfessional(newProfessional);
                } else {
                  _dbService.updateProfessional(newProfessional);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }
}
