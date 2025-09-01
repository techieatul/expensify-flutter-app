import 'constants.dart';

/// Validation utilities for forms and inputs
class Validators {
  /// Validate expense amount
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid number';
    }
    
    if (amount < AppConstants.minExpenseAmount) {
      return 'Amount must be at least \$${AppConstants.minExpenseAmount.toStringAsFixed(2)}';
    }
    
    if (amount > AppConstants.maxExpenseAmount) {
      return 'Amount cannot exceed \$${AppConstants.maxExpenseAmount.toStringAsFixed(0)}';
    }
    
    return null;
  }
  
  /// Validate category name
  static String? validateCategoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required';
    }
    
    final trimmed = value.trim();
    if (trimmed.length > AppConstants.maxCategoryNameLength) {
      return 'Category name cannot exceed ${AppConstants.maxCategoryNameLength} characters';
    }
    
    return null;
  }
  
  /// Validate note (optional field)
  static String? validateNote(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Note is optional
    }
    
    if (value.trim().length > AppConstants.maxNoteLength) {
      return 'Note cannot exceed ${AppConstants.maxNoteLength} characters';
    }
    
    return null;
  }
  
  /// Validate number of months for split
  static String? validateSplitMonths(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number of months is required';
    }
    
    final months = int.tryParse(value.trim());
    if (months == null) {
      return 'Please enter a valid number';
    }
    
    if (months < AppConstants.minSplitMonths) {
      return 'Minimum ${AppConstants.minSplitMonths} months required';
    }
    
    if (months > AppConstants.maxSplitMonths) {
      return 'Maximum ${AppConstants.maxSplitMonths} months allowed';
    }
    
    return null;
  }
  
  /// Validate custom distribution percentages
  static String? validateCustomDistribution(List<double>? distributions, int expectedLength) {
    if (distributions == null || distributions.isEmpty) {
      return 'Distribution percentages are required';
    }
    
    if (distributions.length != expectedLength) {
      return 'Expected $expectedLength distribution values';
    }
    
    // Check for negative values
    if (distributions.any((d) => d < 0)) {
      return 'Distribution percentages cannot be negative';
    }
    
    // Check if sum is approximately 100% (allowing for small floating point errors)
    final sum = distributions.fold<double>(0, (a, b) => a + b);
    if ((sum - 1.0).abs() > 0.01) {
      return 'Distribution percentages must sum to 100%';
    }
    
    return null;
  }
  
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validate date is not in the future (for expenses)
  static String? validateExpenseDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDate = DateTime(date.year, date.month, date.day);
    
    if (expenseDate.isAfter(today)) {
      return 'Expense date cannot be in the future';
    }
    
    return null;
  }
  
  /// Validate date range
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Both start and end dates are required';
    }
    
    if (startDate.isAfter(endDate)) {
      return 'Start date must be before end date';
    }
    
    return null;
  }
  
  /// Check if string contains only valid characters for category names
  static bool isValidCategoryName(String name) {
    // Allow letters, numbers, spaces, and basic punctuation
    final validRegex = RegExp(r'^[a-zA-Z0-9\s\-_&.,!]+$');
    return validRegex.hasMatch(name.trim());
  }
  
  /// Sanitize input string
  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  /// Validate calculator expression
  static String? validateCalculatorExpression(String expression) {
    if (expression.isEmpty) {
      return 'Expression cannot be empty';
    }
    
    // Basic validation for calculator expressions
    final validChars = RegExp(r'^[0-9+\-*/.() ]+$');
    if (!validChars.hasMatch(expression)) {
      return 'Invalid characters in expression';
    }
    
    // Check for balanced parentheses
    int openParens = 0;
    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '(') openParens++;
      if (expression[i] == ')') openParens--;
      if (openParens < 0) return 'Unmatched closing parenthesis';
    }
    
    if (openParens > 0) {
      return 'Unmatched opening parenthesis';
    }
    
    return null;
  }
}
