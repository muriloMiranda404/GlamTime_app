class ProfessionalModel {
  final String id;
  final String name;
  final String photoUrl;
  final String specialty;
  final List<String> services; // IDs dos serviços que este profissional realiza
  final Map<String, List<String>> workingHours; // Ex: {"segunda": ["08:00", "18:00"]}
  final double commissionRate;
  final bool isActive;

  ProfessionalModel({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.specialty,
    required this.services,
    required this.workingHours,
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
      workingHours: Map<String, List<String>>.from(
        (map['workingHours'] ?? {}).map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }
}
