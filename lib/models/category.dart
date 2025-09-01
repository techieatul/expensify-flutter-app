import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final int color;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as int,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Check if this category is deleted (soft delete)
  bool get isDeleted => deletedAt != null;

  /// Get the color as a Flutter Color object
  Color get colorValue => Color(color);

  /// Get the icon as an IconData object
  IconData get iconData {
    return iconFromString(icon);
  }

  /// Static method to convert icon string to IconData
  static IconData iconFromString(String iconName) {
    // Map string icon names to IconData
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'receipt':
        return Icons.receipt;
      case 'movie':
        return Icons.movie;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'pets':
        return Icons.pets;
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'phone':
        return Icons.phone;
      case 'wifi':
        return Icons.wifi;
      case 'electric_bolt':
        return Icons.electric_bolt;
      case 'water_drop':
        return Icons.water_drop;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'checkroom':
        return Icons.checkroom;
      case 'cake':
        return Icons.cake;
      default:
        return Icons.category;
    }
  }

  /// Create a new category
  factory Category.create({
    required String id,
    required String name,
    required String icon,
    required Color color,
    bool isDefault = false,
  }) {
    final now = DateTime.now().toUtc();
    return Category(
      id: id,
      name: name,
      icon: icon,
      color: color.value,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a copy with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Update category
  Category update({
    String? name,
    String? icon,
    Color? color,
  }) {
    return copyWith(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color?.value ?? this.color,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Default categories for seeding
  static List<Category> get defaultCategories => [
        Category.create(
          id: 'food',
          name: 'Food & Dining',
          icon: 'restaurant',
          color: Colors.orange,
          isDefault: true,
        ),
        Category.create(
          id: 'shopping',
          name: 'Shopping',
          icon: 'shopping_cart',
          color: Colors.purple,
          isDefault: true,
        ),
        Category.create(
          id: 'gas',
          name: 'Gas & Fuel',
          icon: 'local_gas_station',
          color: Colors.red,
          isDefault: true,
        ),
        Category.create(
          id: 'home',
          name: 'Home & Garden',
          icon: 'home',
          color: Colors.green,
          isDefault: true,
        ),
        Category.create(
          id: 'car',
          name: 'Auto & Transport',
          icon: 'directions_car',
          color: Colors.blue,
          isDefault: true,
        ),
        Category.create(
          id: 'bills',
          name: 'Bills & Utilities',
          icon: 'receipt',
          color: Colors.brown,
          isDefault: true,
        ),
        Category.create(
          id: 'entertainment',
          name: 'Entertainment',
          icon: 'movie',
          color: Colors.pink,
          isDefault: true,
        ),
        Category.create(
          id: 'healthcare',
          name: 'Healthcare',
          icon: 'medical_services',
          color: Colors.teal,
          isDefault: true,
        ),
        Category.create(
          id: 'education',
          name: 'Education',
          icon: 'school',
          color: Colors.indigo,
          isDefault: true,
        ),
        Category.create(
          id: 'fitness',
          name: 'Fitness & Sports',
          icon: 'fitness_center',
          color: Colors.lime,
          isDefault: true,
        ),
      ];
}
