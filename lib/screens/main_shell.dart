import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/utils.dart';

/// Main shell with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    switch (location) {
      case AppRouter.home:
        return 0;
      case AppRouter.analysis:
        return 1;
      case AppRouter.categories:
        return 2;
      case AppRouter.settings:
        return 3;
      default:
        return 0;
    }
  }
  
  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goToHome();
        break;
      case 1:
        context.goToAnalysis();
        break;
      case 2:
        context.goToCategories();
        break;
      case 3:
        context.goToSettings();
        break;
    }
  }
}
