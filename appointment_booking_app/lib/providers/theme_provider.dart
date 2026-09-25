import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }
      } else {
        // Strict requirement: Always start on system theme initially
        _themeMode = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('Theme preference load error: $e');
      _themeMode = ThemeMode.system;
    } finally {
      _isInitialized = true;
      _syncSystemOverlay();
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();
    _syncSystemOverlay();

    try {
      final prefs = await SharedPreferences.getInstance();
      String stringValue;
      switch (mode) {
        case ThemeMode.light:
          stringValue = 'light';
          break;
        case ThemeMode.dark:
          stringValue = 'dark';
          break;
        case ThemeMode.system:
          stringValue = 'system';
          break;
      }
      await prefs.setString(_prefKey, stringValue);
    } catch (e) {
      debugPrint('Theme preference save error: $e');
    }
  }

  void _syncSystemOverlay() {
    final Brightness iconBrightness;
    if (_themeMode == ThemeMode.light) {
      iconBrightness = Brightness.dark;
    } else if (_themeMode == ThemeMode.dark) {
      iconBrightness = Brightness.light;
    } else {
      // System mode: Follow platform
      final platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      iconBrightness = platformBrightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark;
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness:
            iconBrightness == Brightness.light ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }
}
