import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardVisibilityManager extends ChangeNotifier {
  bool _showAyatCard = true;
  bool _showDuaaDialog = true;

  bool get showAyatCard => _showAyatCard;
  bool get showDuaaDialog => _showDuaaDialog;

  CardVisibilityManager() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showAyatCard = prefs.getBool('showAyatCard') ?? true;
    _showDuaaDialog = prefs.getBool('showDuaaDialog') ?? true;
    notifyListeners();
  }

  Future<void> toggleAyatCard(bool value) async {
    _showAyatCard = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAyatCard', value);
  }

  Future<void> toggleDuaaDialog(bool value) async {
    _showDuaaDialog = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showDuaaDialog', value);
  }
}
