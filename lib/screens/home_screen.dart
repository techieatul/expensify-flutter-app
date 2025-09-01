import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../services/theme_provider.dart';
import '../utils/utils.dart';
import '../utils/sample_data.dart';


/// Home screen showing expense records for the current month
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Watch all expenses to ensure we get updates
    ref.watch(expensesProvider);
    final expenseService = ref.read(expenseServiceProvider);
    
    // Get monthly data for the selected month
    final monthlyExpenses = expenseService.getExpensesForMonth(_currentMonth);
    final monthlyTotal = expenseService.getTotalForMonth(_currentMonth);
    final monthlyCount = expenseService.getCountForMonth(_currentMonth);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expensify'),
        actions: [
          // Debug buttons (only show in debug mode)
          if (kDebugMode) ...[
            IconButton(
              onPressed: _loadSampleData,
              icon: const Icon(Icons.data_usage),
              tooltip: 'Load Sample Data',
            ),
            IconButton(
              onPressed: _debugData,
              icon: const Icon(Icons.bug_report),
              tooltip: 'Debug Data',
            ),
          ],
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            icon: Icon(ref.watch(themeModeProvider.notifier).themeIcon),
            tooltip: 'Toggle Theme (${ref.watch(themeModeProvider.notifier).currentThemeName})',
          ),
          IconButton(
            onPressed: () => context.goToSettings(),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month navigation header
          _buildMonthHeader(),
          
          // Monthly summary
          _buildMonthlySummary(monthlyTotal, monthlyCount),
          
          // Expense list
          Expanded(
            child: _buildExpenseList(monthlyExpenses),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goToAddExpense(),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _currentMonth = _currentMonth.addMonthsSafe(-1);
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              _currentMonth.displayMonth,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => context.goToSearch(),
            icon: const Icon(Icons.search),
            tooltip: 'Search expenses',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _currentMonth = _currentMonth.addMonthsSafe(1);
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthlySummary(double total, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'Total Expenses',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                total.currency,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
          ),
          Column(
            children: [
              Text(
                'Transactions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpenseList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _buildExpenseItem(expense);
      },
    );
  }
  
  Widget _buildExpenseItem(Expense expense) {
    final categories = ref.watch(categoriesProvider);
    final category = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => Category.create(
        id: 'unknown',
        name: 'Unknown',
        icon: 'category',
        color: Colors.grey,
      ),
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(expense.id),
        background: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: Icon(
            Icons.delete,
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(
            Icons.edit,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Delete action
            return await _showDeleteConfirmation(expense);
          } else {
            // Edit action
            context.goToEditExpense(expense.id);
            return false;
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            _deleteExpense(expense);
          }
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: category.colorValue.withValues(alpha: 0.2),
            child: Icon(
              category.iconData,
              color: category.colorValue,
            ),
          ),
          title: Text(
            category.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.date.relativeDate,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (expense.note != null && expense.note!.isNotEmpty)
                Text(
                  expense.note!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                expense.formattedAmount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (expense.splitPlanId != null)
                Icon(
                  Icons.call_split,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          onTap: () => _showExpenseActions(expense),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first expense',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.goToAddExpense(),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<bool> _showDeleteConfirmation(Expense expense) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this ${expense.formattedAmount} expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  void _deleteExpense(Expense expense) {
    final expensesNotifier = ref.read(expensesProvider.notifier);
    expensesNotifier.deleteExpense(expense.id);
    
    // Show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${expense.formattedAmount} expense deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            expensesNotifier.restoreExpense(expense.id);
          },
        ),
      ),
    );
  }
  
  void _showExpenseActions(Expense expense) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(context).pop();
                context.goToEditExpense(expense.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.call_split),
              title: const Text('Split Across Months'),
              onTap: () {
                Navigator.of(context).pop();
                context.goToSplitExpense(
                  existingExpenseId: expense.id,
                  prefilledAmount: expense.amount,
                  prefilledCategoryId: expense.categoryId,
                  prefilledDate: expense.date,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.of(context).pop();
                if (await _showDeleteConfirmation(expense)) {
                  _deleteExpense(expense);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Load sample data for testing/demo purposes
  Future<void> _loadSampleData() async {
    try {
      final expenseService = ref.read(expenseServiceProvider);
      final categoryService = ref.read(categoryServiceProvider);
      final splitService = ref.read(splitServiceProvider);
      
      await SampleDataUtils.setupDevelopmentData(
        expenseService,
        categoryService,
        splitService,
      );
      
      // Refresh the expenses list
      ref.invalidate(expensesProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data loaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sample data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _debugData() {
    final expenseService = ref.read(expenseServiceProvider);
    
    // Get raw data from services
    final rawExpenses = expenseService.getAllExpenses();
    final monthlyExpenses = expenseService.getExpensesForMonth(_currentMonth);
    
    // Debug expense dates
    final expenseDates = rawExpenses.map((e) => '${e.date.day}/${e.date.month}: ${e.amount}').join(', ');
    final currentMonthKey = _currentMonth.monthKey;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total Expenses: ${rawExpenses.length}\nCurrent Month ($currentMonthKey): ${monthlyExpenses.length}\nDates: $expenseDates'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
}
