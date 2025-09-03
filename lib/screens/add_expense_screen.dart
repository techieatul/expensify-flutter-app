import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';

/// Screen for adding a new expense
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount Section
            _buildAmountSection(),
            const SizedBox(height: 24),
            
            // Category Section
            _buildCategorySection(categories),
            const SizedBox(height: 24),
            
            // Date Section
            _buildDateSection(),
            const SizedBox(height: 24),
            
            // Note Section
            _buildNoteSection(),
            const SizedBox(height: 32),
            
            // Action Buttons
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
            InkWell(
              onTap: _showCalculator,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '${ref.watch(currencyServiceProvider).currencySymbol} ',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _amountController.text.isEmpty ? '0.00' : _amountController.text,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Icon(
                      Icons.calculate,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            if (_amountController.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap to enter amount using calculator',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
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
            if (categories.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final isSelected = _selectedCategory?.id == category.id;
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                    avatar: Icon(
                      category.iconData,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : category.colorValue,
                      size: 18,
                    ),
                    label: Text(category.name),
                    backgroundColor: category.colorValue.withValues(alpha: 0.1),
                    selectedColor: category.colorValue.withValues(alpha: 0.3),
                  );
                }).toList(),
              ),
            if (_selectedCategory == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select a category',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
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
          onPressed: _isLoading ? null : _saveExpense,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Expense'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isLoading ? null : _saveAndSplit,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call_split),
              SizedBox(width: 8),
              Text('Save & Split Across Months'),
            ],
          ),
        ),
      ],
    );
  }
  
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030), // Allow future dates
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showCalculator() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        margin: const EdgeInsets.all(16),
        child: CalculatorInput(
          initialValue: _amountController.text,
          onValueChanged: (value) {
            // Update the controller but don't trigger setState here
            // as it would rebuild the bottom sheet
            _amountController.text = value;
          },
          onDone: () {
            setState(() {
              // Trigger rebuild to show the new amount
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
  
  Future<void> _saveExpense() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final expensesNotifier = ref.read(expensesProvider.notifier);
      
      await expensesNotifier.addExpense(
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
            content: Text(AppConstants.expenseAdded),
            backgroundColor: Colors.green,
          ),
        );
        context.goToHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
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
  
  Future<void> _saveAndSplit() async {
    if (!_validateForm()) return;
    
    // Navigate to split expense screen with prefilled data
    context.goToSplitExpense(
      prefilledAmount: double.parse(_amountController.text),
      prefilledCategoryId: _selectedCategory!.id,
      prefilledDate: _selectedDate,
    );
  }
  
  bool _validateForm() {
    // Validate amount
    if (_amountController.text.isEmpty || _amountController.text == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (amount > 999999.99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount cannot exceed \$999,999.99'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    
    // Validate other form fields (note field)
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    
    return true;
  }
}
