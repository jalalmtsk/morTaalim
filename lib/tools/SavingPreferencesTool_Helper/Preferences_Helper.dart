import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardVisibilityManager extends ChangeNotifier {
  bool _showCard = true;

  bool get showCard => _showCard;

  CardVisibilityManager() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _showCard = prefs.getBool('showAyatCard') ?? true;
    notifyListeners();
  }

  Future<void> toggleCardVisibility(bool value) async {
    _showCard = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAyatCard', value);
  }
}
