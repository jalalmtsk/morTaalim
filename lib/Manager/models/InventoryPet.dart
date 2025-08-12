import 'package:shared_preferences/shared_preferences.dart';

class Inventory {
  int _food = 50;
  int _water = 50;
  int _energy = 20;

  static const String _keyFood = 'inventory_food';
  static const String _keyWater = 'inventory_water';
  static const String _keyEnergy = 'inventory_energy';

  // Constructor with optional named parameters
  Inventory({
    int food = 50,
    int water = 50,
    int energy = 20,
  }) {
    _food = food;
    _water = water;
    _energy = energy;
  }

  // Getters
  int get food => _food;
  int get water => _water;
  int get energy => _energy;

  // Setters
  set food(int value) => _food = value;
  set water(int value) => _water = value;
  set energy(int value) => _energy = value;

  // Load from SharedPreferences factory
  factory Inventory.fromPrefs(SharedPreferences prefs) {
    return Inventory(
      food: prefs.getInt(_keyFood) ?? 50,
      water: prefs.getInt(_keyWater) ?? 50,
      energy: prefs.getInt(_keyEnergy) ?? 20,
    );
  }

  // Save to SharedPreferences
  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setInt(_keyFood, _food);
    await prefs.setInt(_keyWater, _water);
    await prefs.setInt(_keyEnergy, _energy);
  }

  // Load from Map
  void loadFromMap(Map<String, dynamic> data) {
    _food = data['food'] ?? _food;
    _water = data['water'] ?? _water;
    _energy = data['energy'] ?? _energy;
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'food': _food,
      'water': _water,
      'energy': _energy,
    };
  }

  // Clear preferences
  Future<void> clearPrefs(SharedPreferences prefs) async {
    await prefs.remove(_keyFood);
    await prefs.remove(_keyWater);
    await prefs.remove(_keyEnergy);
  }
}
