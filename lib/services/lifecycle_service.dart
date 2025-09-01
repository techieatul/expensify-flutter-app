import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import 'backup_service.dart';

/// Service to handle app lifecycle events and backup reminders
class LifecycleService with WidgetsBindingObserver {
  static const String _lastBackupKey = 'last_backup_date';
  static const String _backupReminderKey = 'backup_reminder_enabled';
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _appLaunchCountKey = 'app_launch_count';
  
  // Singleton pattern
  static LifecycleService? _instance;
  static LifecycleService get instance {
    _instance ??= LifecycleService._internal();
    return _instance!;
  }
  
  LifecycleService._internal();
  
  // Factory constructor that returns the singleton instance
  factory LifecycleService() => instance;
  
  final BackupService _backupService = BackupService();
  late Box _settingsBox;
  bool _isInitialized = false;
  
  /// Initialize the lifecycle service
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent double initialization
    
    _settingsBox = Hive.box(AppConstants.settingsBox);
    WidgetsBinding.instance.addObserver(this);
    
    // Track app launches
    await _trackAppLaunch();
    
    // Check if backup reminder is needed
    await _checkBackupReminder();
    
    _isInitialized = true;
  }

  /// Dispose the lifecycle service
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App is going to background
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        _onAppDetached();
        break;
      case AppLifecycleState.resumed:
        // App is coming back to foreground
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., during phone call)
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  /// Handle app being paused (going to background)
  void _onAppPaused() {
    // Create auto-backup when app goes to background
    _createAutoBackupIfNeeded();
  }

  /// Handle app being detached (terminated)
  void _onAppDetached() {
    // Last chance to create backup before app closes
    _createEmergencyBackup();
  }

  /// Handle app being resumed (coming back from background)
  void _onAppResumed() {
    // Check if backup reminder is needed
    _checkBackupReminder();
  }

  /// Track app launches to show backup reminders
  Future<void> _trackAppLaunch() async {
    final currentCount = _settingsBox.get(_appLaunchCountKey, defaultValue: 0) as int;
    await _settingsBox.put(_appLaunchCountKey, currentCount + 1);
  }

  /// Check if backup reminder should be shown
  Future<void> _checkBackupReminder() async {
    final reminderEnabled = _settingsBox.get(_backupReminderKey, defaultValue: true) as bool;
    if (!reminderEnabled) return;

    final lastBackupStr = _settingsBox.get(_lastBackupKey) as String?;
    final launchCount = _settingsBox.get(_appLaunchCountKey, defaultValue: 0) as int;
    
    DateTime? lastBackup;
    if (lastBackupStr != null) {
      lastBackup = DateTime.tryParse(lastBackupStr);
    }

    // Show reminder if:
    // 1. Never backed up and launched 5+ times
    // 2. Last backup was more than 7 days ago
    // 3. Every 20 launches as a safety reminder
    
    bool shouldRemind = false;
    String reminderMessage = '';

    if (lastBackup == null && launchCount >= 5) {
      shouldRemind = true;
      reminderMessage = 'You haven\'t created a backup yet. Create one now to protect your data!';
    } else if (lastBackup != null) {
      final daysSinceBackup = DateTime.now().difference(lastBackup).inDays;
      if (daysSinceBackup >= 7) {
        shouldRemind = true;
        reminderMessage = 'Your last backup was $daysSinceBackup days ago. Consider creating a new backup.';
      }
    }

    if (launchCount % 20 == 0 && launchCount > 0) {
      shouldRemind = true;
      reminderMessage = 'Regular backup reminder: Keep your data safe with regular backups!';
    }

    if (shouldRemind) {
      _showBackupReminder(reminderMessage);
    }
  }

  /// Show backup reminder dialog
  void _showBackupReminder(String message) {
    // We need a context to show dialog, so we'll use a global navigator key
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.orange),
            SizedBox(width: 8),
            Text('Backup Reminder'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'Creating regular backups protects your data from:\n'
              '• App uninstallation\n'
              '• Device loss or damage\n'
              '• Data corruption\n'
              '• Factory resets',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _disableBackupReminders();
            },
            child: const Text('Don\'t remind me'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToBackupScreen();
            },
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }

  /// Create auto-backup when app goes to background (only if enabled)
  Future<void> _createAutoBackupIfNeeded() async {
    // Check if auto-backup is enabled
    final autoBackupEnabled = _settingsBox.get(_autoBackupKey, defaultValue: false) as bool;
    if (!autoBackupEnabled) return;

    try {
      final lastBackupStr = _settingsBox.get(_lastBackupKey) as String?;
      DateTime? lastBackup;
      if (lastBackupStr != null) {
        lastBackup = DateTime.tryParse(lastBackupStr);
      }

      // Create auto-backup if last backup was more than 24 hours ago
      if (lastBackup == null || DateTime.now().difference(lastBackup).inHours >= 24) {
        await _backupService.createAutoBackup();
        await _updateLastBackupDate();
      }
    } catch (e) {
      // Silent fail for auto-backup
      debugPrint('Auto-backup failed: $e');
    }
  }

  /// Create emergency backup when app is being terminated (only if enabled)
  Future<void> _createEmergencyBackup() async {
    // Check if auto-backup is enabled
    final autoBackupEnabled = _settingsBox.get(_autoBackupKey, defaultValue: false) as bool;
    if (!autoBackupEnabled) return;

    try {
      // Quick backup without user interaction
      await _backupService.createAutoBackup();
      await _updateLastBackupDate();
    } catch (e) {
      // Silent fail for emergency backup
      debugPrint('Emergency backup failed: $e');
    }
  }

  /// Update last backup date
  Future<void> _updateLastBackupDate() async {
    await _settingsBox.put(_lastBackupKey, DateTime.now().toIso8601String());
  }

  /// Enable backup reminders
  Future<void> enableBackupReminders() async {
    await _settingsBox.put(_backupReminderKey, true);
  }

  /// Disable backup reminders
  Future<void> disableBackupReminders() async {
    await _settingsBox.put(_backupReminderKey, false);
  }

  /// Check if backup reminders are enabled
  bool get backupRemindersEnabled {
    return _settingsBox.get(_backupReminderKey, defaultValue: true) as bool;
  }

  /// Private method for internal use
  Future<void> _disableBackupReminders() async {
    await _settingsBox.put(_backupReminderKey, false);
  }

  /// Enable auto-backup
  Future<void> enableAutoBackup() async {
    await _settingsBox.put(_autoBackupKey, true);
  }

  /// Disable auto-backup
  Future<void> disableAutoBackup() async {
    await _settingsBox.put(_autoBackupKey, false);
  }

  /// Check if auto-backup is enabled
  bool get autoBackupEnabled {
    return _settingsBox.get(_autoBackupKey, defaultValue: false) as bool;
  }

  /// Get last backup date
  DateTime? get lastBackupDate {
    final lastBackupStr = _settingsBox.get(_lastBackupKey) as String?;
    if (lastBackupStr != null) {
      return DateTime.tryParse(lastBackupStr);
    }
    return null;
  }

  /// Get app launch count
  int get appLaunchCount {
    return _settingsBox.get(_appLaunchCountKey, defaultValue: 0) as int;
  }

  /// Navigate to backup screen
  void _navigateToBackupScreen() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Navigate to settings screen
      // This would need to be implemented based on your routing
      Navigator.of(context).pushNamed('/settings');
    }
  }

  /// Show uninstall warning (call this from settings)
  static void showUninstallWarning(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('Before Uninstalling'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IMPORTANT: Uninstalling this app will permanently delete ALL your data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• All expense records'),
            Text('• Custom categories'),
            Text('• Split plans'),
            Text('• App settings'),
            SizedBox(height: 16),
            Text(
              'Create a backup NOW to save your data!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'After creating a backup, you can restore your data when you reinstall the app.',
              style: TextStyle(fontSize: 12),
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
              // Navigate to backup creation
              // This would need to be implemented based on your routing
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Create Backup First'),
          ),
        ],
      ),
    );
  }
}

// Global navigator key (add this to your main.dart)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
