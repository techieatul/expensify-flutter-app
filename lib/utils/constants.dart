/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Expensify';
  static const String appVersion = '1.0.0';
  
  // Currency
  static const String defaultCurrency = 'USD';
  static const String currencySymbol = '\$';
  
  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String monthFormat = 'MMM yyyy';
  static const String monthKeyFormat = 'yyyy-MM';
  
  // Hive Box Names
  static const String expensesBox = 'expenses';
  static const String categoriesBox = 'categories';
  static const String splitPlansBox = 'split_plans';
  static const String settingsBox = 'settings';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  static const String categoriesCollection = 'categories';
  static const String splitPlansCollection = 'splitPlans';
  
  // Settings Keys
  static const String themeKey = 'theme_mode';
  static const String currencyKey = 'currency_code';
  static const String lastSyncKey = 'last_sync';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Validation
  static const double minExpenseAmount = 0.01;
  static const double maxExpenseAmount = 999999.99;
  static const int maxNoteLength = 500;
  static const int maxCategoryNameLength = 50;
  static const int minSplitMonths = 2;
  static const int maxSplitMonths = 60;
  
  // Error Messages
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String syncError = 'Failed to sync data. Changes will be saved locally.';
  static const String authError = 'Authentication failed. Please sign in again.';
  static const String validationError = 'Please check your input and try again.';
  
  // Success Messages
  static const String expenseAdded = 'Expense added successfully';
  static const String expenseUpdated = 'Expense updated successfully';
  static const String expenseDeleted = 'Expense deleted';
  static const String categoryAdded = 'Category added successfully';
  static const String categoryUpdated = 'Category updated successfully';
  static const String splitCreated = 'Split plan created successfully';
  static const String syncCompleted = 'Data synced successfully';
}
