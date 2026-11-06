import 'package:hurghada_winners/features/expenses/domain/entities/expense_entity.dart';

class ExpenseModel {
  final String id;
  final String academyId;
  final String name;
  final String? description;
  final double amount;
  final String date;
  final String category;

  const ExpenseModel({
    required this.id,
    required this.academyId,
    required this.name,
    this.description,
    required this.amount,
    required this.date,
    required this.category,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['_id'] as String,
        academyId: json['academyId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        amount: (json['amount'] as num).toDouble(),
        date: json['date'] as String,
        category: json['category'] as String,
      );

  ExpenseEntity toEntity() => ExpenseEntity(
        id: id,
        academyId: academyId,
        name: name,
        description: description,
        amount: amount,
        date: date,
        category: category,
      );
}
