class ProfessionalModel {
  final String id;
  final String name;
  final String photoUrl;
  final String specialty;
  final List<String> services; // IDs dos serviços que este profissional realiza
  final Map<String, dynamic> workingHours; // Ex: {"1": {"start": "08:00", "end": "18:00", "isOpen": true}}
  final int slotIntervalMinutes; // Intervalo entre agendamentos (ex: 100 para 1h40)
  final double commissionRate;
  final bool isActive;

  ProfessionalModel({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.specialty,
    required this.services,
    required this.workingHours,
    this.slotIntervalMinutes = 100, // Padrão 1h40
    this.commissionRate = 0.0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'specialty': specialty,
      'services': services,
      'workingHours': workingHours,
      'slotIntervalMinutes': slotIntervalMinutes,
      'commissionRate': commissionRate,
      'isActive': isActive,
    };
  }

  factory ProfessionalModel.fromMap(Map<String, dynamic> map) {
    return ProfessionalModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      specialty: map['specialty'] ?? '',
      services: List<String>.from(map['services'] ?? []),
      workingHours: Map<String, dynamic>.from(map['workingHours'] ?? {}),
      slotIntervalMinutes: map['slotIntervalMinutes'] ?? 100,
      commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }
}
