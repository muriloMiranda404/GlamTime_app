class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationInMinutes;
  final String category; // 'Unhas', 'Cabelo', 'Sobrancelha', 'Estética', 'Outros'
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationInMinutes,
    this.category = 'Outros',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'durationInMinutes': durationInMinutes,
      'category': category,
      'isActive': isActive,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      durationInMinutes: map['durationInMinutes'] ?? 0,
      category: map['category'] ?? 'Outros',
      isActive: map['isActive'] ?? true,
    );
  }
}
