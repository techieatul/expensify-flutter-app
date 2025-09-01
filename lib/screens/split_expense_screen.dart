import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../utils/utils.dart';

/// Screen for splitting an expense across multiple months
class SplitExpenseScreen extends ConsumerStatefulWidget {
  final String? existingExpenseId;
  final double? prefilledAmount;
  final String? prefilledCategoryId;
  final DateTime? prefilledDate;

  const SplitExpenseScreen({
    super.key,
    this.existingExpenseId,
    this.prefilledAmount,
    this.prefilledCategoryId,
    this.prefilledDate,
  });

  @override
  ConsumerState<SplitExpenseScreen> createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends ConsumerState<SplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  Category? _selectedCategory;
  DateTime _startDate = DateTime.now();
  int _numberOfMonths = 3;
  DistributionType _distributionType = DistributionType.equal;
  RoundingMode _roundingMode = RoundingMode.roundHalfUp;
  List<double> _customDistributions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.prefilledAmount != null) {
      _amountController.text = widget.prefilledAmount.toString();
    }
    if (widget.prefilledDate != null) {
      _startDate = widget.prefilledDate!;
    }
    if (widget.prefilledCategoryId != null) {
      final categoryService = ref.read(categoryServiceProvider);
      _selectedCategory = categoryService.getCategoryById(widget.prefilledCategoryId!);
    }
    
    _updateCustomDistributions();
  }

  void _updateCustomDistributions() {
    if (_distributionType == DistributionType.custom) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (_customDistributions.length != _numberOfMonths) {
        _customDistributions = List.filled(_numberOfMonths, amount / _numberOfMonths);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Calculate the correct date for a split expense, preserving the day of month
  DateTime _calculateSplitDate(DateTime startDate, int monthOffset) {
    final targetYear = startDate.year;
    final targetMonth = startDate.month + monthOffset;
    final targetDay = startDate.day;
    
    // Handle month overflow (e.g., month 13 becomes year+1, month 1)
    final adjustedYear = targetYear + ((targetMonth - 1) ~/ 12);
    final adjustedMonth = ((targetMonth - 1) % 12) + 1;
    
    // Handle day overflow (e.g., Feb 31 becomes Feb 28/29, Sep 31 becomes Sep 30)
    final daysInMonth = DateTime(adjustedYear, adjustedMonth + 1, 0).day;
    final adjustedDay = targetDay > daysInMonth ? daysInMonth : targetDay;
    
    return DateTime(adjustedYear, adjustedMonth, adjustedDay);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Expense'),
        actions: [
          IconButton(
            onPressed: _previewSplit,
            icon: const Icon(Icons.preview),
            tooltip: 'Preview Split',
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
            _buildSplitConfigSection(),
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
              'Total Amount to Split',
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
              onChanged: (value) => _updateCustomDistributions(),
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
              'Start Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectStartDate,
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
                      _startDate.displayDate,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    if (_startDate.isToday)
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

  Widget _buildSplitConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Number of months
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Number of Months',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    value: _numberOfMonths,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(12, (index) => index + 2)
                        .map((months) => DropdownMenuItem(
                              value: months,
                              child: Text('$months'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _numberOfMonths = value!;
                        _updateCustomDistributions();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Distribution type
            Text(
              'Distribution Type',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Column(
              children: DistributionType.values.map((type) {
                return RadioListTile<DistributionType>(
                  title: Text(_getDistributionTypeLabel(type)),
                  subtitle: Text(_getDistributionTypeDescription(type)),
                  value: type,
                  groupValue: _distributionType,
                  onChanged: (value) {
                    setState(() {
                      _distributionType = value!;
                      _updateCustomDistributions();
                    });
                  },
                );
              }).toList(),
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
                hintText: 'Add a note about this split expense...',
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
          onPressed: _isLoading ? null : _createSplitExpense,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Split Expense'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _getDistributionTypeLabel(DistributionType type) {
    switch (type) {
      case DistributionType.equal:
        return 'Equal Distribution';
      case DistributionType.custom:
        return 'Custom Distribution';
    }
  }

  String _getDistributionTypeDescription(DistributionType type) {
    switch (type) {
      case DistributionType.equal:
        return 'Split amount equally across all months';
      case DistributionType.custom:
        return 'Set custom amount for each month';
    }
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

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _previewSplit() {
    if (!_validateForm()) return;

    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    final splitService = ref.read(splitServiceProvider);
    
    final splitPlan = SplitPlan.create(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      totalAmount: totalAmount,
      startMonth: _startDate,
      numberOfMonths: _numberOfMonths,
      distributionType: _distributionType,
      customDistributions: _distributionType == DistributionType.custom ? _customDistributions : null,
      roundingMode: _roundingMode,
    );

    final preview = splitService.previewSplit(splitPlan);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Split Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: \$${totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            ...List.generate(preview.length, (index) {
              final monthDate = _calculateSplitDate(_startDate, index);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(monthDate.displayDate),
                      ],
                    ),
                    Text(
                      '\$${preview[index].toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSplitExpense() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
      final splitService = ref.read(splitServiceProvider);
      
      final splitPlan = SplitPlan.create(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        totalAmount: totalAmount,
        startMonth: _startDate,
        numberOfMonths: _numberOfMonths,
        distributionType: _distributionType,
        customDistributions: _distributionType == DistributionType.custom ? _customDistributions : null,
        roundingMode: _roundingMode,
      );

      // Check if we're updating an existing expense or creating a new split
      if (widget.existingExpenseId != null) {
        // Update existing expense with split
        await splitService.updateExpenseWithSplit(
          existingExpenseId: widget.existingExpenseId!,
          splitPlan: splitPlan,
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
      } else {
        // Create new split expense
        await splitService.createSplitExpense(
          splitPlan: splitPlan,
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
      }

      // Force refresh of all expense-related providers
      ref.invalidate(expensesProvider);
      ref.invalidate(currentMonthExpensesProvider);
      ref.invalidate(currentMonthTotalProvider);
      ref.invalidate(currentMonthCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingExpenseId != null 
                ? 'Expense updated and split successfully!' 
                : 'Split expense created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.goToHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingExpenseId != null 
                ? 'Failed to update and split expense: $e'
                : 'Failed to create split expense: $e'),
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