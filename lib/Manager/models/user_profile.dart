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
  String _schoolName = '';

  // New fields
  String _specialNeeds = '';
  String _parentGuardianName = '';
  String _birthday = ''; // ISO string (e.g. "2000-01-01")
  String _schoolType = ''; // e.g. "Public", "Private"
  String _schoolGrade = ''; // e.g. "Grade 3"
  String _schoolLevel = ''; // Primaire, Collège, Lycée
  String _lyceeTrack = '';  // Only relevant if Lycée

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
    String schoolName = '',
    String specialNeeds = '',
    String parentGuardianName = '',
    String birthday = '',
    String schoolType = '',
    String schoolGrade = '',
    String schoolLevel = '',
    String lyceeTrack = '',
  }) {
    _fullName = fullName;
    _lastName = lastName;
    _age = age;
    _country = country;
    _city = city;
    _gender = gender;
    _email = email;
    _preferredLanguage = preferredLanguage;
    _schoolName = schoolName;
    _specialNeeds = specialNeeds;
    _parentGuardianName = parentGuardianName;
    _birthday = birthday;
    _schoolType = schoolType;
    _schoolGrade = schoolGrade;
    _schoolLevel = schoolLevel;
    _lyceeTrack = lyceeTrack;
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
  String get schoolName => _schoolName;
  String get specialNeeds => _specialNeeds;
  String get parentGuardianName => _parentGuardianName;
  String get birthday => _birthday;
  String get schoolType => _schoolType;
  String get schoolGrade => _schoolGrade;
  String get schoolLevel => _schoolLevel;
  String get lyceeTrack => _lyceeTrack;

  // Setters
  set fullName(String value) => _fullName = value;
  set lastName(String value) => _lastName = value;
  set age(int value) => _age = value;
  set country(String value) => _country = value;
  set city(String value) => _city = value;
  set gender(String value) => _gender = value;
  set email(String value) => _email = value;
  set preferredLanguage(String value) => _preferredLanguage = value;
  set schoolName(String value) => _schoolName = value;
  set specialNeeds(String value) => _specialNeeds = value;
  set parentGuardianName(String value) => _parentGuardianName = value;
  set birthday(String value) => _birthday = value;
  set schoolType(String value) => _schoolType = value;
  set schoolGrade(String value) => _schoolGrade = value;
  set schoolLevel(String value) => _schoolLevel = value;
  set lyceeTrack(String value) => _lyceeTrack = value;

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
      schoolName: prefs.getString('schoolName') ?? '',
      specialNeeds: prefs.getString('specialNeeds') ?? '',
      parentGuardianName: prefs.getString('parentGuardianName') ?? '',
      birthday: prefs.getString('birthday') ?? '',
      schoolType: prefs.getString('schoolType') ?? '',
      schoolGrade: prefs.getString('schoolGrade') ?? '',
      schoolLevel: prefs.getString('schoolLevel') ?? '',
      lyceeTrack: prefs.getString('lyceeTrack') ?? '',
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
    await prefs.setString('schoolName', _schoolName);
    await prefs.setString('specialNeeds', _specialNeeds);
    await prefs.setString('parentGuardianName', _parentGuardianName);
    await prefs.setString('birthday', _birthday);
    await prefs.setString('schoolType', _schoolType);
    await prefs.setString('schoolGrade', _schoolGrade);
    await prefs.setString('schoolLevel', _schoolLevel);
    await prefs.setString('lyceeTrack', _lyceeTrack);
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
    _schoolName = data['schoolName'] ?? _schoolName;
    _specialNeeds = data['specialNeeds'] ?? _specialNeeds;
    _parentGuardianName = data['parentGuardianName'] ?? _parentGuardianName;
    _birthday = data['birthday'] ?? _birthday;
    _schoolType = data['schoolType'] ?? _schoolType;
    _schoolGrade = data['schoolGrade'] ?? _schoolGrade;
    _schoolLevel = data['schoolLevel'] ?? _schoolLevel;
    _lyceeTrack = data['lyceeTrack'] ?? _lyceeTrack;
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
    'schoolName': _schoolName,
    'specialNeeds': _specialNeeds,
    'parentGuardianName': _parentGuardianName,
    'birthday': _birthday,
    'schoolType': _schoolType,
    'schoolGrade': _schoolGrade,
    'schoolLevel': _schoolLevel,
    'lyceeTrack': _lyceeTrack,
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
    await prefs.remove('schoolName');
    await prefs.remove('specialNeeds');
    await prefs.remove('parentGuardianName');
    await prefs.remove('birthday');
    await prefs.remove('schoolType');
    await prefs.remove('schoolGrade');
    await prefs.remove('schoolLevel');
    await prefs.remove('lyceeTrack');
  }
}
