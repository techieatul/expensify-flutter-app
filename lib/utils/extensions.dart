import 'package:intl/intl.dart';

/// Extensions for DateTime
extension DateTimeExtensions on DateTime {
  /// Format date for display (e.g., "Aug 21, 2024")
  String get displayDate => DateFormat('MMM dd, yyyy').format(this);
  
  /// Format month for display (e.g., "August 2024")
  String get displayMonth => DateFormat('MMMM yyyy').format(this);
  
  /// Format month short (e.g., "Aug 2024")
  String get displayMonthShort => DateFormat('MMM yyyy').format(this);
  
  /// Get month key for grouping (e.g., "2024-08")
  String get monthKey => DateFormat('yyyy-MM').format(this);
  
  /// Get month and year display (MMM YYYY format)
  String get monthYear => DateFormat('MMM yyyy').format(this);
  
  /// Get first day of month
  DateTime get firstDayOfMonth => DateTime(year, month, 1);
  
  /// Get last day of month
  DateTime get lastDayOfMonth => DateTime(year, month + 1, 0);
  
  /// Check if this date is in the same month as another date
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }
  
  /// Check if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Check if this date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  /// Get relative date string (Today, Yesterday, or formatted date)
  String get relativeDate {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return displayDate;
  }
  
  /// Add months safely (handles month overflow)
  DateTime addMonthsSafe(int months) {
    int newYear = year;
    int newMonth = month + months;
    
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }
    
    // Handle day overflow (e.g., Jan 31 + 1 month = Feb 28/29)
    final lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = day > lastDayOfNewMonth ? lastDayOfNewMonth : day;
    
    return DateTime(newYear, newMonth, newDay, hour, minute, second, millisecond, microsecond);
  }
}

/// Extensions for double (amounts)
extension DoubleExtensions on double {
  /// Format as currency (e.g., "$24.99")
  String get currency => '\$${toStringAsFixed(2)}';
  
  /// Format as currency without symbol (e.g., "24.99")
  String get currencyWithoutSymbol => toStringAsFixed(2);
  
  /// Round to 2 decimal places
  double get rounded => (this * 100).round() / 100;
  
  /// Check if amount is valid for expenses
  bool get isValidAmount => this >= 0.01 && this <= 999999.99;
}

/// Extensions for String
extension StringExtensions on String {
  /// Check if string is empty or null
  bool get isEmptyOrNull => isEmpty;
  
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Parse to double safely
  double? get toDoubleOrNull {
    try {
      return double.parse(this);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if string is a valid number
  bool get isNumeric {
    return toDoubleOrNull != null;
  }
}

/// Extensions for List of double
extension DoubleListExtensions on List<double> {
  /// Sum all values
  double get sum => fold<double>(0, (a, b) => a + b);
  
  /// Get average
  double get average => isEmpty ? 0 : sum / length;
  
  /// Check if all values sum to approximately 1.0 (for percentages)
  bool get sumsToOne => (sum - 1.0).abs() <= 0.01;
}

/// Extensions for List of T
extension ListExtensions<T> on List<T> {
  /// Get element at index safely (returns null if out of bounds)
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  /// Add element if not null
  void addIfNotNull(T? element) {
    if (element != null) add(element);
  }
}
