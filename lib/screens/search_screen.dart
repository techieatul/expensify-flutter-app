import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../utils/utils.dart';

/// Screen for searching expenses
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum SearchDateFilter {
  all('All Time'),
  currentMonth('Current Month'),
  currentQuarter('Current Quarter'),
  currentYear('Current Year'),
  custom('Custom Range');

  const SearchDateFilter(this.label);
  final String label;
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<Expense> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';
  
  // Date filtering
  SearchDateFilter _selectedDateFilter = SearchDateFilter.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter by date',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by amount, category, or note...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  onChanged: _onSearchChanged,
                  autofocus: true,
                ),
              ),
              const SizedBox(height: 8),
              // Date filter chips
              _buildDateFilterChips(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Search your expenses',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter amount, category name, or note to find expenses',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final expense = _searchResults[index];
        final categoryService = ref.read(categoryServiceProvider);
        final category = categoryService.getCategoryById(expense.categoryId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
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
            title: Text(
              category?.name ?? expense.categoryName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (expense.note?.isNotEmpty == true) ...[
                  Text(
                    expense.note!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  expense.date.displayDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  expense.formattedAmount,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (expense.splitPlanId != null)
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
            ),
            onTap: () => context.goToEditExpense(expense.id),
          ),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    if (query == _lastQuery) return;
    _lastQuery = query;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Debounce search to avoid too many calls
    Future.delayed(const Duration(milliseconds: 300), () {
      if (query == _lastQuery && mounted) {
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    final expenseService = ref.read(expenseServiceProvider);
    final (startDate, endDate) = _getDateRange();
    
    List<Expense> results;
    if (query.isEmpty) {
      results = [];
    } else {
      results = expenseService.searchExpenses(query, startDate: startDate, endDate: endDate);
    }
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _lastQuery = '';
    });
  }

  Widget _buildDateFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: SearchDateFilter.values.map((filter) {
          final isSelected = _selectedDateFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDateFilter = filter;
                    if (filter == SearchDateFilter.custom) {
                      _showCustomDatePicker();
                    } else {
                      _customStartDate = null;
                      _customEndDate = null;
                      _performSearch(_lastQuery);
                    }
                  });
                }
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SearchDateFilter.values.map((filter) {
            return RadioListTile<SearchDateFilter>(
              title: Text(filter.label),
              value: filter,
              groupValue: _selectedDateFilter,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDateFilter = value;
                    if (value == SearchDateFilter.custom) {
                      Navigator.of(context).pop();
                      _showCustomDatePicker();
                    } else {
                      _customStartDate = null;
                      _customEndDate = null;
                      Navigator.of(context).pop();
                      _performSearch(_lastQuery);
                    }
                  });
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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
          _customStartDate = startDate;
          _customEndDate = endDate;
        });
        _performSearch(_lastQuery);
      }
    }
  }

  (DateTime?, DateTime?) _getDateRange() {
    final now = DateTime.now();
    
    switch (_selectedDateFilter) {
      case SearchDateFilter.all:
        return (null, null);
      
      case SearchDateFilter.currentMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return (startOfMonth, endOfMonth);
      
      case SearchDateFilter.currentQuarter:
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final startOfQuarter = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);
        final endOfQuarter = DateTime(now.year, currentQuarter * 3 + 1, 0);
        return (startOfQuarter, endOfQuarter);
      
      case SearchDateFilter.currentYear:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        return (startOfYear, endOfYear);
      
      case SearchDateFilter.custom:
        return (_customStartDate, _customEndDate);
    }
  }
}
