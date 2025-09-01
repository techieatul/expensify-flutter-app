import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/constants.dart';

/// Service for managing expense categories
class CategoryService {
  static const _uuid = Uuid();
  
  // Hive box for storing categories
  Box get _categoriesBox => Hive.box(AppConstants.categoriesBox);
  bool _isInitialized = false;
  
  /// Initialize with default categories
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Add default categories if none exist in Hive
    if (_categoriesBox.isEmpty) {
      for (final category in Category.defaultCategories) {
        await _categoriesBox.put(category.id, category.toJson());
      }
    }
    
    _isInitialized = true;
  }
  
  /// Get all active categories
  List<Category> getAllCategories() {
    final categoriesData = _categoriesBox.values.toList();
    final categories = categoriesData
        .map((data) => Category.fromJson(Map<String, dynamic>.from(data)))
        .where((category) => !category.isDeleted)
        .toList()
      ..sort((a, b) {
        // Default categories first, then by name
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });
    return categories;
  }
  
  /// Get category by ID
  Category? getCategoryById(String categoryId) {
    try {
      final categoryData = _categoriesBox.get(categoryId);
      if (categoryData == null) return null;
      
      final category = Category.fromJson(Map<String, dynamic>.from(categoryData));
      return category.isDeleted ? null : category;
    } catch (e) {
      return null;
    }
  }
  
  /// Get category by name
  Category? getCategoryByName(String name) {
    try {
      final allCategories = getAllCategories();
      return allCategories.firstWhere((c) => 
          c.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }
  
  /// Add a new category
  Future<Category> addCategory({
    required String name,
    required String icon,
    required Color color,
  }) async {
    // Check if category with same name already exists
    if (getCategoryByName(name) != null) {
      throw Exception('Category with name "$name" already exists');
    }
    
    final category = Category.create(
      id: _uuid.v4(),
      name: name.trim(),
      icon: icon,
      color: color,
      isDefault: false,
    );
    
    // Save to Hive
    await _categoriesBox.put(category.id, category.toJson());
    
    return category;
  }
  
  /// Update an existing category
  Future<Category> updateCategory(
    String categoryId, {
    String? name,
    String? icon,
    Color? color,
  }) async {
    final categoryData = _categoriesBox.get(categoryId);
    if (categoryData == null) {
      throw Exception('Category not found');
    }
    
    final existingCategory = Category.fromJson(Map<String, dynamic>.from(categoryData));
    if (existingCategory.isDeleted) {
      throw Exception('Category not found');
    }
    
    // Check if new name conflicts with existing category
    if (name != null && name.trim() != existingCategory.name) {
      final conflicting = getCategoryByName(name.trim());
      if (conflicting != null && conflicting.id != categoryId) {
        throw Exception('Category with name "$name" already exists');
      }
    }
    
    final updatedCategory = existingCategory.update(
      name: name?.trim(),
      icon: icon,
      color: color,
    );
    
    // Save to Hive
    await _categoriesBox.put(categoryId, updatedCategory.toJson());
    
    return updatedCategory;
  }
  
  /// Delete a category (soft delete)
  Future<void> deleteCategory(String categoryId) async {
    final categoryData = _categoriesBox.get(categoryId);
    if (categoryData == null) {
      throw Exception('Category not found');
    }
    
    final category = Category.fromJson(Map<String, dynamic>.from(categoryData));
    if (category.isDeleted) {
      throw Exception('Category not found');
    }
    
    // Prevent deletion of default categories
    if (category.isDefault) {
      throw Exception('Cannot delete default category');
    }
    
    final deletedCategory = category.copyWith(
      deletedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    
    // Save to Hive
    await _categoriesBox.put(categoryId, deletedCategory.toJson());
    
    // TODO: Handle existing expenses with this category (reassign or mark as "Unknown")
  }
  
  /// Restore a deleted category
  Future<Category> restoreCategory(String categoryId) async {
    final categoryData = _categoriesBox.get(categoryId);
    if (categoryData == null) {
      throw Exception('Deleted category not found');
    }
    
    final category = Category.fromJson(Map<String, dynamic>.from(categoryData));
    if (!category.isDeleted) {
      throw Exception('Category is not deleted');
    }
    
    final restoredCategory = category.copyWith(
      deletedAt: null,
      updatedAt: DateTime.now().toUtc(),
    );
    
    // Save to Hive
    await _categoriesBox.put(categoryId, restoredCategory.toJson());
    
    return restoredCategory;
  }
  
  /// Get categories used in expenses (for analytics)
  List<Category> getCategoriesUsedInExpenses(List<String> categoryIds) {
    final usedCategoryIds = categoryIds.toSet();
    final allCategories = getAllCategories();
    return allCategories
        .where((category) => usedCategoryIds.contains(category.id))
        .toList();
  }
  
  /// Get most used categories
  List<Category> getMostUsedCategories(Map<String, int> categoryUsageCount, {int limit = 5}) {
    final sortedEntries = categoryUsageCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategoryIds = sortedEntries
        .take(limit)
        .map((entry) => entry.key)
        .toList();
    
    return topCategoryIds
        .map((id) => getCategoryById(id))
        .where((category) => category != null)
        .cast<Category>()
        .toList();
  }
  
  /// Search categories by name
  List<Category> searchCategories(String query) {
    final lowercaseQuery = query.toLowerCase().trim();
    if (lowercaseQuery.isEmpty) return getAllCategories();
    
    final allCategories = getAllCategories();
    return allCategories
        .where((category) => 
            category.name.toLowerCase().contains(lowercaseQuery))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  
  /// Get available icons for categories
  static List<String> getAvailableIcons() {
    return [
      'restaurant',
      'shopping_cart',
      'local_gas_station',
      'home',
      'directions_car',
      'receipt',
      'movie',
      'medical_services',
      'school',
      'fitness_center',
      'pets',
      'flight',
      'hotel',
      'phone',
      'wifi',
      'electric_bolt',
      'water_drop',
      'local_laundry_service',
      'checkroom',
      'cake',
      'coffee',
      'local_grocery_store',
      'local_pharmacy',
      'local_hospital',
      'train',
      'directions_bus',
      'local_taxi',
      'sports_soccer',
      'music_note',
      'book',
      'computer',
      'smartphone',
      'camera',
      'headphones',
      'watch',
      'brush',
      'content_cut',
      'spa',
      'beach_access',
      'park',
      'local_florist',
      'celebration',
      'card_giftcard',
      'volunteer_activism',
      'savings',
      'account_balance',
      'credit_card',
      'payment',
      'attach_money',
    ];
  }
  
  /// Get available colors for categories
  static List<Color> getAvailableColors() {
    return [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];
  }
  
  /// Validate category data
  static String? validateCategoryName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Category name cannot be empty';
    }
    if (trimmed.length > 50) {
      return 'Category name cannot exceed 50 characters';
    }
    return null;
  }
  
  /// Check if category is in use by expenses
  Future<bool> isCategoryInUse(String categoryId) async {
    // TODO: Check with ExpenseService if any expenses use this category
    // For now, return false
    return false;
  }
  
  /// Clear all categories (for testing/reset)
  Future<void> clearAllCategories() async {
    await _categoriesBox.clear();
    _isInitialized = false;
  }
}
