import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AmazighMaterialLocalizations extends DefaultMaterialLocalizations {
  AmazighMaterialLocalizations() : super();

  // --- Basic Buttons ---
  @override
  String get backButtonTooltip => "ⴰⵖⴰⵍⵉⴷ"; // Back
  @override
  String get closeButtonTooltip => "ⵎⴹⵍ"; // Close
  @override
  String get searchFieldLabel => "ⴰⵏⴰⵣⵓⵔ"; // Search
  @override
  String get cancelButtonLabel => "ⵙⵖⵙ"; // Cancel
  @override
  String get continueButtonLabel => "ⴽⵎⵎⵍ"; // Continue
  @override
  String get okButtonLabel => "ⵡⴰⵅⵅⴰ"; // OK
  @override
  String get dialogLabel => "ⵜⵉⵙⵎⵉⵜ"; // Dialog
  @override
  String get licensesPageTitle => 'ⵜⵉⵙⵔⴰⴳⵍⵉⵏ'; // Licenses
  @override
  String get modalBarrierDismissLabel => 'ⵙⵖⵙ'; // Dismiss

  // --- Date Picker ---
  static const List<String> _months = [
    'ⵉⵏⵏⴰⵢⵔ', 'ⴱⵕⴰⴱⵔⴰⵢⵔ', 'ⵎⴰⵔⵚ', 'ⵉⴱⵔⵉⵍ',
    'ⵎⴰⵢⵢⵓ', 'ⵢⵓⵏⵢⵓ', 'ⵢⵓⵍⵢⵓⵣ', 'ⵖⵓⵛⵜ',
    'ⵛⴰⵜⴰⵏⴱⵕ', 'ⴽⵜⵓⴱⵔ', 'ⵏⵓⵡⴰⵏⴱⵕ', 'ⴷⵓⵊⴰⵏⴱⵕ'
  ];

  static const List<String> _weekdays = [
    '', // DateTime.weekday is 1-7, index 0 unused
    'ⴰⵙⵎⵉⵏ', 'ⴰⵙⵏⵉⵏ', 'ⴰⵙⵛⴰⵏⵙ',
    'ⴰⴽⵕⴰⵙ', 'ⴰⵙⵉⵎⵙ', 'ⴰⵙⵉⵙ', 'ⴰⵙⵕⵉⴷ'
  ];

  @override
  String formatMediumDate(DateTime date) {
    return "${date.day} ${_months[date.month - 1]} ${date.year}";
  }

  @override
  String formatFullDate(DateTime date) {
    final weekday = _weekdays[date.weekday];
    return "$weekday, ${date.day} ${_months[date.month - 1]} ${date.year}";
  }

  @override
  String formatMonthYear(DateTime date) {
    return "${_months[date.month - 1]} ${date.year}";
  }

  @override
  String get datePickerHelpText => "ⵙⵉⴳⵎ ⴰⵙⵏⵙ"; // Select date
  @override
  String get dateInputLabel => "ⴰⵙⵏⵙ ⵏ ⵓⵙⵉⴳⵎ"; // Date input
  @override
  String get invalidDateFormatLabel => "ⴰⵙⵏⵙ ⵓⵔ ⵉⵍⵍⵉ ⵎⴰⵙⵔⵓⵜ"; // Invalid format

  // --- Number formatting ---
  @override
  String formatDecimal(int number) {
    final df = NumberFormat.decimalPattern('zgh');
    return df.format(number);
  }


  @override
  String formatCompactDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // --- Delegate ---
  static const LocalizationsDelegate<MaterialLocalizations> delegate =
  _AmazighMaterialLocalizationsDelegate();
}

class _AmazighMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _AmazighMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ber', 'zgh'].contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return SynchronousFuture<MaterialLocalizations>(AmazighMaterialLocalizations());
  }

  @override
  bool shouldReload(_AmazighMaterialLocalizationsDelegate old) => false;
}
