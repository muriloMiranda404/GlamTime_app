import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import '../models/expense_model.dart';
import '../models/professional_model.dart';

class DatabaseService {
  FirebaseFirestore? get _firestore {
    if (FirebaseFirestore.instance == false) return null;
    return FirebaseFirestore.instance;
  }

  bool get isFirebaseAvailable => FirebaseFirestore.instance != false;

  // Coleções
  static const String _servicesColl = 'services';
  static const String _appointmentsColl = 'appointments';
  static const String _expensesColl = 'expenses';
  static const String _professionalsColl = 'professionals';

  // --- PROFISSIONAIS ---

  Stream<List<ProfessionalModel>> get professionals {
    final db = _firestore;
    if (db == null) return Stream.value([]);
    return db.collection(_professionalsColl).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProfessionalModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> addProfessional(ProfessionalModel professional) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection(_professionalsColl).add(professional.toMap());
  }

  Future<void> updateProfessional(ProfessionalModel professional) async {
    final db = _firestore;
    if (db == null) return;
    await db
        .collection(_professionalsColl)
        .doc(professional.id)
        .update(professional.toMap());
  }

  Future<void> deleteProfessional(String id) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection(_professionalsColl).doc(id).delete();
  }

  // --- VERIFICAÇÃO DE DISPONIBILIDADE (O CORAÇÃO DO SERVIDOR) ---

  Future<bool> isTimeSlotAvailable(
    DateTime dateTime,
    int duration, {
    String? professionalId,
  }) async {
    final db = _firestore;
    if (db == null)
      return true; // Se não tem Firebase, assume disponível (mock)

    // Definir o início e fim do dia para filtrar a busca no servidor
    final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Busca no SERVIDOR apenas agendamentos do dia escolhido que não foram cancelados
    final querySnapshot = await db
        .collection(_appointmentsColl)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .get();

    final appointments = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return AppointmentModel.fromMap(data, doc.id);
    }).toList();

    for (var appt in appointments) {
      if (appt.status == 'cancelled') continue;

      // Verifica se é o mesmo profissional
      if (professionalId != null && appt.professionalId != professionalId) {
        continue;
      }

      final apptEnd = appt.dateTime.add(
        Duration(minutes: appt.durationInMinutes),
      );
      final newEnd = dateTime.add(Duration(minutes: duration));

      // Lógica de sobreposição de horários (Interseção de intervalos)
      // Um conflito ocorre se o novo início for antes do fim do existente
      // E o início do existente for antes do novo fim.
      if (dateTime.isBefore(apptEnd) && appt.dateTime.isBefore(newEnd)) {
        return false; // Conflito detectado!
      }
    }
    return true; // Horário livre
  }

  // --- AGENDAMENTOS ---

  Stream<List<AppointmentModel>> getAppointments(String userId) {
    final db = _firestore;
    if (db == null) return Stream.value([]);
    return db
        .collection(_appointmentsColl)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<AppointmentModel>> get allAppointments {
    final db = _firestore;
    if (db == null) return Stream.value([]);
    return db.collection(_appointmentsColl).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addAppointment(AppointmentModel appt) async {
    final db = _firestore;
    if (db == null) return;

    // Antes de salvar, fazemos uma última checagem no servidor para garantir
    bool available = await isTimeSlotAvailable(
      appt.dateTime,
      appt.durationInMinutes,
      professionalId: appt.professionalId,
    );

    if (!available) {
      throw Exception('Este horário acabou de ser ocupado por outra pessoa!');
    }

    await db.collection(_appointmentsColl).add(appt.toMap());
  }

  // --- SERVIÇOS ---

  Stream<List<ServiceModel>> get services {
    final db = _firestore;
    if (db == null) return Stream.value([]);
    return db.collection(_servicesColl).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addService(ServiceModel service) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection(_servicesColl).add(service.toMap());
  }

  Future<void> updateService(ServiceModel service) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection(_servicesColl).doc(service.id).update(service.toMap());
  }

  Future<void> deleteService(String id) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection(_servicesColl).doc(id).delete();
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection(_appointmentsColl).doc(id).update({'status': status});
  }

  // --- FINANÇAS ---

  Stream<List<ExpenseModel>> get expenses {
    final db = _firestore;
    if (db == null) return Stream.value([]);
    return db.collection(_expensesColl).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection(_expensesColl).add(expense.toMap());
  }
}
