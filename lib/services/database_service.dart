import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import '../models/expense_model.dart';
import '../models/professional_model.dart';

class DatabaseService {

  static bool _firebaseInitialized = true;

  static void markFirebaseInitialized(){
    _firebaseInitialized = true;
  }

  FirebaseFirestore? get _firestore {
    return FirebaseFirestore.instance;
  }

  bool get isFirebaseAvailable => true;

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
    await db
        .collection(_professionalsColl)
        .doc(professional.id)
        .set(professional.toMap());
  }

  Future<void> updateProfessional(ProfessionalModel professional) async {
    final db = _firestore;
    if (db == null) return;
    // Usamos 'set' com 'merge: true' em vez de 'update'
    // Isso garante que se o documento não existir por algum motivo, ele será criado
    await db
        .collection(_professionalsColl)
        .doc(professional.id)
        .set(professional.toMap(), SetOptions(merge: true));
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
    if (db == null) return true;

    final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final querySnapshot = await db
        .collection(_appointmentsColl)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .get();

    final appointments = querySnapshot.docs.map((doc) {
      return AppointmentModel.fromMap(doc.data(), doc.id);
    }).toList();

    // O fim do novo agendamento que se deseja fazer
    final newStart = dateTime;
    final newEnd = dateTime.add(Duration(minutes: duration));

    for (var appt in appointments) {
      if (appt.status == 'cancelled') continue;
      if (professionalId != null && appt.professionalId != professionalId) continue;

      final apptStart = appt.dateTime;
      final apptEnd = appt.dateTime.add(Duration(minutes: appt.durationInMinutes));

      // Lógica de colisão:
      // Se o novo agendamento começa antes do fim do existente
      // E o novo agendamento termina depois do início do existente
      if (newStart.isBefore(apptEnd) && newEnd.isAfter(apptStart)) {
        print("CONFLITO DETECTADO: Novo ($newStart - $newEnd) colide com Existente ($apptStart - $apptEnd)");
        return false;
      }
    }
    return true;
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

    // Criamos o documento e deixamos o Firestore gerar o ID real
    final docRef = await db.collection(_appointmentsColl).add(appt.toMap());
    print("DATABASE_SERVICE: Novo agendamento criado com ID: ${docRef.id}");
  }

  // --- SERVIÇOS ---

  Stream<List<ServiceModel>> get services {
    final db = _firestore;
    if (db == null) return Stream.value([]);
    return db.collection(_servicesColl).snapshots().map((snapshot) {
      print("DATABASE_SERVICE: Recebidos ${snapshot.docs.length} documentos da coleção 'services'");
      for (var doc in snapshot.docs) {
        print("DATABASE_SERVICE: Doc ID: ${doc.id}, Data: ${doc.data()}");
      }
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
    
    Map<String, dynamic> updates = {'status': status};
    // Se o status for 'completed', marcamos como pago automaticamente por padrão
    if (status == 'completed') {
      updates['isPaid'] = true;
    }
    
    await db.collection(_appointmentsColl).doc(id).update(updates);
  }

  Future<void> updatePaymentStatus(String id, bool isPaid) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection(_appointmentsColl).doc(id).update({'isPaid': isPaid});
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
