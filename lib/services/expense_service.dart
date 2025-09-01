import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/extensions.dart';
import '../utils/constants.dart';

/// Service for managing expenses
class ExpenseService {
  static const _uuid = Uuid();
  
  // Hive box for storing expenses
  Box get _expensesBox => Hive.box(AppConstants.expensesBox);
  
  /// Get all expenses
  List<Expense> getAllExpenses() {
    final expensesData = _expensesBox.values.toList();
    final expenses = expensesData
        .map((data) => Expense.fromJson(Map<String, dynamic>.from(data)))
        .where((expense) => !expense.isDeleted)
        .toList();
    return expenses;
  }
  
  /// Get expenses for a specific month
  List<Expense> getExpensesForMonth(DateTime month) {
    final monthKey = month.monthKey;
    final allExpenses = getAllExpenses();
    return allExpenses
        .where((expense) => expense.date.monthKey == monthKey)
        .toList()
      ..sort((a, b) {
        // Sort by date descending, then by createdAt descending for stability
        final dateComparison = b.date.compareTo(a.date);
        if (dateComparison != 0) return dateComparison;
        return b.createdAt.compareTo(a.createdAt);
      });
  }
  
  /// Get expenses for a date range
  List<Expense> getExpensesForDateRange(DateTime startDate, DateTime endDate) {
    final allExpenses = getAllExpenses();
    return allExpenses
        .where((expense) => 
            expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  /// Get total expenses for a month
  double getTotalForMonth(DateTime month) {
    return getExpensesForMonth(month)
        .where((expense) => expense.deletedAt == null) // Only include non-deleted expenses
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }
  
  /// Get total expenses for a date range
  double getTotalForDateRange(DateTime startDate, DateTime endDate) {
    return getExpensesForDateRange(startDate, endDate)
        .where((expense) => expense.deletedAt == null) // Only include non-deleted expenses
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }
  
  /// Get expense count for a month
  int getCountForMonth(DateTime month) {
    return getExpensesForMonth(month)
        .where((expense) => expense.deletedAt == null) // Only include non-deleted expenses
        .length;
  }
  
  /// Get expenses by category for a date range
  Map<String, List<Expense>> getExpensesByCategory(DateTime startDate, DateTime endDate) {
    final expenses = getExpensesForDateRange(startDate, endDate)
        .where((expense) => expense.deletedAt == null) // Only include non-deleted expenses
        .toList();
    
    final Map<String, List<Expense>> grouped = {};
    for (final expense in expenses) {
      grouped.putIfAbsent(expense.categoryId, () => []).add(expense);
    }
    
    return grouped;
  }
  
  /// Get category totals for a date range
  Map<String, double> getCategoryTotals(DateTime startDate, DateTime endDate) {
    final grouped = getExpensesByCategory(startDate, endDate);
    final Map<String, double> totals = {};
    
    for (final entry in grouped.entries) {
      totals[entry.key] = entry.value.fold<double>(0, (sum, expense) => sum + expense.amount);
    }
    
    return totals;
  }
  
  /// Add a new expense
  Future<Expense> addExpense({
    required double amount,
    required String categoryId,
    required String categoryName,
    required DateTime date,
    String? note,
    String? splitPlanId,
    bool isSplitParent = false,
  }) async {
    final expense = Expense.create(
      id: _uuid.v4(),
      amount: amount.rounded,
      categoryId: categoryId,
      categoryName: categoryName,
      date: date,
      note: note?.trim(),
      splitPlanId: splitPlanId,
      isSplitParent: isSplitParent,
    );
    
    // Save to Hive
    await _expensesBox.put(expense.id, expense.toJson());
    
    return expense;
  }
  
  /// Update an existing expense
  Future<Expense> updateExpense(
    String expenseId, {
    double? amount,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    String? note,
    String? splitPlanId,
    bool? isSplitParent,
  }) async {
    final expenseData = _expensesBox.get(expenseId);
    if (expenseData == null) {
      throw Exception('Expense not found');
    }
    
    final expense = Expense.fromJson(Map<String, dynamic>.from(expenseData));
    if (expense.isDeleted) {
      throw Exception('Expense not found');
    }
    
    final updatedExpense = expense.copyWith(
      amount: amount?.rounded,
      categoryId: categoryId,
      categoryName: categoryName,
      date: date,
      note: note?.trim(),
      splitPlanId: splitPlanId,
      isSplitParent: isSplitParent,
      updatedAt: DateTime.now().toUtc(),
    );
    
    // Save to Hive
    await _expensesBox.put(expenseId, updatedExpense.toJson());
    
    return updatedExpense;
  }
  
  /// Delete an expense (soft delete)
  Future<void> deleteExpense(String expenseId) async {
    final expenseData = _expensesBox.get(expenseId);
    if (expenseData == null) {
      throw Exception('Expense not found');
    }
    
    final expense = Expense.fromJson(Map<String, dynamic>.from(expenseData));
    if (expense.isDeleted) {
      throw Exception('Expense not found');
    }
    
    final deletedExpense = expense.copyWith(
      deletedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    
    // Save to Hive
    await _expensesBox.put(expenseId, deletedExpense.toJson());
  }
  
  /// Permanently delete an expense
  Future<void> permanentlyDeleteExpense(String expenseId) async {
    await _expensesBox.delete(expenseId);
  }
  
  /// Restore a deleted expense
  Future<Expense> restoreExpense(String expenseId) async {
    final expenseData = _expensesBox.get(expenseId);
    if (expenseData == null) {
      throw Exception('Deleted expense not found');
    }
    
    final expense = Expense.fromJson(Map<String, dynamic>.from(expenseData));
    if (!expense.isDeleted) {
      throw Exception('Expense is not deleted');
    }
    
    final restoredExpense = expense.copyWith(
      deletedAt: null,
      updatedAt: DateTime.now().toUtc(),
    );
    
    await _expensesBox.put(expenseId, restoredExpense.toJson());
    
    return restoredExpense;
  }
  
  /// Get an expense by ID
  Expense? getExpenseById(String expenseId) {
    try {
      final expenseData = _expensesBox.get(expenseId);
      if (expenseData == null) return null;
      
      final expense = Expense.fromJson(Map<String, dynamic>.from(expenseData));
      return expense.isDeleted ? null : expense;
    } catch (e) {
      return null;
    }
  }
  
  /// Get expenses by split plan ID
  List<Expense> getExpensesBySplitPlan(String splitPlanId) {
    final allExpenses = getAllExpenses();
    return allExpenses
        .where((expense) => expense.splitPlanId == splitPlanId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  /// Delete all expenses for a split plan
  Future<void> deleteExpensesForSplitPlan(String splitPlanId) async {
    final expensesToDelete = getExpensesBySplitPlan(splitPlanId);
    
    for (final expense in expensesToDelete) {
      await deleteExpense(expense.id);
    }
  }
  
  /// Get monthly totals for a year
  Map<String, double> getMonthlyTotalsForYear(int year) {
    final Map<String, double> monthlyTotals = {};
    
    for (int month = 1; month <= 12; month++) {
      final monthDate = DateTime(year, month, 1);
      final total = getTotalForMonth(monthDate);
      monthlyTotals[monthDate.monthKey] = total;
    }
    
    return monthlyTotals;
  }
  

  /// Search expenses by note or category name
  List<Expense> searchExpenses(String query, {DateTime? startDate, DateTime? endDate}) {
    final lowercaseQuery = query.toLowerCase().trim();
    if (lowercaseQuery.isEmpty) return [];
    
    final allExpenses = getAllExpenses();
    return allExpenses
        .where((expense) => 
            (expense.note?.toLowerCase().contains(lowercaseQuery) == true ||
             expense.categoryName.toLowerCase().contains(lowercaseQuery)) &&
            (startDate == null || expense.date.isAfter(startDate.subtract(const Duration(days: 1)))) &&
            (endDate == null || expense.date.isBefore(endDate.add(const Duration(days: 1)))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  /// Clear all expenses (for testing/reset)
  Future<void> clearAllExpenses() async {
    await _expensesBox.clear();
  }
}
