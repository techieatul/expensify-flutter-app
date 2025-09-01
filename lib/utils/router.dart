import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/screens.dart';

/// App routing configuration using go_router
class AppRouter {
  static const String home = '/';
  static const String addExpense = '/add-expense';
  static const String editExpense = '/edit-expense';
  static const String splitExpense = '/split-expense';
  static const String analysis = '/analysis';
  static const String categories = '/categories';
  static const String addCategory = '/add-category';
  static const String editCategory = '/edit-category';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String categoryDetail = '/category-detail';
  static const String auth = '/auth';
  
  /// Router configuration
  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: false, // Disable debug logs for faster startup
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Main navigation with shell route for bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Home/Records screen
          GoRoute(
            path: home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              // Add expense as a sub-route of home
              GoRoute(
                path: 'add-expense',
                name: 'add-expense',
                builder: (context, state) => const AddExpenseScreen(),
              ),
              // Edit expense as a sub-route of home
              GoRoute(
                path: 'edit-expense/:id',
                name: 'edit-expense',
                builder: (context, state) {
                  final expenseId = state.pathParameters['id']!;
                  return EditExpenseScreen(expenseId: expenseId);
                },
              ),
              // Split expense as a sub-route of home
              GoRoute(
                path: 'split-expense',
                name: 'split-expense',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return SplitExpenseScreen(
                    existingExpenseId: extra?['expenseId'] as String?,
                    prefilledAmount: extra?['amount'] as double?,
                    prefilledCategoryId: extra?['categoryId'] as String?,
                    prefilledDate: extra?['date'] as DateTime?,
                  );
                },
              ),
            ],
          ),
          
          // Analysis screen
          GoRoute(
            path: analysis,
            name: 'analysis',
            builder: (context, state) => const AnalysisScreen(),
          ),
          
          // Categories screen
          GoRoute(
            path: categories,
            name: 'categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          
                  // Settings screen
        GoRoute(
          path: settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        
        // Search screen
        GoRoute(
          path: search,
          name: 'search',
          builder: (context, state) => const SearchScreen(),
        ),
        ],
      ),
      
      // Category detail screen (outside shell for full-screen experience)
      GoRoute(
        path: categoryDetail,
        name: 'categoryDetail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CategoryDetailScreen(
            categoryId: extra?['categoryId'] ?? '',
            startDate: extra?['startDate'] ?? DateTime.now(),
            endDate: extra?['endDate'] ?? DateTime.now(),
          );
        },
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Error: ${state.error.toString()}'),
      ),
    ),
    
    // Redirect logic for authentication
    redirect: (context, state) {
      // TODO: Implement authentication check
      // For now, allow all routes
      return null;
    },
  );
}

/// Navigation helper methods
extension AppRouterExtension on GoRouter {
  /// Navigate to add expense screen
  void goToAddExpense() => go('/add-expense');
  
  /// Navigate to edit expense screen
  void goToEditExpense(String expenseId) => go('/edit-expense/$expenseId');
  
  /// Navigate to split expense screen
  void goToSplitExpense({
    String? existingExpenseId,
    double? prefilledAmount,
    String? prefilledCategoryId,
    DateTime? prefilledDate,
  }) {
    go(
      '/split-expense',
      extra: {
        'expenseId': existingExpenseId,
        'amount': prefilledAmount,
        'categoryId': prefilledCategoryId,
        'date': prefilledDate,
      },
    );
  }
  

  
  /// Navigate to analysis screen
  void goToAnalysis() => go(AppRouter.analysis);
  
  /// Navigate to categories screen
  void goToCategories() => go(AppRouter.categories);
  
  /// Navigate to settings screen
  void goToSettings() => go(AppRouter.settings);
  
  /// Navigate to search screen
  void goToSearch() => go(AppRouter.search);
  
  /// Navigate to category detail screen
  void goToCategoryDetail({
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    go(
      AppRouter.categoryDetail,
      extra: {
        'categoryId': categoryId,
        'startDate': startDate,
        'endDate': endDate,
      },
    );
  }
  
  /// Navigate to home screen
  void goToHome() => go(AppRouter.home);
  

}

/// Context extension for easy navigation
extension BuildContextExtension on BuildContext {
  /// Get the router instance
  GoRouter get router => GoRouter.of(this);
  
  /// Navigate to add expense screen
  void goToAddExpense() => router.goToAddExpense();
  
  /// Navigate to edit expense screen
  void goToEditExpense(String expenseId) => router.goToEditExpense(expenseId);
  
  /// Navigate to split expense screen
  void goToSplitExpense({
    String? existingExpenseId,
    double? prefilledAmount,
    String? prefilledCategoryId,
    DateTime? prefilledDate,
  }) => router.goToSplitExpense(
    existingExpenseId: existingExpenseId,
    prefilledAmount: prefilledAmount,
    prefilledCategoryId: prefilledCategoryId,
    prefilledDate: prefilledDate,
  );
  

  
  /// Navigate to analysis screen
  void goToAnalysis() => router.goToAnalysis();
  
  /// Navigate to categories screen
  void goToCategories() => router.goToCategories();
  
  /// Navigate to settings screen
  void goToSettings() => router.goToSettings();
  
  /// Navigate to search screen
  void goToSearch() => router.goToSearch();
  
  /// Navigate to category detail screen
  void goToCategoryDetail({
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
  }) => router.goToCategoryDetail(
    categoryId: categoryId,
    startDate: startDate,
    endDate: endDate,
  );
  
  /// Navigate to home screen
  void goToHome() => router.goToHome();
  

  
  /// Go back
  void goBack() => router.pop();
}
