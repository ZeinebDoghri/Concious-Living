import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app theme (light/dark mode)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  /// Load saved theme preference
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }
  
  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
    
    notifyListeners();
  }
  
  /// Set theme to light mode
  Future<void> setLightMode() async {
    if (_isDarkMode) {
      _isDarkMode = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_themeKey, false);
      } catch (e) {
        debugPrint('Error saving theme: $e');
      }
      notifyListeners();
    }
  }
  
  /// Set theme to dark mode
  Future<void> setDarkMode() async {
    if (!_isDarkMode) {
      _isDarkMode = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_themeKey, true);
      } catch (e) {
        debugPrint('Error saving theme: $e');
      }
      notifyListeners();
    }
  }
}
