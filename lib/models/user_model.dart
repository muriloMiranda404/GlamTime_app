class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'isAdmin': isAdmin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}
