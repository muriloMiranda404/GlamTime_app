class AppointmentModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String serviceId;
  final String serviceName;
  final DateTime dateTime;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final bool isPaid;
  final String professionalId;
  final String professionalName;
  final double totalPrice;
  final int durationInMinutes;
  final String paymentMethod;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.serviceId,
    required this.serviceName,
    required this.dateTime,
    this.status = 'pending',
    this.isPaid = false,
    required this.professionalId,
    required this.professionalName,
    this.totalPrice = 0.0,
    this.durationInMinutes = 30,
    this.paymentMethod = 'Dinheiro',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'isPaid': isPaid,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'totalPrice': totalPrice,
      'durationInMinutes': durationInMinutes,
      'paymentMethod': paymentMethod,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'pending',
      isPaid: map['isPaid'] ?? false,
      professionalId: map['professionalId'] ?? '',
      professionalName: map['professionalName'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      durationInMinutes: map['durationInMinutes'] ?? 30,
      paymentMethod: map['paymentMethod'] ?? 'Dinheiro',
    );
  }
}
