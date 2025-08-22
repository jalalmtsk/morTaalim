import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AppTheme.dart';

class ThemeManager with ChangeNotifier {
  static const String _themeKey = "selected_theme_index";

  final List<AppTheme> themes;
  int _selectedIndex = 0;

  ThemeManager({required this.themes}) {
    _loadTheme();
  }

  int get selectedIndex => _selectedIndex;
  AppTheme get currentTheme => themes[_selectedIndex];

  // Change theme
  void setTheme(int index) async {
    _selectedIndex = index;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themeKey, index);
  }

  // Load saved theme
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(_themeKey) ?? 4;
    _selectedIndex = index;
    notifyListeners();
  }
}
