import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../utils/utils.dart';

/// Screen showing all expenses for a specific category
class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final DateTime startDate;
  final DateTime endDate;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final categoryService = ref.read(categoryServiceProvider);
    final expenseService = ref.read(expenseServiceProvider);
    final category = categoryService.getCategoryById(widget.categoryId);
    
    // Get all expenses for this category in the date range
    final allExpenses = expenseService.getExpensesForDateRange(widget.startDate, widget.endDate);
    final categoryExpenses = allExpenses
        .where((expense) => expense.categoryId == widget.categoryId && expense.deletedAt == null)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalAmount = categoryExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name ?? 'Category Details'),
        backgroundColor: category != null ? Color(category.color).withOpacity(0.1) : null,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.goToAnalysis();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Category Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: category != null ? Color(category.color).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: category != null ? Color(category.color).withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  category?.iconData ?? Icons.category,
                  size: 48,
                  color: category != null ? Color(category.color) : Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  category?.name ?? 'Unknown Category',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalAmount.currency,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${categoryExpenses.length} expense${categoryExpenses.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Expenses List
          Expanded(
            child: categoryExpenses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categoryExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = categoryExpenses[index];
                      return _buildExpenseItem(expense, category);
                    },
                  ),
          ),
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
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No expenses in this category for the selected period',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense, Category? category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                expense.note?.isNotEmpty == true ? expense.note! : category?.name ?? 'Expense',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (expense.splitPlanId != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Split',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          expense.date.displayDate,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          expense.formattedAmount,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: () => context.goToEditExpense(expense.id),
      ),
    );
  }
}
