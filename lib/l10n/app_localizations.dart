import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_zgh.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('zgh')
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
  /// **'AlphaDraw'**
  String get drawingAlphabet;

  /// No description provided for @quizGame.
  ///
  /// In en, this message translates to:
  /// **'BrainQuest'**
  String get quizGame;

  /// No description provided for @appStories.
  ///
  /// In en, this message translates to:
  /// **'StoryLand'**
  String get appStories;

  /// No description provided for @shapeSorter.
  ///
  /// In en, this message translates to:
  /// **'ShapePop!'**
  String get shapeSorter;

  /// No description provided for @boardGame.
  ///
  /// In en, this message translates to:
  /// **'BrainyBoard'**
  String get boardGame;

  /// No description provided for @wordLink.
  ///
  /// In en, this message translates to:
  /// **'Word Weave'**
  String get wordLink;

  /// No description provided for @sugarSmash.
  ///
  /// In en, this message translates to:
  /// **'Sugar Swirl'**
  String get sugarSmash;

  /// No description provided for @magicPainting.
  ///
  /// In en, this message translates to:
  /// **'Color Whiz'**
  String get magicPainting;

  /// No description provided for @planeDestroyer.
  ///
  /// In en, this message translates to:
  /// **'Sky Blaster'**
  String get planeDestroyer;

  /// No description provided for @iqTest.
  ///
  /// In en, this message translates to:
  /// **'IQ Spark'**
  String get iqTest;

  /// No description provided for @jumpingBoard.
  ///
  /// In en, this message translates to:
  /// **'HopZone'**
  String get jumpingBoard;

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

  /// No description provided for @courseLocked.
  ///
  /// In en, this message translates to:
  /// **'Course Locked'**
  String get courseLocked;

  /// No description provided for @unlockThisCourseFor.
  ///
  /// In en, this message translates to:
  /// **'Unlock this course for'**
  String get unlockThisCourseFor;

  /// No description provided for @gained.
  ///
  /// In en, this message translates to:
  /// **'Gained'**
  String get gained;

  /// No description provided for @wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well Done'**
  String get wellDone;

  /// No description provided for @freeDrawing.
  ///
  /// In en, this message translates to:
  /// **'Free Drawing'**
  String get freeDrawing;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @noDrawingsSavedYet.
  ///
  /// In en, this message translates to:
  /// **'No drawings saved yet'**
  String get noDrawingsSavedYet;

  /// No description provided for @createSomeAwesomeArt.
  ///
  /// In en, this message translates to:
  /// **'Create some awesome art!'**
  String get createSomeAwesomeArt;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickAColor;

  /// No description provided for @selectBrushSize.
  ///
  /// In en, this message translates to:
  /// **'Select brush size'**
  String get selectBrushSize;

  /// No description provided for @drawSomethingBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Draw something before saving'**
  String get drawSomethingBeforeSaving;

  /// No description provided for @drawingSaved.
  ///
  /// In en, this message translates to:
  /// **'Drawing saved'**
  String get drawingSaved;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @chooseYourBanner.
  ///
  /// In en, this message translates to:
  /// **'Choose your banner'**
  String get chooseYourBanner;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @letter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get letter;

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get secondsLeft;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @addtofavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorite'**
  String get addtofavorite;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @favoriteWords.
  ///
  /// In en, this message translates to:
  /// **'Favorite Words'**
  String get favoriteWords;

  /// No description provided for @noFavoriteWordsYetAddNewWordsHere.
  ///
  /// In en, this message translates to:
  /// **'No favorite words yet. Add new words here.'**
  String get noFavoriteWordsYetAddNewWordsHere;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @funMoji.
  ///
  /// In en, this message translates to:
  /// **'FunMoji'**
  String get funMoji;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @beams.
  ///
  /// In en, this message translates to:
  /// **'Beams'**
  String get beams;

  /// No description provided for @moji.
  ///
  /// In en, this message translates to:
  /// **'Moji'**
  String get moji;

  /// No description provided for @aliens.
  ///
  /// In en, this message translates to:
  /// **'Aliens'**
  String get aliens;

  /// No description provided for @animated.
  ///
  /// In en, this message translates to:
  /// **'Animated'**
  String get animated;

  /// No description provided for @banners.
  ///
  /// In en, this message translates to:
  /// **'Banners'**
  String get banners;

  /// No description provided for @cute.
  ///
  /// In en, this message translates to:
  /// **'Cute'**
  String get cute;

  /// No description provided for @joyful.
  ///
  /// In en, this message translates to:
  /// **'Joyful'**
  String get joyful;

  /// No description provided for @sciFi.
  ///
  /// In en, this message translates to:
  /// **'Sci-Fi'**
  String get sciFi;

  /// No description provided for @fantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get fantasy;

  /// No description provided for @islamic.
  ///
  /// In en, this message translates to:
  /// **'Islamic'**
  String get islamic;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @tolims.
  ///
  /// In en, this message translates to:
  /// **'Tolims'**
  String get tolims;

  /// No description provided for @spinningWheel.
  ///
  /// In en, this message translates to:
  /// **'Spinning Wheel'**
  String get spinningWheel;

  /// No description provided for @spin.
  ///
  /// In en, this message translates to:
  /// **'Spin'**
  String get spin;

  /// No description provided for @reroll.
  ///
  /// In en, this message translates to:
  /// **'Reroll'**
  String get reroll;

  /// No description provided for @comeBackin.
  ///
  /// In en, this message translates to:
  /// **'Come back in'**
  String get comeBackin;

  /// No description provided for @dailyReward.
  ///
  /// In en, this message translates to:
  /// **'Daily Reward'**
  String get dailyReward;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd;

  /// No description provided for @earn.
  ///
  /// In en, this message translates to:
  /// **'Earn'**
  String get earn;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @youWon.
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get youWon;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @freeSpinUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Free spin unlocked!'**
  String get freeSpinUnlocked;

  /// No description provided for @youEarned.
  ///
  /// In en, this message translates to:
  /// **'You earned'**
  String get youEarned;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again!'**
  String get tryAgain;

  /// No description provided for @noRewardThisTime.
  ///
  /// In en, this message translates to:
  /// **'No reward this time.'**
  String get noRewardThisTime;

  /// No description provided for @dailySpin.
  ///
  /// In en, this message translates to:
  /// **'Daily Spin'**
  String get dailySpin;

  /// No description provided for @comeBackIn.
  ///
  /// In en, this message translates to:
  /// **'Come back in'**
  String get comeBackIn;

  /// No description provided for @youreReadyToSpin.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready to spin!'**
  String get youreReadyToSpin;

  /// No description provided for @pronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get pronunciation;

  /// No description provided for @example.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get example;

  /// No description provided for @drawWhateverYouLike.
  ///
  /// In en, this message translates to:
  /// **'Draw whatever you like'**
  String get drawWhateverYouLike;

  /// No description provided for @paintOnSketches.
  ///
  /// In en, this message translates to:
  /// **'Paint on sketches'**
  String get paintOnSketches;

  /// No description provided for @colorBeautifulTemplates.
  ///
  /// In en, this message translates to:
  /// **'Color beautiful templates'**
  String get colorBeautifulTemplates;

  /// No description provided for @learningProgram.
  ///
  /// In en, this message translates to:
  /// **'Learning Program'**
  String get learningProgram;

  /// No description provided for @stepByStepPaintingLessons.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step painting lessons'**
  String get stepByStepPaintingLessons;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @areYouSureYouWantToDeleteThisDrawing.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this drawing?'**
  String get areYouSureYouWantToDeleteThisDrawing;

  /// No description provided for @deleteDrawing.
  ///
  /// In en, this message translates to:
  /// **'Delete Drawing'**
  String get deleteDrawing;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get howToPlay;

  /// No description provided for @readyToPlay.
  ///
  /// In en, this message translates to:
  /// **'Ready to Play?'**
  String get readyToPlay;

  /// No description provided for @chooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseYourLanguage;

  /// No description provided for @pickSingleOrMultiplayer.
  ///
  /// In en, this message translates to:
  /// **'Pick Single or Multiplayer'**
  String get pickSingleOrMultiplayer;

  /// No description provided for @rules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules;

  /// No description provided for @treeCorrectAnswersEqualOnestar.
  ///
  /// In en, this message translates to:
  /// **'Three Correct Answers Equal One Star'**
  String get treeCorrectAnswersEqualOnestar;

  /// No description provided for @everyCorrectAnswerEqualPlusTwoXP.
  ///
  /// In en, this message translates to:
  /// **'Every Correct Answer Equals Plus Two XP'**
  String get everyCorrectAnswerEqualPlusTwoXP;

  /// No description provided for @competeOrPlaySolo.
  ///
  /// In en, this message translates to:
  /// **'Compete or Play Solo'**
  String get competeOrPlaySolo;

  /// No description provided for @haveFunAndLearnSomethingNew.
  ///
  /// In en, this message translates to:
  /// **'Have Fun and Learn Something New!'**
  String get haveFunAndLearnSomethingNew;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @adFailedToLoadOrWasNotCompletedPleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Ad failed to load or was not completed. Please try again later.'**
  String get adFailedToLoadOrWasNotCompletedPleaseTryAgainLater;

  /// No description provided for @outOfHearts.
  ///
  /// In en, this message translates to:
  /// **'Out of Hearts!'**
  String get outOfHearts;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @chooseALanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose A Language'**
  String get chooseALanguage;

  /// No description provided for @allCorrectAnwsersEqualOneTolim.
  ///
  /// In en, this message translates to:
  /// **'All correct answers equal one Tolim'**
  String get allCorrectAnwsersEqualOneTolim;

  /// No description provided for @youHaveNoHeartsLeftWhatWouldYouLikeToDo.
  ///
  /// In en, this message translates to:
  /// **'You have no hearts left. What would you like to do?'**
  String get youHaveNoHeartsLeftWhatWouldYouLikeToDo;

  /// No description provided for @science.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get science;

  /// No description provided for @badges_beginnerReader.
  ///
  /// In en, this message translates to:
  /// **'beginner reader'**
  String get badges_beginnerReader;

  /// No description provided for @badges_curiousMind.
  ///
  /// In en, this message translates to:
  /// **'curious mind'**
  String get badges_curiousMind;

  /// No description provided for @badges_bookLover.
  ///
  /// In en, this message translates to:
  /// **'book lover'**
  String get badges_bookLover;

  /// No description provided for @badges_knowledgeSeeker.
  ///
  /// In en, this message translates to:
  /// **'knowledge seeker'**
  String get badges_knowledgeSeeker;

  /// No description provided for @badges_quizExpert.
  ///
  /// In en, this message translates to:
  /// **'quiz expert'**
  String get badges_quizExpert;

  /// No description provided for @badges_studyMaster.
  ///
  /// In en, this message translates to:
  /// **'study master'**
  String get badges_studyMaster;

  /// No description provided for @badges_truthDiscoverer.
  ///
  /// In en, this message translates to:
  /// **'truth discoverer'**
  String get badges_truthDiscoverer;

  /// No description provided for @badges_intelligent.
  ///
  /// In en, this message translates to:
  /// **'intelligent'**
  String get badges_intelligent;

  /// No description provided for @badges_theorist.
  ///
  /// In en, this message translates to:
  /// **'theorist'**
  String get badges_theorist;

  /// No description provided for @badges_masterOfLogic.
  ///
  /// In en, this message translates to:
  /// **'master of logic'**
  String get badges_masterOfLogic;

  /// No description provided for @badges_keeperOfWisdom.
  ///
  /// In en, this message translates to:
  /// **'keeper of wisdom'**
  String get badges_keeperOfWisdom;

  /// No description provided for @badges_ideaArchitect.
  ///
  /// In en, this message translates to:
  /// **'idea architect'**
  String get badges_ideaArchitect;

  /// No description provided for @badges_thoughtLeader.
  ///
  /// In en, this message translates to:
  /// **'thought leader'**
  String get badges_thoughtLeader;

  /// No description provided for @badges_mindMentor.
  ///
  /// In en, this message translates to:
  /// **'mind mentor'**
  String get badges_mindMentor;

  /// No description provided for @badges_wizardOfWisdom.
  ///
  /// In en, this message translates to:
  /// **'wizard of wisdom'**
  String get badges_wizardOfWisdom;

  /// No description provided for @badges_learningLegend.
  ///
  /// In en, this message translates to:
  /// **'learning legend'**
  String get badges_learningLegend;

  /// No description provided for @badges_sageOfTruth.
  ///
  /// In en, this message translates to:
  /// **'sage of truth'**
  String get badges_sageOfTruth;

  /// No description provided for @badges_greatScholar.
  ///
  /// In en, this message translates to:
  /// **'great scholar'**
  String get badges_greatScholar;

  /// No description provided for @badges_pinnacleOfKnowledge.
  ///
  /// In en, this message translates to:
  /// **'pinnacle of knowledge'**
  String get badges_pinnacleOfKnowledge;

  /// No description provided for @learningPower.
  ///
  /// In en, this message translates to:
  /// **'Learning Power'**
  String get learningPower;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @global.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get global;

  /// No description provided for @coursesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Courses Completed'**
  String get coursesCompleted;

  /// No description provided for @exercices.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercices;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @practiseCourses.
  ///
  /// In en, this message translates to:
  /// **'Practice Courses'**
  String get practiseCourses;

  /// No description provided for @keepUpTheGoodWork.
  ///
  /// In en, this message translates to:
  /// **'Keep Up The Good Work'**
  String get keepUpTheGoodWork;

  /// No description provided for @classLevel.
  ///
  /// In en, this message translates to:
  /// **'Class Level'**
  String get classLevel;

  /// No description provided for @audioSettings.
  ///
  /// In en, this message translates to:
  /// **'Audio Settings'**
  String get audioSettings;

  /// No description provided for @backgroundMusic.
  ///
  /// In en, this message translates to:
  /// **'Background Music'**
  String get backgroundMusic;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @buttonSounds.
  ///
  /// In en, this message translates to:
  /// **'Button Sounds'**
  String get buttonSounds;

  /// No description provided for @resetAudioSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Audio Settings'**
  String get resetAudioSettings;

  /// No description provided for @duaaAndAyat.
  ///
  /// In en, this message translates to:
  /// **'Duaa and Ayat'**
  String get duaaAndAyat;

  /// No description provided for @showAyat.
  ///
  /// In en, this message translates to:
  /// **'Show Ayat'**
  String get showAyat;

  /// No description provided for @enableordisabletheAyatcardfromappearinginyourapp.
  ///
  /// In en, this message translates to:
  /// **'Enable or Disable the Ayat Card from Appearing in Your App'**
  String get enableordisabletheAyatcardfromappearinginyourapp;

  /// No description provided for @showDuaa.
  ///
  /// In en, this message translates to:
  /// **'Show Duaa'**
  String get showDuaa;

  /// No description provided for @enableorDisableDuaaEveryTimeYouEnter.
  ///
  /// In en, this message translates to:
  /// **'Enable or Disable Duaa Every Time You Enter'**
  String get enableorDisableDuaaEveryTimeYouEnter;

  /// No description provided for @accountAndBackup.
  ///
  /// In en, this message translates to:
  /// **'Account and Backup'**
  String get accountAndBackup;

  /// No description provided for @preferredSubject.
  ///
  /// In en, this message translates to:
  /// **'Preferred Subject'**
  String get preferredSubject;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @followUsOnSocialMedia.
  ///
  /// In en, this message translates to:
  /// **'Follow Us On Social Media'**
  String get followUsOnSocialMedia;

  /// No description provided for @weArePreparingSomethingAwesome.
  ///
  /// In en, this message translates to:
  /// **'We Are Preparing Something Awesome'**
  String get weArePreparingSomethingAwesome;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @unableToOpenTheLink.
  ///
  /// In en, this message translates to:
  /// **'Unable To Open The Link'**
  String get unableToOpenTheLink;

  /// No description provided for @thankYouForYourPatience.
  ///
  /// In en, this message translates to:
  /// **'Thank You For Your Patience'**
  String get thankYouForYourPatience;

  /// No description provided for @manageBackup.
  ///
  /// In en, this message translates to:
  /// **'Manage Backup'**
  String get manageBackup;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup and Restore'**
  String get backupAndRestore;

  /// No description provided for @backupYourProgressOrRestoreItUsingABackupCode.
  ///
  /// In en, this message translates to:
  /// **'Backup your progress or restore it using a backup code'**
  String get backupYourProgressOrRestoreItUsingABackupCode;

  /// No description provided for @saveBackup.
  ///
  /// In en, this message translates to:
  /// **'Save Backup'**
  String get saveBackup;

  /// No description provided for @loadBackup.
  ///
  /// In en, this message translates to:
  /// **'Load Backup'**
  String get loadBackup;

  /// No description provided for @howToBackup.
  ///
  /// In en, this message translates to:
  /// **'How to Backup'**
  String get howToBackup;

  /// No description provided for @makeSureToSaveYourBackupCodeSafelyYouWillNeedItToRestoreYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Make sure to save your backup code safely. You will need it to restore your progress'**
  String get makeSureToSaveYourBackupCodeSafelyYouWillNeedItToRestoreYourProgress;

  /// No description provided for @signedInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get signedInWithGoogle;

  /// No description provided for @disconnectedNowinanonymousmode.
  ///
  /// In en, this message translates to:
  /// **'Disconnected, now in anonymous mode'**
  String get disconnectedNowinanonymousmode;

  /// No description provided for @failedToDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to disconnect'**
  String get failedToDisconnect;

  /// No description provided for @googleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get googleAccount;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @connectGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Account'**
  String get connectGoogleAccount;

  /// No description provided for @notConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'Not connected yet'**
  String get notConnectedYet;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @areYouSureYouWantToDisconnectYourGoogleAccountYouWillBeSwitchedToAnonymousMode.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect your Google account? You will be switched to anonymous mode'**
  String get areYouSureYouWantToDisconnectYourGoogleAccountYouWillBeSwitchedToAnonymousMode;

  /// No description provided for @selectALanguageToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a language to continue'**
  String get selectALanguageToContinue;

  /// No description provided for @languageSetTo.
  ///
  /// In en, this message translates to:
  /// **'Language set to'**
  String get languageSetTo;

  /// No description provided for @letsGetToKnowEachOther.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get to know each other'**
  String get letsGetToKnowEachOther;

  /// No description provided for @fillInYourInformation.
  ///
  /// In en, this message translates to:
  /// **'Fill in your information to personalize your experience'**
  String get fillInYourInformation;

  /// No description provided for @pleaseEnterYourFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your First Name'**
  String get pleaseEnterYourFirstName;

  /// No description provided for @pleaseEnterYourLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Last Name'**
  String get pleaseEnterYourLastName;

  /// No description provided for @pleaseEnterYourAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Age'**
  String get pleaseEnterYourAge;

  /// No description provided for @pleaseEnterAValidAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Age'**
  String get pleaseEnterAValidAge;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @schoolInformation.
  ///
  /// In en, this message translates to:
  /// **'School Information'**
  String get schoolInformation;

  /// No description provided for @pleaseEnterSchoolNameTypeLevelAndClass.
  ///
  /// In en, this message translates to:
  /// **'Please enter the school name, type, level, and class'**
  String get pleaseEnterSchoolNameTypeLevelAndClass;

  /// No description provided for @schoolName.
  ///
  /// In en, this message translates to:
  /// **'School Name'**
  String get schoolName;

  /// No description provided for @pleaseEnterSchoolName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the school name'**
  String get pleaseEnterSchoolName;

  /// No description provided for @schoolType.
  ///
  /// In en, this message translates to:
  /// **'School Type'**
  String get schoolType;

  /// No description provided for @selectSchoolType.
  ///
  /// In en, this message translates to:
  /// **'Select the school type'**
  String get selectSchoolType;

  /// No description provided for @schoolLevel.
  ///
  /// In en, this message translates to:
  /// **'School Level'**
  String get schoolLevel;

  /// No description provided for @selectSchoolLevel.
  ///
  /// In en, this message translates to:
  /// **'Select the school level'**
  String get selectSchoolLevel;

  /// No description provided for @classSchool.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classSchool;

  /// No description provided for @selectClass.
  ///
  /// In en, this message translates to:
  /// **'Select the class'**
  String get selectClass;

  /// No description provided for @highSchoolTrack.
  ///
  /// In en, this message translates to:
  /// **'High School Track'**
  String get highSchoolTrack;

  /// No description provided for @selectHighSchoolTrack.
  ///
  /// In en, this message translates to:
  /// **'Select the high school track'**
  String get selectHighSchoolTrack;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocation;

  /// No description provided for @pleaseEnterYourCityAndCountryToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please enter your city and country to continue'**
  String get pleaseEnterYourCityAndCountryToContinue;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @pleaseEnterYourCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter your city'**
  String get pleaseEnterYourCity;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @pleaseEnterYourCountry.
  ///
  /// In en, this message translates to:
  /// **'Please enter your country'**
  String get pleaseEnterYourCountry;

  /// No description provided for @schoolTypePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get schoolTypePrivate;

  /// No description provided for @schoolTypePublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get schoolTypePublic;

  /// No description provided for @schoolTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get schoolTypeOther;

  /// No description provided for @schoolLevelPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get schoolLevelPrimary;

  /// No description provided for @schoolLevelMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle School'**
  String get schoolLevelMiddle;

  /// No description provided for @schoolLevelHigh.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get schoolLevelHigh;

  /// No description provided for @gradesPrimary1.
  ///
  /// In en, this message translates to:
  /// **'1st Grade (CP)'**
  String get gradesPrimary1;

  /// No description provided for @gradesPrimary2.
  ///
  /// In en, this message translates to:
  /// **'2nd Grade (CE1)'**
  String get gradesPrimary2;

  /// No description provided for @gradesPrimary3.
  ///
  /// In en, this message translates to:
  /// **'3rd Grade (CE2)'**
  String get gradesPrimary3;

  /// No description provided for @gradesPrimary4.
  ///
  /// In en, this message translates to:
  /// **'4th Grade (CM1)'**
  String get gradesPrimary4;

  /// No description provided for @gradesPrimary5.
  ///
  /// In en, this message translates to:
  /// **'5th Grade (CM2)'**
  String get gradesPrimary5;

  /// No description provided for @gradesPrimary6.
  ///
  /// In en, this message translates to:
  /// **'6th Grade (CM3)'**
  String get gradesPrimary6;

  /// No description provided for @gradesMiddle1.
  ///
  /// In en, this message translates to:
  /// **'7th Grade (1st year Middle School)'**
  String get gradesMiddle1;

  /// No description provided for @gradesMiddle2.
  ///
  /// In en, this message translates to:
  /// **'8th Grade (2nd year Middle School)'**
  String get gradesMiddle2;

  /// No description provided for @gradesMiddle3.
  ///
  /// In en, this message translates to:
  /// **'9th Grade (3rd year Middle School)'**
  String get gradesMiddle3;

  /// No description provided for @gradesHigh1.
  ///
  /// In en, this message translates to:
  /// **'Common Core (TC)'**
  String get gradesHigh1;

  /// No description provided for @gradesHigh2.
  ///
  /// In en, this message translates to:
  /// **'1st year Bac (Regional)'**
  String get gradesHigh2;

  /// No description provided for @gradesHigh3.
  ///
  /// In en, this message translates to:
  /// **'Baccalaureate (National)'**
  String get gradesHigh3;

  /// No description provided for @lyceeTrackScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get lyceeTrackScience;

  /// No description provided for @lyceeTrackLiterature.
  ///
  /// In en, this message translates to:
  /// **'Literature'**
  String get lyceeTrackLiterature;

  /// No description provided for @errorFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields correctly'**
  String get errorFillAllFields;

  /// No description provided for @pleaseChooseABanner.
  ///
  /// In en, this message translates to:
  /// **'Please choose a banner'**
  String get pleaseChooseABanner;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// No description provided for @futurePlans.
  ///
  /// In en, this message translates to:
  /// **'Future Plans'**
  String get futurePlans;

  /// No description provided for @chooseYourAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Avatar'**
  String get chooseYourAvatar;

  /// No description provided for @profileInfo.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInfo;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @dontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Do not show again'**
  String get dontShowAgain;

  /// No description provided for @informationTechnology.
  ///
  /// In en, this message translates to:
  /// **'Information Technology'**
  String get informationTechnology;

  /// No description provided for @islam.
  ///
  /// In en, this message translates to:
  /// **'Islam'**
  String get islam;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'An innovative educational platform blending learning, games, and culture to make education fun and engaging for students in Morocco and beyond.'**
  String get info;

  /// No description provided for @aboutMission.
  ///
  /// In en, this message translates to:
  /// **'MoorTaalim aims to empower students by providing interactive educational content that respects Moroccan culture and promotes a love of learning. We believe education should be enjoyable, accessible, and culturally relevant.'**
  String get aboutMission;

  /// No description provided for @aboutFuturePlans.
  ///
  /// In en, this message translates to:
  /// **'We\'re continuously working to add new courses, exciting multiplayer games, and advanced features like personalized learning paths and community forums to connect learners and educators.'**
  String get aboutFuturePlans;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'fr', 'zgh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'zgh': return AppLocalizationsZgh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
