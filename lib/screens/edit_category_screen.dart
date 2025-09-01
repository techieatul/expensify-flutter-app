import 'package:flutter/material.dart';

/// Screen for editing an existing category
class EditCategoryScreen extends StatelessWidget {
  final String categoryId;
  
  const EditCategoryScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
      ),
      body: Center(
        child: Text('Edit Category Screen - ID: $categoryId'),
      ),
    );
  }
}
