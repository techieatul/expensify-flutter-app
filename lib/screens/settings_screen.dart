import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../services/providers.dart';
import '../services/theme_provider.dart';
import '../services/backup_service.dart';
import '../services/lifecycle_service.dart';
import '../utils/extensions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _backupService = BackupService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = ref.watch(expensesProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Section
            _buildSectionHeader('App Information'),
            _buildInfoCard(
              icon: Icons.receipt_long,
              title: 'Total Expenses',
              subtitle: '${expenses.length} records',
              trailing: Text(
                expenses.fold<double>(0, (sum, expense) => sum + expense.amount).currency,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              icon: Icons.category,
              title: 'Categories',
              subtitle: '${categories.length} categories',
            ),
            const SizedBox(height: 24),

            // Theme Section
            _buildSectionHeader('Appearance'),
            _buildThemeCard(),
            const SizedBox(height: 24),
            
            // Currency Section
            _buildSectionHeader('Currency'),
            _buildCurrencyCard(),
            const SizedBox(height: 24),

            // Backup & Restore Section
            _buildSectionHeader('Backup & Restore'),
            _buildBackupCard(),
            const SizedBox(height: 24),

            // Data Management Section
            _buildSectionHeader('Data Management'),
            _buildDataManagementCard(),
            const SizedBox(height: 24),

            // File Verification Section
            _buildSectionHeader('File Verification'),
            _buildFileVerificationCard(),
            const SizedBox(height: 24),

            // Backup Preferences
            _buildSectionHeader('Backup Preferences'),
            _buildBackupPreferencesCard(),
            const SizedBox(height: 24),

            // Uninstall Protection
            _buildSectionHeader('Uninstall Protection'),
            _buildUninstallProtectionCard(),
            const SizedBox(height: 24),

            // Danger Zone
            _buildSectionHeader('Danger Zone'),
            _buildDangerZoneCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  Widget _buildThemeCard() {
    final theme = Theme.of(context);
    final themeNotifier = ref.watch(themeModeProvider.notifier);
    final currentMode = ref.watch(themeModeProvider);

    return Card(
      child: ListTile(
        leading: Icon(themeNotifier.themeIcon, color: theme.colorScheme.primary),
        title: const Text('Theme'),
        subtitle: Text('Current: ${themeNotifier.currentThemeName}'),
        trailing: DropdownButton<ThemeMode>(
          value: currentMode,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('System'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Light'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Dark'),
            ),
          ],
          onChanged: (ThemeMode? mode) {
            if (mode != null) {
              themeNotifier.setThemeMode(mode);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCurrencyCard() {
    final currencyService = ref.watch(currencyServiceProvider);
    final currentCurrency = currencyService.currentCurrency;

    return Card(
      child: ListTile(
        leading: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary),
        title: const Text('Currency'),
        subtitle: Text('Current: ${currentCurrency.name} (${currentCurrency.code})'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentCurrency.symbol,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _showCurrencySelector(),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.backup, color: Theme.of(context).colorScheme.primary),
            title: const Text('Create Backup'),
            subtitle: const Text('Export all your data to a file'),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'quick':
                    _showBackupOptionsDialog();
                    break;
                  case 'advanced':
                    _showAdvancedBackupDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'quick',
                  child: ListTile(
                    leading: Icon(Icons.backup),
                    title: Text('Quick Backup'),
                    subtitle: Text('Standard backup options'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'advanced',
                  child: ListTile(
                    leading: Icon(Icons.settings_backup_restore),
                    title: Text('Advanced Options'),
                    subtitle: Text('Custom settings & locations'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            onTap: _showBackupOptionsDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.restore, color: Theme.of(context).colorScheme.primary),
            title: const Text('Restore from Backup'),
            subtitle: const Text('Import data from a backup file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _restoreFromBackup,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
            title: const Text('Auto Backup Settings'),
            subtitle: Text(ref.read(lifecycleServiceProvider).autoBackupEnabled 
                ? 'Automatic backups enabled' 
                : 'Automatic backups disabled'),
            trailing: Switch(
              value: ref.read(lifecycleServiceProvider).autoBackupEnabled,
              onChanged: (value) async {
                if (value) {
                  await ref.read(lifecycleServiceProvider).enableAutoBackup();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Auto-backup enabled. Backups will be created automatically.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  await ref.read(lifecycleServiceProvider).disableAutoBackup();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Auto-backup disabled. Create manual backups to protect your data.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
                setState(() {});
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            title: const Text('View Auto Backups'),
            subtitle: const Text('Browse and restore automatic backups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAutoBackupsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.delete_sweep, color: Theme.of(context).colorScheme.primary),
            title: const Text('Delete Records'),
            subtitle: const Text('Remove expense records by date range'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showDeleteOptionsDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
            title: const Text('Delete Monthly Records'),
            subtitle: const Text('Remove all records for a specific month'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showDeleteMonthDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildFileVerificationCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.folder_open, color: Theme.of(context).colorScheme.primary),
            title: const Text('Check Downloads Folder'),
            subtitle: const Text('Verify backup files in Downloads'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _checkDownloadsFolder,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
            title: const Text('Find Backup Files'),
            subtitle: const Text('Search for all backup files on device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _findBackupFiles,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupPreferencesCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
            title: const Text('Backup Reminders'),
            subtitle: const Text('Show reminders to create backups regularly'),
            value: ref.read(lifecycleServiceProvider).backupRemindersEnabled,
            onChanged: (value) async {
              if (value) {
                await ref.read(lifecycleServiceProvider).enableBackupReminders();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup reminders enabled'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                await ref.read(lifecycleServiceProvider).disableBackupReminders();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup reminders disabled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
              setState(() {});
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Auto-backup: ${ref.read(lifecycleServiceProvider).autoBackupEnabled ? "ON" : "OFF"} • '
                    'Reminders: ${ref.read(lifecycleServiceProvider).backupRemindersEnabled ? "ON" : "OFF"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUninstallProtectionCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.shield,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Before Uninstalling App',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Important: Create a backup to protect your data',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => LifecycleService.showUninstallWarning(context),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap above before uninstalling to get backup instructions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: Icon(
          Icons.warning,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          'Delete All Data',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Permanently delete all expenses and split plans',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.error,
        ),
        onTap: _showDeleteAllDialog,
      ),
    );
  }

  void _showDeleteOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => _DeleteRangeDialog(
        onDelete: _deleteRecordsInRange,
      ),
    );
  }

  void _showDeleteMonthDialog() {
    showDialog(
      context: context,
      builder: (context) => _DeleteMonthDialog(
        onDelete: _deleteRecordsForMonth,
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete ALL expenses, split plans, and related data. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAllData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecordsInRange(DateTime startDate, DateTime endDate) async {
    try {
      final expenseService = ref.read(expenseServiceProvider);
      final splitService = ref.read(splitServiceProvider);

      // Get expenses in range
      final expensesToDelete = expenseService.getExpensesForDateRange(startDate, endDate);
      
      // Delete expenses
      for (final expense in expensesToDelete) {
        await expenseService.permanentlyDeleteExpense(expense.id);
      }

      // Delete split plans that fall within the range
      final splitPlans = splitService.getAllSplitPlans();
      for (final splitPlan in splitPlans) {
        if (splitPlan.startMonth.isAfter(startDate.subtract(const Duration(days: 1))) &&
            splitPlan.startMonth.isBefore(endDate.add(const Duration(days: 1)))) {
          await splitService.deleteSplitPlan(splitPlan.id);
        }
      }

      // Refresh providers
      ref.invalidate(expensesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${expensesToDelete.length} records'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecordsForMonth(DateTime month) async {
    try {
      final expenseService = ref.read(expenseServiceProvider);
      final splitService = ref.read(splitServiceProvider);

      // Get expenses for the month
      final expensesToDelete = expenseService.getExpensesForMonth(month);
      
      // Delete expenses
      for (final expense in expensesToDelete) {
        await expenseService.permanentlyDeleteExpense(expense.id);
      }

      // Delete split plans that start in this month
      final splitPlans = splitService.getAllSplitPlans();
      for (final splitPlan in splitPlans) {
        if (splitPlan.startMonth.year == month.year && 
            splitPlan.startMonth.month == month.month) {
          await splitService.deleteSplitPlan(splitPlan.id);
        }
      }

      // Refresh providers
      ref.invalidate(expensesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${expensesToDelete.length} records from ${month.monthYear}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllData() async {
    try {
      final expenseService = ref.read(expenseServiceProvider);
      final splitService = ref.read(splitServiceProvider);

      // Clear all data
      await expenseService.clearAllExpenses();
      
      // Clear all split plans
      final splitPlans = splitService.getAllSplitPlans();
      for (final splitPlan in splitPlans) {
        await splitService.deleteSplitPlan(splitPlan.id);
      }

      // Refresh providers
      ref.invalidate(expensesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Backup & Restore Methods
  void _showBackupOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup'),
        content: const Text('Choose how you want to save your backup:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveBackupToDownloads();
            },
            child: const Text('Downloads'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveBackupToCustomLocation();
            },
            child: const Text('Share & Save'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shareBackup();
            },
            child: const Text('Share Only'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareBackup() async {
    try {
      await _backupService.shareBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup file shared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveBackupToDownloads() async {
    try {
      final filePath = await _backupService.saveBackupToDownloads();
      
      // Verify file exists
      final file = File(filePath);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup saved to Downloads\n'
              'File: ${filePath.split('/').last}\n'
              'Size: ${(size / 1024).toStringAsFixed(1)} KB\n'
              'Exists: ${exists ? "✓" : "✗"}'
            ),
            backgroundColor: exists ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View Path',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Backup File Location'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Full Path:'),
                        SelectableText(filePath),
                        const SizedBox(height: 16),
                        Text('File exists: ${exists ? "Yes" : "No"}'),
                        Text('File size: ${(size / 1024).toStringAsFixed(1)} KB'),
                        const SizedBox(height: 16),
                        const Text(
                          'To find this file:\n'
                          '1. Open Files app\n'
                          '2. Go to Downloads folder\n'
                          '3. Look for expensify_backup_*.json',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveBackupToCustomLocation() async {
    try {
      final filePath = await _backupService.saveBackupToCustomLocation();
      
      if (filePath == null) {
        // User cancelled the save dialog
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup created and shared! Choose where to save it.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Info',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Backup Shared'),
                    content: const Text(
                      'Your backup file has been created and shared. You can now save it to:\n\n'
                      '• Google Drive\n'
                      '• Dropbox\n'
                      '• Email to yourself\n'
                      '• Any file manager app\n'
                      '• Cloud storage service\n\n'
                      'Choose your preferred location from the share menu.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromBackup() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore from Backup'),
          content: const Text(
            'This will replace ALL current data with the backup data. This action cannot be undone.\n\nAre you sure you want to continue?',
          ),
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
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _backupService.importFromFile();
        
        // Refresh all providers
        ref.invalidate(expensesProvider);
        ref.invalidate(categoriesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAutoBackupsDialog() {
    showDialog(
      context: context,
      builder: (context) => _AutoBackupsDialog(backupService: _backupService),
    );
  }

  void _showAdvancedBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => _AdvancedBackupDialog(backupService: _backupService),
    );
  }

  Future<void> _checkDownloadsFolder() async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      
      if (!await downloadsDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Downloads folder not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final files = downloadsDir.listSync()
          .where((file) => file.path.contains('expensify_backup') && file.path.endsWith('.json'))
          .toList();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Downloads Folder (${files.length} backups found)'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: files.isEmpty
                  ? const Center(child: Text('No backup files found in Downloads'))
                  : ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final stat = file.statSync();
                        return ListTile(
                          leading: const Icon(Icons.backup),
                          title: Text(file.path.split('/').last),
                          subtitle: Text(
                            'Size: ${(stat.size / 1024).toStringAsFixed(1)} KB\n'
                            'Modified: ${stat.modified.displayDate}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.info),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('File Details'),
                                  content: SelectableText(
                                    'Path: ${file.path}\n'
                                    'Size: ${stat.size} bytes\n'
                                    'Modified: ${stat.modified}\n'
                                    'Type: ${stat.type}',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking Downloads: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _findBackupFiles() async {
    try {
      // Check multiple common locations
      final locations = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0',
      ];

      final foundFiles = <String>[];

      for (final location in locations) {
        try {
          final dir = Directory(location);
          if (await dir.exists()) {
            final files = dir.listSync(recursive: true)
                .where((file) => 
                    file is File && 
                    file.path.contains('expensify_backup') && 
                    file.path.endsWith('.json'))
                .toList();
            
            foundFiles.addAll(files.map((f) => f.path));
          }
        } catch (e) {
          // Skip directories we can't access
          continue;
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Backup Files Found (${foundFiles.length})'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: foundFiles.isEmpty
                  ? const Center(child: Text('No backup files found on device'))
                  : ListView.builder(
                      itemCount: foundFiles.length,
                      itemBuilder: (context, index) {
                        final filePath = foundFiles[index];
                        final file = File(filePath);
                        final stat = file.statSync();
                        
                        return ListTile(
                          leading: const Icon(Icons.backup),
                          title: Text(filePath.split('/').last),
                          subtitle: Text(
                            'Location: ${filePath.split('/').take(filePath.split('/').length - 1).join('/')}\n'
                            'Size: ${(stat.size / 1024).toStringAsFixed(1)} KB',
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('File Location'),
                                content: SelectableText(filePath),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCurrencySelector() async {
    final currencyService = ref.read(currencyServiceProvider);
    final currentCurrency = currencyService.currentCurrency;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Select Currency',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Popular currencies section
            Text(
              'Popular',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Popular currencies grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currencyService.popularCurrencies.map((currency) {
                final isSelected = currencyService.isCurrencySelected(currency);
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) async {
                    if (selected) {
                      await currencyService.setCurrentCurrency(currency);
                      setState(() {});
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Currency changed to ${currency.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  avatar: Text(
                    currency.symbol,
                    style: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  label: Text('${currency.code} - ${currency.name}'),
                  backgroundColor: currency == currentCurrency 
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // All currencies section
            Text(
              'All Currencies',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            // All currencies list
            Expanded(
              child: ListView.builder(
                itemCount: currencyService.availableCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = currencyService.availableCurrencies[index];
                  final isSelected = currencyService.isCurrencySelected(currency);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(currency.name),
                    subtitle: Text(currency.code),
                    trailing: isSelected 
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () async {
                      await currencyService.setCurrentCurrency(currency);
                      setState(() {});
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Currency changed to ${currency.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoBackupsDialog extends StatefulWidget {
  final BackupService backupService;

  const _AutoBackupsDialog({required this.backupService});

  @override
  State<_AutoBackupsDialog> createState() => _AutoBackupsDialogState();
}

class _AutoBackupsDialogState extends State<_AutoBackupsDialog> {
  List<Map<String, dynamic>>? _backups;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAutoBackups();
  }

  Future<void> _loadAutoBackups() async {
    try {
      final backups = await widget.backupService.getAutoBackups();
      if (mounted) {
        setState(() {
          _backups = backups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backups = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Auto Backups'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _backups == null || _backups!.isEmpty
                ? const Center(
                    child: Text('No auto backups found'),
                  )
                : ListView.builder(
                    itemCount: _backups!.length,
                    itemBuilder: (context, index) {
                      final backup = _backups![index];
                      final modified = backup['modified'] as DateTime;
                      final metadata = backup['metadata'] as Map<String, dynamic>;
                      
                      return ListTile(
                        leading: const Icon(Icons.backup),
                        title: Text(backup['name']),
                        subtitle: Text(
                          'Created: ${modified.displayDate}\n'
                          'Expenses: ${metadata['totalExpenses'] ?? 0}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.restore),
                          onPressed: () => _restoreAutoBackup(backup['path']),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _restoreAutoBackup(String backupPath) async {
    try {
      Navigator.of(context).pop(); // Close dialog
      
      await widget.backupService.restoreAutoBackup(backupPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto backup restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore auto backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AdvancedBackupDialog extends StatefulWidget {
  final BackupService backupService;

  const _AdvancedBackupDialog({required this.backupService});

  @override
  State<_AdvancedBackupDialog> createState() => _AdvancedBackupDialogState();
}

class _AdvancedBackupDialogState extends State<_AdvancedBackupDialog> {
  String _selectedLocation = 'downloads';
  String? _customPath;
  bool _includeSettings = true;
  bool _includeCategories = true;
  bool _includeExpenses = true;
  bool _includeSplitPlans = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Advanced Backup Options'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Save Location Section
              Text(
                'Save Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Downloads Folder'),
                subtitle: const Text('/storage/emulated/0/Download/'),
                value: 'downloads',
                groupValue: _selectedLocation,
                onChanged: (value) => setState(() => _selectedLocation = value!),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('Choose Custom Folder'),
                subtitle: _customPath != null 
                    ? Text(_customPath!, style: const TextStyle(fontSize: 12))
                    : const Text('Tap to select folder'),
                value: 'custom',
                groupValue: _selectedLocation,
                onChanged: (value) {
                  setState(() => _selectedLocation = value!);
                  if (value == 'custom') {
                    _selectCustomLocation();
                  }
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('Share File'),
                subtitle: const Text('Send via email, cloud storage, etc.'),
                value: 'share',
                groupValue: _selectedLocation,
                onChanged: (value) => setState(() => _selectedLocation = value!),
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              
              // Data Selection Section
              Text(
                'Data to Include',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Expenses'),
                subtitle: const Text('All expense records'),
                value: _includeExpenses,
                onChanged: (value) => setState(() => _includeExpenses = value!),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Categories'),
                subtitle: const Text('Custom and default categories'),
                value: _includeCategories,
                onChanged: (value) => setState(() => _includeCategories = value!),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Split Plans'),
                subtitle: const Text('Multi-month expense splits'),
                value: _includeSplitPlans,
                onChanged: (value) => setState(() => _includeSplitPlans = value!),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Settings'),
                subtitle: const Text('App preferences and theme'),
                value: _includeSettings,
                onChanged: (value) => setState(() => _includeSettings = value!),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canCreateBackup() ? _createAdvancedBackup : null,
          child: const Text('Create Backup'),
        ),
      ],
    );
  }

  bool _canCreateBackup() {
    return _includeExpenses || _includeCategories || _includeSplitPlans || _includeSettings;
  }

  Future<void> _selectCustomLocation() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Backup Location',
      );
      
      if (result != null) {
        setState(() => _customPath = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createAdvancedBackup() async {
    try {
      Navigator.of(context).pop(); // Close dialog
      
      String? filePath;
      
      switch (_selectedLocation) {
        case 'downloads':
          filePath = await widget.backupService.saveBackupToDownloads();
          break;
        case 'custom':
          if (_customPath != null) {
            final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
            final fileName = 'expensify_backup_$timestamp.json';
            filePath = await widget.backupService.saveBackupWithOptions(
              customPath: '$_customPath/$fileName',
            );
          }
          break;
        case 'share':
          await widget.backupService.shareBackup();
          return;
      }

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Advanced backup created: ${filePath.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Path',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Backup Location'),
                    content: SelectableText(filePath!),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _DeleteRangeDialog extends StatefulWidget {
  final Function(DateTime startDate, DateTime endDate) onDelete;

  const _DeleteRangeDialog({required this.onDelete});

  @override
  State<_DeleteRangeDialog> createState() => _DeleteRangeDialogState();
}

class _DeleteRangeDialogState extends State<_DeleteRangeDialog> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Records by Date Range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Start Date'),
            subtitle: Text(_startDate.displayDate),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(true),
          ),
          ListTile(
            title: const Text('End Date'),
            subtitle: Text(_endDate.displayDate),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(false),
          ),
          const SizedBox(height: 16),
          Text(
            'This will delete all expenses between ${_startDate.displayDate} and ${_endDate.displayDate}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _startDate.isBefore(_endDate.add(const Duration(days: 1)))
              ? () {
                  Navigator.of(context).pop();
                  widget.onDelete(_startDate, _endDate);
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
}

class _DeleteMonthDialog extends StatefulWidget {
  final Function(DateTime month) onDelete;

  const _DeleteMonthDialog({required this.onDelete});

  @override
  State<_DeleteMonthDialog> createState() => _DeleteMonthDialogState();
}

class _DeleteMonthDialogState extends State<_DeleteMonthDialog> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Monthly Records'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Select Month'),
            subtitle: Text(_selectedMonth.monthYear),
            trailing: const Icon(Icons.calendar_month),
            onTap: _selectMonth,
          ),
          const SizedBox(height: 16),
          Text(
            'This will delete all expenses from ${_selectedMonth.monthYear}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDelete(_selectedMonth);
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }
}