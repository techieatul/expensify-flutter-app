import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../utils/utils.dart';

/// Screen for editing an existing expense
class EditExpenseScreen extends ConsumerStatefulWidget {
  final String expenseId;
  
  const EditExpenseScreen({
    super.key,
    required this.expenseId,
  });

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Expense? _originalExpense;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  void _loadExpense() {
    final expenseService = ref.read(expenseServiceProvider);
    _originalExpense = expenseService.getExpenseById(widget.expenseId);
    
    if (_originalExpense != null) {
      _amountController.text = _originalExpense!.amount.toString();
      _noteController.text = _originalExpense!.note ?? '';
      _selectedDate = _originalExpense!.date;
      
      // Find the category
      final categoryService = ref.read(categoryServiceProvider);
      _selectedCategory = categoryService.getCategoryById(_originalExpense!.categoryId);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_originalExpense == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Expense'),
        ),
        body: const Center(
          child: Text('Expense not found'),
        ),
      );
    }

    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _deleteExpense,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Expense',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAmountSection(),
            const SizedBox(height: 16),
            _buildCategorySection(categories),
            const SizedBox(height: 16),
            _buildDateSection(),
            const SizedBox(height: 16),
            _buildNoteSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: Validators.validateAmount,
              autofocus: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(List<Category> categories) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final isSelected = _selectedCategory?.id == category.id;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.iconData,
                        size: 16,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : Color(category.color),
                      ),
                      const SizedBox(width: 4),
                      Text(category.name),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                  backgroundColor: Color(category.color).withOpacity(0.1),
                  selectedColor: Color(category.color).withOpacity(0.3),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate.displayDate,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    if (_selectedDate.isToday)
                      Chip(
                        label: const Text('Today'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Note (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Add a note about this expense...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: AppConstants.maxNoteLength,
              validator: Validators.validateNote,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        FilledButton(
          onPressed: _isLoading ? null : _updateExpense,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Expense'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isLoading ? null : _updateAndSplit,
          child: const Text('Update & Split Across Months'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateExpense() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final expensesNotifier = ref.read(expensesProvider.notifier);

      await expensesNotifier.updateExpense(
        widget.expenseId,
        amount: double.parse(_amountController.text),
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      // Force refresh of all expense-related providers
      ref.invalidate(expensesProvider);
      ref.invalidate(currentMonthExpensesProvider);
      ref.invalidate(currentMonthTotalProvider);
      ref.invalidate(currentMonthCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.goToHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAndSplit() async {
    if (!_validateForm()) return;

    // Navigate to split expense screen with pre-filled data
    // Pass the existing expense ID so it can be updated instead of creating new
    context.goToSplitExpense(
      existingExpenseId: widget.expenseId, // Pass the existing expense ID
      prefilledAmount: double.parse(_amountController.text),
      prefilledCategoryId: _selectedCategory!.id,
      prefilledDate: _selectedDate,
    );
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final expensesNotifier = ref.read(expensesProvider.notifier);
        await expensesNotifier.deleteExpense(widget.expenseId);

        // Force refresh of all expense-related providers
        ref.invalidate(expensesProvider);
        ref.invalidate(currentMonthExpensesProvider);
        ref.invalidate(currentMonthTotalProvider);
        ref.invalidate(currentMonthCountProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.goToHome();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete expense: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}