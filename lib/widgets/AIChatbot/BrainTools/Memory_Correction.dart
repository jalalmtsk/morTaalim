import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CorrectionsMemory {
  static final CorrectionsMemory _instance = CorrectionsMemory._internal();

  factory CorrectionsMemory() => _instance;

  CorrectionsMemory._internal();

  Map<String, String> _corrections = {};

  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('waki_corrections');
    if (jsonStr != null) {
      _corrections = Map<String, String>.from(json.decode(jsonStr));
    }
    _initialized = true;
  }

  Future<void> addCorrection(String question, String answer) async {
    await _init();
    final q = question.toLowerCase().trim();
    _corrections[q] = answer;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('waki_corrections', json.encode(_corrections));
  }

  String? getCorrection(String question) {
    final q = question.toLowerCase().trim();
    return _corrections[q];
  }

  Map<String, String> get allCorrections => _corrections;
}
