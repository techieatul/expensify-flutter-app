import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/providers.dart';
import 'services/theme_provider.dart';
import 'services/lifecycle_service.dart';
import 'utils/utils.dart';
import 'utils/sample_data.dart';

// Global navigator key for lifecycle service


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Open Hive boxes
  await Hive.openBox(AppConstants.expensesBox);
  await Hive.openBox(AppConstants.categoriesBox);
  await Hive.openBox(AppConstants.splitPlansBox);
  await Hive.openBox(AppConstants.settingsBox);
  
  // Initialize default categories
  final categoriesBox = Hive.box(AppConstants.categoriesBox);
  if (categoriesBox.isEmpty) {
    // Import Category here to avoid circular imports
    final defaultCategories = [
      {
        'id': 'food',
        'name': 'Food & Dining',
        'icon': 'restaurant',
        'color': 0xFFFF6B35, // Vibrant orange-red
        'isDefault': true,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'id': 'shopping',
        'name': 'Shopping',
        'icon': 'shopping_cart',
        'color': 0xFF8B5CF6, // Vibrant purple
        'isDefault': true,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'id': 'gas',
        'name': 'Gas & Fuel',
        'icon': 'local_gas_station',
        'color': 0xFFEF4444, // Modern red
        'isDefault': true,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'id': 'home',
        'name': 'Home & Garden',
        'icon': 'home',
        'color': 0xFF10B981, // Emerald green
        'isDefault': true,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'id': 'car',
        'name': 'Auto & Transport',
        'icon': 'directions_car',
        'color': 0xFF3B82F6, // Modern blue
        'isDefault': true,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'id': 'bills',
        'name': 'Bills & Utilities',
        'icon': 'receipt',
        'color': 0xFF6B7280, // Modern gray
        'isDefault': true,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'id': 'entertainment',
        'name': 'Entertainment',
        'icon': 'movie',
        'color': 0xFFEC4899, // Vibrant pink
        'isDefault': true,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    ];
    
    for (final category in defaultCategories) {
      await categoriesBox.put(category['id'], category);
    }
  }
  
  // Initialize lifecycle service
  final lifecycleService = LifecycleService();
  await lifecycleService.initialize();
  
  runApp(
    const ProviderScope(
      child: ExpensifyApp(),
    ),
  );
}

/// Initialize sample data for development/demo
Future<void> initializeSampleData(WidgetRef ref) async {
  final expenseService = ref.read(expenseServiceProvider);
  final categoryService = ref.read(categoryServiceProvider);
  final splitService = ref.read(splitServiceProvider);
  
  await SampleDataUtils.setupDevelopmentData(
    expenseService,
    categoryService,
    splitService,
  );
}

class ExpensifyApp extends ConsumerWidget {
  const ExpensifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'Expensify',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
