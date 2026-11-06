import 'package:equatable/equatable.dart';

const List<String> expenseCategories = [
  'rent', 'electricity', 'water', 'sports_equipment',
  'salaries', 'maintenance', 'transport', 'other',
];

const Map<String, String> expenseCategoryLabels = {
  'rent': 'إيجار',
  'electricity': 'كهرباء',
  'water': 'مياه',
  'sports_equipment': 'أدوات رياضية',
  'salaries': 'مرتبات',
  'maintenance': 'صيانة',
  'transport': 'انتقالات',
  'other': 'أخرى',
};

class ExpenseEntity extends Equatable {
  final String id;
  final String academyId;
  final String name;
  final String? description;
  final double amount;
  final String date; // 'YYYY-MM-DD'
  final String category;

  const ExpenseEntity({
    required this.id,
    required this.academyId,
    required this.name,
    this.description,
    required this.amount,
    required this.date,
    required this.category,
  });

  String get categoryLabel => expenseCategoryLabels[category] ?? category;

  @override
  List<Object?> get props => [id, academyId, name, description, amount, date, category];
}

class ExpenseReportData extends Equatable {
  final double totalAmount;
  final int totalCount;
  final Map<String, ({double total, int count})> byCategory;

  const ExpenseReportData({
    required this.totalAmount,
    required this.totalCount,
    required this.byCategory,
  });

  @override
  List<Object?> get props => [totalAmount, totalCount, byCategory];
}
