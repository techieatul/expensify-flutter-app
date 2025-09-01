import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

/// Theme mode provider for managing light/dark theme
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Notifier for managing theme mode state
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';
  late Box _settingsBox;

  ThemeModeNotifier() : super(ThemeMode.system) {
    _initializeTheme();
  }

  void _initializeTheme() {
    _settingsBox = Hive.box(AppConstants.settingsBox);
    final savedTheme = _settingsBox.get(_themeKey, defaultValue: 'system');
    
    switch (savedTheme) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  /// Toggle between light and dark themes
  void toggleTheme() {
    switch (state) {
      case ThemeMode.light:
        setTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setTheme(ThemeMode.system);
        break;
      case ThemeMode.system:
        setTheme(ThemeMode.light);
        break;
    }
  }

  /// Set specific theme mode
  void setTheme(ThemeMode themeMode) {
    state = themeMode;
    
    String themeString;
    switch (themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    
    _settingsBox.put(_themeKey, themeString);
  }

  /// Alias for setTheme for consistency with UI
  void setThemeMode(ThemeMode themeMode) => setTheme(themeMode);

  /// Get current theme name for display
  String get currentThemeName {
    switch (state) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get theme icon
  IconData get themeIcon {
    switch (state) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
