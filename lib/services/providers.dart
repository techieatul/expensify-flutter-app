import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'services.dart';
import 'lifecycle_service.dart';

/// Provider for ExpenseService
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService();
});

/// Provider for CategoryService
final categoryServiceProvider = Provider<CategoryService>((ref) {
  final service = CategoryService();
  return service;
});

/// Provider for SplitService
final splitServiceProvider = Provider<SplitService>((ref) {
  final expenseService = ref.watch(expenseServiceProvider);
  return SplitService(expenseService);
});

/// Provider for LifecycleService
final lifecycleServiceProvider = Provider<LifecycleService>((ref) {
  return LifecycleService();
});

/// Provider for all expenses
final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  final expenseService = ref.watch(expenseServiceProvider);
  return ExpensesNotifier(expenseService);
});

/// Provider for all categories
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  final categoryService = ref.watch(categoryServiceProvider);
  return CategoriesNotifier(categoryService);
});

/// Provider for expenses in current month
final currentMonthExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month, 1);
  
  return expenses.where((expense) => 
      expense.date.year == currentMonth.year && 
      expense.date.month == currentMonth.month &&
      expense.shouldIncludeInTotals
  ).toList()
    ..sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      return b.createdAt.compareTo(a.createdAt);
    });
});

/// Provider for current month total
final currentMonthTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);
  return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
});

/// Provider for current month count
final currentMonthCountProvider = Provider<int>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);
  return expenses.length;
});

/// StateNotifier for managing expenses
class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final ExpenseService _expenseService;
  
  ExpensesNotifier(this._expenseService) : super([]) {
    _loadExpenses();
  }
  
  void _loadExpenses() {
    state = _expenseService.getAllExpenses();
  }
  
  Future<void> addExpense({
    required double amount,
    required String categoryId,
    required String categoryName,
    required DateTime date,
    String? note,
  }) async {
    await _expenseService.addExpense(
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
      date: date,
      note: note,
    );
    _loadExpenses();
  }
  
  Future<void> updateExpense(
    String expenseId, {
    double? amount,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    String? note,
  }) async {
    await _expenseService.updateExpense(
      expenseId,
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
      date: date,
      note: note,
    );
    _loadExpenses();
  }
  
  Future<void> deleteExpense(String expenseId) async {
    await _expenseService.deleteExpense(expenseId);
    _loadExpenses();
  }
  
  Future<void> restoreExpense(String expenseId) async {
    await _expenseService.restoreExpense(expenseId);
    _loadExpenses();
  }
  
  List<Expense> getExpensesForMonth(DateTime month) {
    return _expenseService.getExpensesForMonth(month);
  }
  
  double getTotalForMonth(DateTime month) {
    return _expenseService.getTotalForMonth(month);
  }
  
  int getCountForMonth(DateTime month) {
    return _expenseService.getCountForMonth(month);
  }
}

/// StateNotifier for managing categories
class CategoriesNotifier extends StateNotifier<List<Category>> {
  final CategoryService _categoryService;
  
  CategoriesNotifier(this._categoryService) : super([]) {
    _initializeCategories();
  }
  
  void _initializeCategories() async {
    await _categoryService.initialize();
    _loadCategories();
  }
  
  void _loadCategories() {
    state = _categoryService.getAllCategories();
  }
  
  Future<void> addCategory({
    required String name,
    required String icon,
    required Color color,
  }) async {
    await _categoryService.addCategory(
      name: name,
      icon: icon,
      color: color,
    );
    _loadCategories();
  }
  
  Future<void> updateCategory(
    String categoryId, {
    String? name,
    String? icon,
    Color? color,
  }) async {
    await _categoryService.updateCategory(
      categoryId,
      name: name,
      icon: icon,
      color: color,
    );
    _loadCategories();
  }
  
  Future<void> deleteCategory(String categoryId) async {
    await _categoryService.deleteCategory(categoryId);
    _loadCategories();
  }
  
  Category? getCategoryById(String categoryId) {
    return _categoryService.getCategoryById(categoryId);
  }
}
