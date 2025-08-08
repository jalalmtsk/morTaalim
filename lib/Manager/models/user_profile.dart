import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String _fullName = '';
  String _lastName = '';
  int _age = 0;
  String _country = '';
  String _city = '';
  String _gender = '';
  String _email = '';
  String _preferredLanguage = 'fr';

  // Constructor
  UserProfile({
    String fullName = '',
    String lastName = '',
    int age = 0,
    String country = '',
    String city = '',
    String gender = '',
    String email = '',
    String preferredLanguage = 'fr',
  }) {
    _fullName = fullName;
    _lastName = lastName;
    _age = age;
    _country = country;
    _city = city;
    _gender = gender;
    _email = email;
    _preferredLanguage = preferredLanguage;
  }

  // Getters
  String get fullName => _fullName;
  String get lastName => _lastName;
  int get age => _age;
  String get country => _country;
  String get city => _city;
  String get gender => _gender;
  String get email => _email;
  String get preferredLanguage => _preferredLanguage;

  // Setters
  set fullName(String value) => _fullName = value;
  set lastName(String value) => _lastName = value;
  set age(int value) => _age = value;
  set country(String value) => _country = value;
  set city(String value) => _city = value;
  set gender(String value) => _gender = value;
  set email(String value) => _email = value;
  set preferredLanguage(String value) => _preferredLanguage = value;

  // Load from SharedPreferences
  factory UserProfile.fromPrefs(SharedPreferences prefs) {
    return UserProfile(
      fullName: prefs.getString('name') ?? '',
      lastName: prefs.getString('lastName') ?? '',
      age: prefs.getInt('age') ?? 0,
      country: prefs.getString('country') ?? '',
      city: prefs.getString('city') ?? '',
      gender: prefs.getString('gender') ?? '',
      email: prefs.getString('email') ?? '',
      preferredLanguage: prefs.getString('preferredLanguage') ?? 'fr',
    );
  }

  // Save to SharedPreferences
  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setString('name', _fullName);
    await prefs.setString('lastName', _lastName);
    await prefs.setInt('age', _age);
    await prefs.setString('country', _country);
    await prefs.setString('city', _city);
    await prefs.setString('gender', _gender);
    await prefs.setString('email', _email);
    await prefs.setString('preferredLanguage', _preferredLanguage);
  }

  // Load from Map
  void loadFromMap(Map<String, dynamic> data) {
    _fullName = data['name'] ?? _fullName;
    _lastName = data['lastName'] ?? _lastName;
    _age = data['age'] ?? _age;
    _country = data['country'] ?? _country;
    _city = data['city'] ?? _city;
    _gender = data['gender'] ?? _gender;
    _email = data['email'] ?? _email;
    _preferredLanguage = data['preferredLanguage'] ?? _preferredLanguage;
  }

  // Convert to Map
  Map<String, dynamic> toMap() => {
    'name': _fullName,
    'lastName': _lastName,
    'age': _age,
    'country': _country,
    'city': _city,
    'gender': _gender,
    'email': _email,
    'preferredLanguage': _preferredLanguage,
  };

  // Clear preferences
  Future<void> clearPrefs(SharedPreferences prefs) async {
    await prefs.remove('name');
    await prefs.remove('lastName');
    await prefs.remove('age');
    await prefs.remove('country');
    await prefs.remove('city');
    await prefs.remove('gender');
    await prefs.remove('email');
    await prefs.remove('preferredLanguage');
  }
}
