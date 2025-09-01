import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../utils/utils.dart';

/// Screen for viewing expense analytics and charts
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  String _selectedPeriod = 'month'; // month, quarter, year, custom
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  Widget build(BuildContext context) {
    final expenseService = ref.read(expenseServiceProvider);
    
    // Get data based on selected period
    final (startDate, endDate) = _getDateRange();
    final expenses = expenseService.getExpensesForDateRange(startDate, endDate);
    final categoryTotals = expenseService.getCategoryTotals(startDate, endDate);
    final totalAmount = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (period) {
              if (period == 'custom') {
                _showCustomDatePicker();
              } else {
                setState(() {
                  _selectedPeriod = period;
                  _customStartDate = null;
                  _customEndDate = null;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'quarter', child: Text('This Quarter')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
              const PopupMenuItem(value: 'custom', child: Text('Custom Range')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getPeriodLabel()),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: expenses.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCards(totalAmount, expenses.length),
                const SizedBox(height: 24),
                _buildTopCategories(categoryTotals),
                const SizedBox(height: 24),
                _buildRecentExpenses(expenses),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses to analyze',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some expenses to see your spending analytics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double totalAmount, int expenseCount) {
    final avgPerExpense = expenseCount > 0 ? totalAmount / expenseCount : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Spent',
                '\$${totalAmount.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Transactions',
                expenseCount.toString(),
                Icons.receipt_long,
                Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Average per Transaction',
          '\$${avgPerExpense.toStringAsFixed(2)}',
          Icons.trending_up,
          Theme.of(context).colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...sortedEntries.take(5).map((entry) {
              final categoryService = ref.read(categoryServiceProvider);
              final category = categoryService.getCategoryById(entry.key);
              final totalSum = categoryTotals.values.fold<double>(0, (sum, value) => sum + value);
              final percentage = totalSum > 0 ? (entry.value / totalSum) * 100 : 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    final (startDate, endDate) = _getDateRange();
                    context.goToCategoryDetail(
                      categoryId: entry.key,
                      startDate: startDate,
                      endDate: endDate,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(
                          category?.iconData ?? Icons.category,
                          color: category != null ? Color(category.color) : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category?.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation(
                                  category != null ? Color(category.color) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${entry.value.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenses(List<Expense> expenses) {
    final recentExpenses = expenses.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Expenses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...recentExpenses.map((expense) {
              final categoryService = ref.read(categoryServiceProvider);
              final category = categoryService.getCategoryById(expense.categoryId);
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: category != null 
                      ? Color(category.color).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  child: Icon(
                    category?.iconData ?? Icons.category,
                    color: category != null ? Color(category.color) : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(_getExpenseDisplayName(expense, category)),
                subtitle: Text(expense.date.displayDate),
                trailing: Text(
                  expense.formattedAmount,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => context.goToEditExpense(expense.id),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Get the proper display name for an expense
  String _getExpenseDisplayName(Expense expense, Category? category) {
    final categoryName = category?.name ?? expense.categoryName;
    
    // Always show just the category name, regardless of split status
    // This keeps the analysis clean and groups expenses by category only
    return categoryName;
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'quarter':
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        final quarterEnd = DateTime(quarterStart.year, quarterStart.month + 3, 0);
        return (quarterStart, quarterEnd);
      case 'year':
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return (_customStartDate!, _customEndDate!);
        }
        // Fallback to current month if custom dates not set
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
      default: // month
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
    }
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'quarter':
        return 'This Quarter';
      case 'year':
        return 'This Year';
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_customStartDate!.displayDate} - ${_customEndDate!.displayDate}';
        }
        return 'Custom Range';
      default:
        return 'This Month';
    }
  }

  void _showCustomDatePicker() async {
    final now = DateTime.now();
    final startDate = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select start date',
    );

    if (startDate != null && mounted) {
      final endDate = await showDatePicker(
        context: context,
        initialDate: _customEndDate ?? startDate,
        firstDate: startDate,
        lastDate: now,
        helpText: 'Select end date',
      );

      if (endDate != null && mounted) {
        setState(() {
          _selectedPeriod = 'custom';
          _customStartDate = startDate;
          _customEndDate = endDate;
        });
      }
    }
  }
}