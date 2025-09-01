import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import 'expense_service.dart';

/// Service for managing split expenses across multiple months
class SplitService {
  final ExpenseService _expenseService;
  late Box _splitPlansBox;

  SplitService(this._expenseService) {
    _splitPlansBox = Hive.box(AppConstants.splitPlansBox);
  }

  /// Create a split expense plan and generate individual expenses
  Future<SplitPlan> createSplitExpense({
    required SplitPlan splitPlan,
    required String categoryId,
    required String categoryName,
    String? note,
  }) async {
    // Calculate the split amounts
    final splitAmounts = calculateSplit(splitPlan);
    
    // Create individual expenses for each month
    final generatedExpenseIds = <String>[];
    
    for (int i = 0; i < splitAmounts.length; i++) {
      final monthDate = _calculateSplitDate(splitPlan.startMonth, i);
      
      final expense = await _expenseService.addExpense(
        amount: splitAmounts[i],
        categoryId: categoryId,
        categoryName: categoryName,
        date: monthDate,
        note: note != null ? '$note (Split ${i + 1}/${splitAmounts.length})' : 'Split ${i + 1}/${splitAmounts.length}',
        splitPlanId: splitPlan.id,
        isSplitParent: i == 0, // First expense is the parent
      );
      
      generatedExpenseIds.add(expense.id);
    }
    
    // Update the split plan with generated expense IDs
    final updatedSplitPlan = splitPlan.copyWith(
      generatedExpenseIds: generatedExpenseIds,
    );
    
    // Save the split plan to Hive
    await _splitPlansBox.put(updatedSplitPlan.id, updatedSplitPlan.toJson());
    
    return updatedSplitPlan;
  }

  /// Update an existing expense by splitting it across multiple months
  /// The original expense becomes the first split, additional expenses are created for remaining months
  Future<SplitPlan> updateExpenseWithSplit({
    required String existingExpenseId,
    required SplitPlan splitPlan,
    required String categoryId,
    required String categoryName,
    String? note,
  }) async {
    // Calculate the split amounts
    final splitAmounts = calculateSplit(splitPlan);
    
    // Get the existing expense
    final existingExpense = _expenseService.getExpenseById(existingExpenseId);
    if (existingExpense == null) {
      throw Exception('Existing expense not found');
    }
    
    final generatedExpenseIds = <String>[];
    
    for (int i = 0; i < splitAmounts.length; i++) {
      final monthDate = _calculateSplitDate(splitPlan.startMonth, i);
      
      if (i == 0) {
        // Update the existing expense with the first split amount
        await _expenseService.updateExpense(
          existingExpenseId,
          amount: splitAmounts[i],
          categoryId: categoryId,
          categoryName: categoryName,
          date: monthDate,
          note: note != null ? '$note (Split ${i + 1}/${splitAmounts.length})' : 'Split ${i + 1}/${splitAmounts.length}',
          splitPlanId: splitPlan.id,
          isSplitParent: true, // First expense is the parent
        );
        generatedExpenseIds.add(existingExpenseId);
      } else {
        // Create new expenses for remaining months
        final expense = await _expenseService.addExpense(
          amount: splitAmounts[i],
          categoryId: categoryId,
          categoryName: categoryName,
          date: monthDate,
          note: note != null ? '$note (Split ${i + 1}/${splitAmounts.length})' : 'Split ${i + 1}/${splitAmounts.length}',
          splitPlanId: splitPlan.id,
          isSplitParent: false, // Only first expense is the parent
        );
        generatedExpenseIds.add(expense.id);
      }
    }
    
    // Update the split plan with generated expense IDs
    final updatedSplitPlan = splitPlan.copyWith(
      generatedExpenseIds: generatedExpenseIds,
    );
    
    // Save the split plan to Hive
    await _splitPlansBox.put(updatedSplitPlan.id, updatedSplitPlan.toJson());
    
    return updatedSplitPlan;
  }

  /// Calculate split amounts based on the split plan
  List<double> calculateSplit(SplitPlan splitPlan) {
    switch (splitPlan.distributionType) {
      case DistributionType.equal:
        return _calculateEqualSplit(splitPlan);
      case DistributionType.custom:
        return _calculateCustomSplit(splitPlan);
    }
  }

  /// Preview split amounts without creating expenses
  List<double> previewSplit(SplitPlan splitPlan) {
    return calculateSplit(splitPlan);
  }

  /// Calculate equal distribution
  List<double> _calculateEqualSplit(SplitPlan splitPlan) {
    final baseAmount = splitPlan.totalAmount / splitPlan.numberOfMonths;
    final amounts = List.filled(splitPlan.numberOfMonths, baseAmount);
    
    // Handle rounding
    return _applyRounding(amounts, splitPlan.totalAmount, splitPlan.roundingMode);
  }

  /// Calculate custom distribution
  List<double> _calculateCustomSplit(SplitPlan splitPlan) {
    if (splitPlan.customDistributions == null || 
        splitPlan.customDistributions!.length != splitPlan.numberOfMonths) {
      throw Exception('Invalid custom distributions');
    }
    
    return List.from(splitPlan.customDistributions!);
  }

  /// Apply rounding mode to ensure total matches exactly
  List<double> _applyRounding(List<double> amounts, double totalAmount, RoundingMode roundingMode) {
    List<double> roundedAmounts;
    
    switch (roundingMode) {
      case RoundingMode.roundHalfUp:
        roundedAmounts = amounts.map((amount) => _roundToNearest(amount)).toList();
        break;
      case RoundingMode.ceil:
        roundedAmounts = amounts.map((amount) => amount.ceilToDouble()).toList();
        break;
      case RoundingMode.floor:
        roundedAmounts = amounts.map((amount) => amount.floorToDouble()).toList();
        break;
    }
    
    // Adjust for rounding differences
    final roundedTotal = roundedAmounts.fold<double>(0, (sum, amount) => sum + amount);
    final difference = totalAmount - roundedTotal;
    
    if (difference.abs() > 0.01) {
      // Distribute the difference to the first expense
      roundedAmounts[0] += difference;
    }
    
    return roundedAmounts;
  }

  /// Round to nearest cent
  double _roundToNearest(double amount) {
    return (amount * 100).round() / 100;
  }

  /// Calculate the correct date for a split expense, preserving the day of month
  /// and handling edge cases like Feb 31 -> Feb 28/29, Sep 31 -> Sep 30
  DateTime _calculateSplitDate(DateTime startDate, int monthOffset) {
    final targetYear = startDate.year;
    final targetMonth = startDate.month + monthOffset;
    final targetDay = startDate.day;
    
    // Handle month overflow (e.g., month 13 becomes year+1, month 1)
    final adjustedYear = targetYear + ((targetMonth - 1) ~/ 12);
    final adjustedMonth = ((targetMonth - 1) % 12) + 1;
    
    // Handle day overflow (e.g., Feb 31 becomes Feb 28/29, Sep 31 becomes Sep 30)
    final daysInMonth = DateTime(adjustedYear, adjustedMonth + 1, 0).day;
    final adjustedDay = targetDay > daysInMonth ? daysInMonth : targetDay;
    
    return DateTime(adjustedYear, adjustedMonth, adjustedDay);
  }

  /// Get all split plans
  List<SplitPlan> getAllSplitPlans() {
    final splitPlansData = _splitPlansBox.values.toList();
    return splitPlansData
        .map((data) => SplitPlan.fromJson(Map<String, dynamic>.from(data)))
        .where((splitPlan) => !splitPlan.isDeleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get split plan by ID
  SplitPlan? getSplitPlanById(String splitPlanId) {
    try {
      final splitPlanData = _splitPlansBox.get(splitPlanId);
      if (splitPlanData == null) return null;
      
      final splitPlan = SplitPlan.fromJson(Map<String, dynamic>.from(splitPlanData));
      return splitPlan.isDeleted ? null : splitPlan;
    } catch (e) {
      return null;
    }
  }

  /// Get expenses for a split plan
  List<Expense> getExpensesForSplitPlan(String splitPlanId) {
    return _expenseService.getExpensesBySplitPlan(splitPlanId);
  }

  /// Update a split plan
  Future<SplitPlan> updateSplitPlan(
    String splitPlanId, {
    double? totalAmount,
    DateTime? startMonth,
    int? numberOfMonths,
    DistributionType? distributionType,
    List<double>? customDistributions,
    RoundingMode? roundingMode,
  }) async {
    final existingSplitPlan = getSplitPlanById(splitPlanId);
    if (existingSplitPlan == null) {
      throw Exception('Split plan not found');
    }

    final updatedSplitPlan = existingSplitPlan.update(
      totalAmount: totalAmount,
      startMonth: startMonth,
      numberOfMonths: numberOfMonths,
      distributionType: distributionType,
      customDistributions: customDistributions,
      roundingMode: roundingMode,
    );

    await _splitPlansBox.put(splitPlanId, updatedSplitPlan.toJson());
    return updatedSplitPlan;
  }

  /// Delete a split plan and its associated expenses
  Future<void> deleteSplitPlan(String splitPlanId) async {
    final splitPlan = getSplitPlanById(splitPlanId);
    if (splitPlan == null) {
      throw Exception('Split plan not found');
    }

    // Delete all associated expenses
    for (final expenseId in splitPlan.generatedExpenseIds) {
      try {
        await _expenseService.deleteExpense(expenseId);
      } catch (e) {
        // Continue deleting other expenses even if one fails
      }
    }

    // Soft delete the split plan
    final deletedSplitPlan = splitPlan.copyWith(
      deletedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    await _splitPlansBox.put(splitPlanId, deletedSplitPlan.toJson());
  }

  /// Restore a deleted split plan
  Future<SplitPlan> restoreSplitPlan(String splitPlanId) async {
    final splitPlanData = _splitPlansBox.get(splitPlanId);
    if (splitPlanData == null) {
      throw Exception('Split plan not found');
    }

    final splitPlan = SplitPlan.fromJson(Map<String, dynamic>.from(splitPlanData));
    if (!splitPlan.isDeleted) {
      throw Exception('Split plan is not deleted');
    }

    final restoredSplitPlan = splitPlan.copyWith(
      deletedAt: null,
      updatedAt: DateTime.now().toUtc(),
    );

    await _splitPlansBox.put(splitPlanId, restoredSplitPlan.toJson());
    return restoredSplitPlan;
  }

  /// Get split plans for a date range
  List<SplitPlan> getSplitPlansForDateRange(DateTime startDate, DateTime endDate) {
    return getAllSplitPlans()
        .where((splitPlan) =>
            splitPlan.startMonth.isAfter(startDate.subtract(const Duration(days: 1))) &&
            splitPlan.startMonth.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  /// Get monthly split plan statistics
  Map<String, int> getMonthlySplitPlanStats() {
    final splitPlans = getAllSplitPlans();
    final Map<String, int> monthlyStats = {};

    for (final splitPlan in splitPlans) {
      final monthKey = DateFormat('yyyy-MM').format(splitPlan.startMonth);
      monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
    }

    return monthlyStats;
  }

  /// Clear all split plans (for testing/reset)
  Future<void> clearAllSplitPlans() async {
    await _splitPlansBox.clear();
  }

  /// Validate split plan data
  bool validateSplitPlan(SplitPlan splitPlan) {
    // Check basic constraints
    if (splitPlan.totalAmount <= 0) return false;
    if (splitPlan.numberOfMonths < 2) return false;
    if (splitPlan.numberOfMonths > 12) return false;

    // Validate custom distributions if present
    if (splitPlan.distributionType == DistributionType.custom) {
      if (splitPlan.customDistributions == null) return false;
      if (splitPlan.customDistributions!.length != splitPlan.numberOfMonths) return false;
      
      final customTotal = splitPlan.customDistributions!.fold<double>(0, (sum, amount) => sum + amount);
      if ((customTotal - splitPlan.totalAmount).abs() > 0.01) return false;
    }

    return true;
  }

  /// Get split plan summary
  Map<String, dynamic> getSplitPlanSummary(String splitPlanId) {
    final splitPlan = getSplitPlanById(splitPlanId);
    if (splitPlan == null) return {};

    final expenses = getExpensesForSplitPlan(splitPlanId);
    final splitAmounts = calculateSplit(splitPlan);

    return {
      'splitPlan': splitPlan,
      'expenses': expenses,
      'splitAmounts': splitAmounts,
      'totalExpenses': expenses.length,
      'completedExpenses': expenses.where((e) => !e.isDeleted).length,
      'totalAmount': splitPlan.totalAmount,
      'actualTotal': expenses.fold<double>(0, (sum, expense) => sum + expense.amount),
    };
  }
}