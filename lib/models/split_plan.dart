enum DistributionType {
  equal,
  custom,
}

enum RoundingMode {
  roundHalfUp,
  floor,
  ceil,
}

class SplitPlan {
  final String id;
  final double totalAmount;
  final DateTime startMonth;
  final int numberOfMonths;
  final DistributionType distributionType;
  final List<double>? customDistributions;
  final RoundingMode roundingMode;
  final List<String> generatedExpenseIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const SplitPlan({
    required this.id,
    required this.totalAmount,
    required this.startMonth,
    required this.numberOfMonths,
    required this.distributionType,
    this.customDistributions,
    this.roundingMode = RoundingMode.roundHalfUp,
    this.generatedExpenseIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SplitPlan.fromJson(Map<String, dynamic> json) {
    return SplitPlan(
      id: json['id'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      startMonth: DateTime.parse(json['startMonth'] as String),
      numberOfMonths: json['numberOfMonths'] as int,
      distributionType: DistributionType.values.firstWhere(
        (e) => e.name == json['distributionType'],
        orElse: () => DistributionType.equal,
      ),
      customDistributions: (json['customDistributions'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      roundingMode: RoundingMode.values.firstWhere(
        (e) => e.name == json['roundingMode'],
        orElse: () => RoundingMode.roundHalfUp,
      ),
      generatedExpenseIds: (json['generatedExpenseIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'startMonth': startMonth.toIso8601String(),
      'numberOfMonths': numberOfMonths,
      'distributionType': distributionType.name,
      'customDistributions': customDistributions,
      'roundingMode': roundingMode.name,
      'generatedExpenseIds': generatedExpenseIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Check if this split plan is deleted (soft delete)
  bool get isDeleted => deletedAt != null;

  /// Validate custom distributions
  bool get isValidCustomDistribution {
    if (distributionType != DistributionType.custom) return true;
    if (customDistributions == null) return false;
    if (customDistributions!.length != numberOfMonths) return false;
    
    final sum = customDistributions!.fold<double>(0, (a, b) => a + b);
    // Allow for small floating point errors (±0.01)
    return (sum - 1.0).abs() <= 0.01;
  }

  /// Get the distribution percentages for each month
  List<double> get distributions {
    if (distributionType == DistributionType.equal) {
      final equalShare = 1.0 / numberOfMonths;
      return List.filled(numberOfMonths, equalShare);
    } else {
      return customDistributions ?? [];
    }
  }

  /// Calculate the amount for each month
  List<double> calculateMonthlyAmounts() {
    final distributions = this.distributions;
    final amounts = <double>[];
    
    for (int i = 0; i < numberOfMonths; i++) {
      final baseAmount = totalAmount * distributions[i];
      amounts.add(_roundAmount(baseAmount));
    }
    
    // Handle rounding residual by adjusting the last month
    final totalCalculated = amounts.fold<double>(0, (a, b) => a + b);
    final residual = totalAmount - totalCalculated;
    
    if (residual.abs() > 0.001) {
      amounts[amounts.length - 1] += residual;
      amounts[amounts.length - 1] = _roundAmount(amounts[amounts.length - 1]);
    }
    
    return amounts;
  }

  /// Round amount based on rounding mode
  double _roundAmount(double amount) {
    switch (roundingMode) {
      case RoundingMode.roundHalfUp:
        return (amount * 100).round() / 100;
      case RoundingMode.floor:
        return (amount * 100).floor() / 100;
      case RoundingMode.ceil:
        return (amount * 100).ceil() / 100;
    }
  }

  /// Get the months covered by this split plan
  List<DateTime> get months {
    final months = <DateTime>[];
    for (int i = 0; i < numberOfMonths; i++) {
      final month = DateTime(startMonth.year, startMonth.month + i, 1);
      months.add(month);
    }
    return months;
  }

  /// Create a new split plan
  factory SplitPlan.create({
    required String id,
    required double totalAmount,
    required DateTime startMonth,
    required int numberOfMonths,
    required DistributionType distributionType,
    List<double>? customDistributions,
    RoundingMode roundingMode = RoundingMode.roundHalfUp,
  }) {
    final now = DateTime.now().toUtc();
    // Keep the original date - preserve the day of month for split expenses
    
    return SplitPlan(
      id: id,
      totalAmount: totalAmount,
      startMonth: startMonth,
      numberOfMonths: numberOfMonths,
      distributionType: distributionType,
      customDistributions: customDistributions,
      roundingMode: roundingMode,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a copy with updated fields
  SplitPlan copyWith({
    String? id,
    double? totalAmount,
    DateTime? startMonth,
    int? numberOfMonths,
    DistributionType? distributionType,
    List<double>? customDistributions,
    RoundingMode? roundingMode,
    List<String>? generatedExpenseIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SplitPlan(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      startMonth: startMonth ?? this.startMonth,
      numberOfMonths: numberOfMonths ?? this.numberOfMonths,
      distributionType: distributionType ?? this.distributionType,
      customDistributions: customDistributions ?? this.customDistributions,
      roundingMode: roundingMode ?? this.roundingMode,
      generatedExpenseIds: generatedExpenseIds ?? this.generatedExpenseIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Update the split plan
  SplitPlan update({
    double? totalAmount,
    DateTime? startMonth,
    int? numberOfMonths,
    DistributionType? distributionType,
    List<double>? customDistributions,
    RoundingMode? roundingMode,
  }) {
    return copyWith(
      totalAmount: totalAmount ?? this.totalAmount,
      startMonth: startMonth != null 
          ? DateTime(startMonth.year, startMonth.month, 1)
          : this.startMonth,
      numberOfMonths: numberOfMonths ?? this.numberOfMonths,
      distributionType: distributionType ?? this.distributionType,
      customDistributions: customDistributions ?? this.customDistributions,
      roundingMode: roundingMode ?? this.roundingMode,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Add generated expense ID
  SplitPlan addGeneratedExpense(String expenseId) {
    return copyWith(
      generatedExpenseIds: [...generatedExpenseIds, expenseId],
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Remove generated expense ID
  SplitPlan removeGeneratedExpense(String expenseId) {
    return copyWith(
      generatedExpenseIds: generatedExpenseIds.where((id) => id != expenseId).toList(),
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
