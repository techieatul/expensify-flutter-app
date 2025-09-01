class Expense {
  final String id;
  final double amount;
  final String currencyCode;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String? note;
  final String? splitPlanId;
  final bool isSplitParent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Expense({
    required this.id,
    required this.amount,
    this.currencyCode = 'USD',
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.note,
    this.splitPlanId,
    this.isSplitParent = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      splitPlanId: json['splitPlanId'] as String?,
      isSplitParent: json['isSplitParent'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currencyCode': currencyCode,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
      'note': note,
      'splitPlanId': splitPlanId,
      'isSplitParent': isSplitParent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Check if this expense is deleted (soft delete)
  bool get isDeleted => deletedAt != null;

  /// Check if this expense should be included in totals
  /// Split parent records are virtual and not counted
  bool get shouldIncludeInTotals => !isSplitParent && !isDeleted;

  /// Get the month key for grouping expenses (YYYY-MM format)
  String get monthKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Create a copy for editing
  Expense copyWith({
    String? id,
    double? amount,
    String? currencyCode,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    String? note,
    String? splitPlanId,
    bool? isSplitParent,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      date: date ?? this.date,
      note: note ?? this.note,
      splitPlanId: splitPlanId ?? this.splitPlanId,
      isSplitParent: isSplitParent ?? this.isSplitParent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Create a new expense
  factory Expense.create({
    required String id,
    required double amount,
    required String categoryId,
    required String categoryName,
    required DateTime date,
    String? note,
    String? splitPlanId,
    bool isSplitParent = false,
    String currencyCode = 'USD',
  }) {
    final now = DateTime.now().toUtc();
    return Expense(
      id: id,
      amount: amount,
      currencyCode: currencyCode,
      categoryId: categoryId,
      categoryName: categoryName,
      date: date,
      note: note,
      splitPlanId: splitPlanId,
      isSplitParent: isSplitParent,
      createdAt: now,
      updatedAt: now,
    );
  }
}
