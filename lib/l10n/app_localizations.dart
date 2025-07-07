import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @chooseLevel.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Level'**
  String get chooseLevel;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading ...'**
  String get loading;

  /// No description provided for @examTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam Title'**
  String get examTitle;

  /// No description provided for @class1.
  ///
  /// In en, this message translates to:
  /// **'1st Grade'**
  String get class1;

  /// No description provided for @class2.
  ///
  /// In en, this message translates to:
  /// **'2nd Grade'**
  String get class2;

  /// No description provided for @class3.
  ///
  /// In en, this message translates to:
  /// **'3rd Grade'**
  String get class3;

  /// No description provided for @class4.
  ///
  /// In en, this message translates to:
  /// **'4th Grade'**
  String get class4;

  /// No description provided for @class5.
  ///
  /// In en, this message translates to:
  /// **'5th Grade'**
  String get class5;

  /// No description provided for @class6.
  ///
  /// In en, this message translates to:
  /// **'6th Grade'**
  String get class6;

  /// No description provided for @math.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get math;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @islamicEducation.
  ///
  /// In en, this message translates to:
  /// **'Islamic Education'**
  String get islamicEducation;

  /// No description provided for @artEducation.
  ///
  /// In en, this message translates to:
  /// **'Artistic Education'**
  String get artEducation;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job! You have completed all sections'**
  String get greatJob;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @selectGameMode.
  ///
  /// In en, this message translates to:
  /// **'Select Game Mode'**
  String get selectGameMode;

  /// No description provided for @singlePlayer.
  ///
  /// In en, this message translates to:
  /// **'Single Player'**
  String get singlePlayer;

  /// No description provided for @multiplayer.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get multiplayer;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @drawingAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Drawing Alphabet'**
  String get drawingAlphabet;

  /// No description provided for @quizGame.
  ///
  /// In en, this message translates to:
  /// **'Quiz Game'**
  String get quizGame;

  /// No description provided for @appStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get appStories;

  /// No description provided for @shapeSorter.
  ///
  /// In en, this message translates to:
  /// **'Shape Sorter'**
  String get shapeSorter;

  /// No description provided for @boardGame.
  ///
  /// In en, this message translates to:
  /// **'Board Game'**
  String get boardGame;

  /// No description provided for @linkWordgame.
  ///
  /// In en, this message translates to:
  /// **'Link the Words'**
  String get linkWordgame;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stars;

  /// No description provided for @lives.
  ///
  /// In en, this message translates to:
  /// **'Lives'**
  String get lives;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @storiesLibrary.
  ///
  /// In en, this message translates to:
  /// **'Stories library'**
  String get storiesLibrary;

  /// No description provided for @selectDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Select Difficulty'**
  String get selectDifficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @funBoardGame.
  ///
  /// In en, this message translates to:
  /// **'Fun Board Game'**
  String get funBoardGame;

  /// No description provided for @tapStepOrJumpToMoveForward.
  ///
  /// In en, this message translates to:
  /// **'Tap, Step or Jump to move forward'**
  String get tapStepOrJumpToMoveForward;

  /// No description provided for @avoidTheHolesBoardScrollsOnlyWhenYouStart.
  ///
  /// In en, this message translates to:
  /// **'Avoid the holes! The board scrolls only when you start'**
  String get avoidTheHolesBoardScrollsOnlyWhenYouStart;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @jump.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get jump;

  /// No description provided for @chooseGame.
  ///
  /// In en, this message translates to:
  /// **'Choose a Game'**
  String get chooseGame;

  /// No description provided for @alphabetTracing.
  ///
  /// In en, this message translates to:
  /// **'Alphabet Tracing'**
  String get alphabetTracing;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @nextLetter.
  ///
  /// In en, this message translates to:
  /// **'Next letter'**
  String get nextLetter;

  /// No description provided for @piano.
  ///
  /// In en, this message translates to:
  /// **'Piano'**
  String get piano;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @musicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music Volume'**
  String get musicVolume;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @changeName.
  ///
  /// In en, this message translates to:
  /// **'Change Username'**
  String get changeName;

  /// No description provided for @enterNewName.
  ///
  /// In en, this message translates to:
  /// **'Enter a new name'**
  String get enterNewName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About the App'**
  String get aboutApp;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get rateApp;

  /// No description provided for @parentalLock.
  ///
  /// In en, this message translates to:
  /// **'Parental Lock'**
  String get parentalLock;

  /// No description provided for @parentalLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'Parental Lock is enabled'**
  String get parentalLockEnabled;

  /// No description provided for @parentalLockDisabled.
  ///
  /// In en, this message translates to:
  /// **'Parental Lock is disabled'**
  String get parentalLockDisabled;

  /// No description provided for @setParentalPin.
  ///
  /// In en, this message translates to:
  /// **'Set Parental PIN'**
  String get setParentalPin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @enterPinToDisable.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to disable parental lock'**
  String get enterPinToDisable;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Try again.'**
  String get incorrectPin;

  /// No description provided for @screenTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Screen Time Limit'**
  String get screenTimeLimit;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @progressReports.
  ///
  /// In en, this message translates to:
  /// **'Progress Reports'**
  String get progressReports;

  /// No description provided for @progressReportsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Progress Reports feature coming soon!'**
  String get progressReportsComingSoon;

  /// No description provided for @loadingPhrase1.
  ///
  /// In en, this message translates to:
  /// **'Keep calm and wait a bit!'**
  String get loadingPhrase1;

  /// No description provided for @loadingPhrase2.
  ///
  /// In en, this message translates to:
  /// **'Good things take time...'**
  String get loadingPhrase2;

  /// No description provided for @loadingPhrase3.
  ///
  /// In en, this message translates to:
  /// **'Loading... patience is a virtue!'**
  String get loadingPhrase3;

  /// No description provided for @loadingPhrase4.
  ///
  /// In en, this message translates to:
  /// **'Almost there, hang tight!'**
  String get loadingPhrase4;

  /// No description provided for @loadingPhrase5.
  ///
  /// In en, this message translates to:
  /// **'Making magic happen!'**
  String get loadingPhrase5;

  /// No description provided for @loadingPhrase6.
  ///
  /// In en, this message translates to:
  /// **'Miaow! Processing your request...'**
  String get loadingPhrase6;

  /// No description provided for @loadingPhrase7.
  ///
  /// In en, this message translates to:
  /// **'This kitty is working hard!'**
  String get loadingPhrase7;

  /// No description provided for @loadingPhrase8.
  ///
  /// In en, this message translates to:
  /// **'Loading... time for a quick cat stretch!'**
  String get loadingPhrase8;

  /// No description provided for @loadingPhrase9.
  ///
  /// In en, this message translates to:
  /// **'Hang on, kitty’s debugging the code!'**
  String get loadingPhrase9;

  /// No description provided for @loadingPhrase10.
  ///
  /// In en, this message translates to:
  /// **'Mrrrow! Almost done!'**
  String get loadingPhrase10;

  /// No description provided for @this_avatar_is_locked_unlock_it_in_the.
  ///
  /// In en, this message translates to:
  /// **'This avatar is locked. Unlock it in the'**
  String get this_avatar_is_locked_unlock_it_in_the;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @player1Wins.
  ///
  /// In en, this message translates to:
  /// **'Player 1 wins!'**
  String get player1Wins;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @player2Wins.
  ///
  /// In en, this message translates to:
  /// **'Player 2 wins!'**
  String get player2Wins;

  /// No description provided for @itsATie.
  ///
  /// In en, this message translates to:
  /// **'It\'s a tie!'**
  String get itsATie;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @player1.
  ///
  /// In en, this message translates to:
  /// **'Player 1'**
  String get player1;

  /// No description provided for @player2.
  ///
  /// In en, this message translates to:
  /// **'Player 2'**
  String get player2;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @chooseYourLanguageToStartTracing.
  ///
  /// In en, this message translates to:
  /// **'Choose your language to start tracing!'**
  String get chooseYourLanguageToStartTracing;

  /// No description provided for @languageLocked.
  ///
  /// In en, this message translates to:
  /// **'Language locked'**
  String get languageLocked;

  /// No description provided for @unlockFor.
  ///
  /// In en, this message translates to:
  /// **'Unlock for'**
  String get unlockFor;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @sunnyTheSquirrel.
  ///
  /// In en, this message translates to:
  /// **'Sunny the squirrel'**
  String get sunnyTheSquirrel;

  /// No description provided for @flickTheDancingFox.
  ///
  /// In en, this message translates to:
  /// **'Flick the dancing fox'**
  String get flickTheDancingFox;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page of'**
  String get pageOf;

  /// No description provided for @forb.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get forb;

  /// No description provided for @notEnoughStars.
  ///
  /// In en, this message translates to:
  /// **'Not enough stars'**
  String get notEnoughStars;

  /// No description provided for @iQTest.
  ///
  /// In en, this message translates to:
  /// **'IQ Test'**
  String get iQTest;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
