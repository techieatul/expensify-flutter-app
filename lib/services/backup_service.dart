import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/constants.dart';
import '../models/models.dart';

/// Service for backing up and restoring app data
class BackupService {
  /// Export all data to JSON format
  Future<Map<String, dynamic>> exportAllData() async {
    final expensesBox = Hive.box(AppConstants.expensesBox);
    final categoriesBox = Hive.box(AppConstants.categoriesBox);
    final splitPlansBox = Hive.box(AppConstants.splitPlansBox);
    final settingsBox = Hive.box(AppConstants.settingsBox);

    return {
      'version': '1.0',
      'exportDate': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'expenses': expensesBox.values.toList(),
        'categories': categoriesBox.values.toList(),
        'splitPlans': splitPlansBox.values.toList(),
        'settings': settingsBox.toMap(),
      },
      'metadata': {
        'totalExpenses': expensesBox.length,
        'totalCategories': categoriesBox.length,
        'totalSplitPlans': splitPlansBox.length,
        'appVersion': '1.0.0',
      }
    };
  }

  /// Create backup file and share it
  Future<String> createBackupFile() async {
    try {
      // Export data
      final backupData = await exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Create backup file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'expensify_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to create backup file: $e');
    }
  }

  /// Share backup file
  Future<void> shareBackup() async {
    try {
      final filePath = await createBackupFile();
      final file = File(filePath);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Expensify Data Backup',
        text: 'Backup of your Expensify expense data. Keep this file safe!',
      );
    } catch (e) {
      throw Exception('Failed to share backup: $e');
    }
  }

  /// Save backup to Downloads folder
  Future<String> saveBackupToDownloads() async {
    try {
      final backupData = await exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Get Downloads directory
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'expensify_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save backup to Downloads: $e');
    }
  }

  /// Save backup to user-selected location (Android compatible)
  Future<String?> saveBackupToCustomLocation() async {
    try {
      // Create backup data first
      final backupData = await exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Generate default filename
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'expensify_backup_$timestamp.json';

      // Create temporary file first
      final directory = await getApplicationDocumentsDirectory();
      final tempFile = File('${directory.path}/$fileName');
      await tempFile.writeAsString(jsonString);

      // Use share to let user choose location (more reliable on Android)
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Expensify Backup - $fileName',
        text: 'Save this backup file to your preferred location.',
      );

      // Clean up temp file after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });

      return tempFile.path;
    } catch (e) {
      throw Exception('Failed to save backup to custom location: $e');
    }
  }

  /// Alternative method using directory picker (may not work on all Android versions)
  Future<String?> saveBackupToSelectedDirectory() async {
    try {
      // Generate default filename
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'expensify_backup_$timestamp.json';

      // Let user choose save directory
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose Backup Folder',
      );

      if (result == null) {
        return null; // User cancelled
      }

      // Create backup data and save to selected directory
      final backupData = await exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save to selected location
      final file = File('$result/$fileName');
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save backup to selected directory: $e');
    }
  }

  /// Save backup with location options
  Future<String?> saveBackupWithOptions({
    String? customPath,
    bool useDownloads = false,
  }) async {
    if (useDownloads) {
      return await saveBackupToDownloads();
    } else if (customPath != null) {
      try {
        final backupData = await exportAllData();
        final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
        
        final file = File(customPath);
        await file.writeAsString(jsonString);
        return file.path;
      } catch (e) {
        throw Exception('Failed to save backup to custom path: $e');
      }
    } else {
      return await saveBackupToCustomLocation();
    }
  }

  /// Import data from backup file
  Future<void> importFromFile() async {
    try {
      // Pick backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      await _restoreFromBackupData(backupData);
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  /// Restore data from backup JSON
  Future<void> _restoreFromBackupData(Map<String, dynamic> backupData) async {
    try {
      // Validate backup format
      if (!backupData.containsKey('data') || !backupData.containsKey('version')) {
        throw Exception('Invalid backup file format');
      }

      final data = backupData['data'] as Map<String, dynamic>;

      // Get Hive boxes
      final expensesBox = Hive.box(AppConstants.expensesBox);
      final categoriesBox = Hive.box(AppConstants.categoriesBox);
      final splitPlansBox = Hive.box(AppConstants.splitPlansBox);
      final settingsBox = Hive.box(AppConstants.settingsBox);

      // Clear existing data
      await expensesBox.clear();
      await categoriesBox.clear();
      await splitPlansBox.clear();
      await settingsBox.clear();

      // Restore expenses
      if (data.containsKey('expenses')) {
        final expenses = data['expenses'] as List;
        for (final expenseData in expenses) {
          final expense = Expense.fromJson(Map<String, dynamic>.from(expenseData));
          await expensesBox.put(expense.id, expense.toJson());
        }
      }

      // Restore categories
      if (data.containsKey('categories')) {
        final categories = data['categories'] as List;
        for (final categoryData in categories) {
          final category = Category.fromJson(Map<String, dynamic>.from(categoryData));
          await categoriesBox.put(category.id, category.toJson());
        }
      }

      // Restore split plans
      if (data.containsKey('splitPlans')) {
        final splitPlans = data['splitPlans'] as List;
        for (final splitPlanData in splitPlans) {
          final splitPlan = SplitPlan.fromJson(Map<String, dynamic>.from(splitPlanData));
          await splitPlansBox.put(splitPlan.id, splitPlan.toJson());
        }
      }

      // Restore settings
      if (data.containsKey('settings')) {
        final settings = data['settings'] as Map<String, dynamic>;
        for (final entry in settings.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
      }
    } catch (e) {
      throw Exception('Failed to restore backup data: $e');
    }
  }

  /// Get backup file info
  Future<Map<String, dynamic>> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      return {
        'version': backupData['version'] ?? 'Unknown',
        'exportDate': backupData['exportDate'] ?? 'Unknown',
        'metadata': backupData['metadata'] ?? {},
      };
    } catch (e) {
      throw Exception('Failed to read backup info: $e');
    }
  }

  /// Auto-backup on app close (optional)
  Future<void> createAutoBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/auto_backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Keep only last 5 auto-backups
      final existingBackups = backupDir.listSync()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      // Delete old backups (keep 5)
      if (existingBackups.length >= 5) {
        for (int i = 4; i < existingBackups.length; i++) {
          await existingBackups[i].delete();
        }
      }

      // Create new auto-backup
      final backupData = await exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'auto_backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');

      await file.writeAsString(jsonString);
    } catch (e) {
      // Silent fail for auto-backup
      debugPrint('Auto-backup failed: $e');
    }
  }

  /// List available auto-backups
  Future<List<Map<String, dynamic>>> getAutoBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/auto_backups');
      
      if (!await backupDir.exists()) {
        return [];
      }

      final backupFiles = backupDir.listSync()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      final backups = <Map<String, dynamic>>[];
      
      for (final file in backupFiles) {
        try {
          final info = await getBackupInfo(file.path);
          backups.add({
            'path': file.path,
            'name': file.path.split('/').last,
            'size': file.statSync().size,
            'modified': file.statSync().modified,
            ...info,
          });
        } catch (e) {
          // Skip corrupted backup files
          continue;
        }
      }

      return backups;
    } catch (e) {
      return [];
    }
  }

  /// Restore from auto-backup
  Future<void> restoreAutoBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      await _restoreFromBackupData(backupData);
    } catch (e) {
      throw Exception('Failed to restore auto-backup: $e');
    }
  }
}
