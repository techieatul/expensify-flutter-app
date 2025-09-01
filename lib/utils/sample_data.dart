
import '../models/models.dart';
import '../services/services.dart';

/// Sample data generator for testing and demonstration
class SampleDataGenerator {
  final ExpenseService _expenseService;
  final CategoryService _categoryService;
  final SplitService _splitService;
  
  SampleDataGenerator(
    this._expenseService,
    this._categoryService,
    this._splitService,
  );
  
  /// Generate sample expenses for the last 3 months
  Future<void> generateSampleData() async {
    // Ensure categories are initialized
    await _categoryService.initialize();
    final categories = _categoryService.getAllCategories();
    
    if (categories.isEmpty) {
      throw Exception('No categories available for sample data generation');
    }
    
    final now = DateTime.now();
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    
    // Generate expenses for the last 3 months
    for (int monthOffset = 0; monthOffset < 3; monthOffset++) {
      final month = DateTime(now.year, now.month - monthOffset, 1);
      await _generateExpensesForMonth(month, categories, random + monthOffset);
    }
    
    // Generate a few split plans
    await _generateSampleSplitPlans(categories);
  }
  
  /// Generate expenses for a specific month
  Future<void> _generateExpensesForMonth(
    DateTime month,
    List<Category> categories,
    int seed,
  ) async {
    final random = _SimpleRandom(seed);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    
    // Generate 8-15 expenses per month
    final expenseCount = 8 + (random.nextInt(8));
    
    for (int i = 0; i < expenseCount; i++) {
      final category = categories[random.nextInt(categories.length)];
      final day = 1 + random.nextInt(daysInMonth);
      final date = DateTime(month.year, month.month, day);
      
      // Generate realistic amounts based on category
      final amount = _generateRealisticAmount(category.name, random);
      
      // Generate optional notes for some expenses
      final note = random.nextInt(3) == 0 ? _generateNote(category.name, random) : null;
      
      await _expenseService.addExpense(
        amount: amount,
        categoryId: category.id,
        categoryName: category.name,
        date: date,
        note: note,
      );
    }
  }
  
  /// Generate sample split plans
  Future<void> _generateSampleSplitPlans(List<Category> categories) async {
    final random = _SimpleRandom(42);
    final now = DateTime.now();
    
    // Generate 2-3 split plans
    for (int i = 0; i < 2; i++) {
      final category = categories[random.nextInt(categories.length)];
      final startMonth = DateTime(now.year, now.month - random.nextInt(2), 1);
      final numberOfMonths = 3 + random.nextInt(4); // 3-6 months
      final totalAmount = 200 + random.nextInt(800); // $200-$1000
      
      final splitPlan = SplitPlan.create(
        id: 'sample-split-$i',
        totalAmount: totalAmount.toDouble(),
        startMonth: startMonth,
        numberOfMonths: numberOfMonths,
        distributionType: DistributionType.equal,
        roundingMode: RoundingMode.roundHalfUp,
      );
      
      await _splitService.createSplitExpense(
        splitPlan: splitPlan,
        categoryId: category.id,
        categoryName: category.name,
        note: 'Sample split plan ${i + 1}',
      );
    }
  }
  
  /// Generate realistic amounts based on category
  double _generateRealisticAmount(String categoryName, _SimpleRandom random) {
    final baseName = categoryName.toLowerCase();
    
    if (baseName.contains('food') || baseName.contains('dining')) {
      return 8.0 + random.nextInt(50); // $8-$58
    } else if (baseName.contains('gas') || baseName.contains('fuel')) {
      return 30.0 + random.nextInt(70); // $30-$100
    } else if (baseName.contains('shopping')) {
      return 15.0 + random.nextInt(200); // $15-$215
    } else if (baseName.contains('bills') || baseName.contains('utilities')) {
      return 50.0 + random.nextInt(150); // $50-$200
    } else if (baseName.contains('entertainment') || baseName.contains('movie')) {
      return 10.0 + random.nextInt(40); // $10-$50
    } else if (baseName.contains('healthcare') || baseName.contains('medical')) {
      return 20.0 + random.nextInt(180); // $20-$200
    } else if (baseName.contains('transport') || baseName.contains('car')) {
      return 15.0 + random.nextInt(85); // $15-$100
    } else if (baseName.contains('home') || baseName.contains('garden')) {
      return 25.0 + random.nextInt(175); // $25-$200
    } else {
      return 10.0 + random.nextInt(90); // $10-$100 (default)
    }
  }
  
  /// Generate sample notes for expenses
  String? _generateNote(String categoryName, _SimpleRandom random) {
    final baseName = categoryName.toLowerCase();
    
    if (baseName.contains('food') || baseName.contains('dining')) {
      final restaurants = ['Pizza Palace', 'Burger King', 'Local Cafe', 'Sushi Express', 'Taco Bell'];
      return restaurants[random.nextInt(restaurants.length)];
    } else if (baseName.contains('gas') || baseName.contains('fuel')) {
      final stations = ['Shell', 'Exxon', 'BP', 'Chevron', 'Local Gas Station'];
      return stations[random.nextInt(stations.length)];
    } else if (baseName.contains('shopping')) {
      final stores = ['Amazon', 'Target', 'Walmart', 'Best Buy', 'Local Store'];
      return stores[random.nextInt(stores.length)];
    } else if (baseName.contains('entertainment')) {
      final activities = ['Movie tickets', 'Concert', 'Game night', 'Streaming service', 'Books'];
      return activities[random.nextInt(activities.length)];
    } else if (baseName.contains('transport')) {
      final transport = ['Uber ride', 'Bus fare', 'Parking', 'Car maintenance', 'Taxi'];
      return transport[random.nextInt(transport.length)];
    } else {
      return null;
    }
  }
  
  /// Clear all sample data
  Future<void> clearAllData() async {
    _expenseService.clearAllExpenses();
    _splitService.clearAllSplitPlans();
    // Note: We don't clear categories as they include defaults
  }
}

/// Simple random number generator for consistent sample data
class _SimpleRandom {
  int _seed;
  
  _SimpleRandom(this._seed);
  
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }
}

/// Sample data utilities
class SampleDataUtils {
  /// Create sample data generator
  static SampleDataGenerator createGenerator(
    ExpenseService expenseService,
    CategoryService categoryService,
    SplitService splitService,
  ) {
    return SampleDataGenerator(expenseService, categoryService, splitService);
  }
  
  /// Quick setup for development/testing
  static Future<void> setupDevelopmentData(
    ExpenseService expenseService,
    CategoryService categoryService,
    SplitService splitService,
  ) async {
    final generator = createGenerator(expenseService, categoryService, splitService);
    await generator.generateSampleData();
  }
  
  /// Reset all data (useful for testing)
  static Future<void> resetAllData(
    ExpenseService expenseService,
    CategoryService categoryService,
    SplitService splitService,
  ) async {
    final generator = createGenerator(expenseService, categoryService, splitService);
    await generator.clearAllData();
    
    // Reinitialize categories
    categoryService.clearAllCategories();
    await categoryService.initialize();
  }
}
