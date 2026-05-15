import 'dart:convert';

class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category; // 'Produtos', 'Aluguel', 'Energia', 'Materiais', 'Outros'

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      category: map['category'] ?? 'Outros',
    );
  }

  String toJson() => json.encode(toMap());

  factory ExpenseModel.fromJson(String source) => ExpenseModel.fromMap(json.decode(source));
}
