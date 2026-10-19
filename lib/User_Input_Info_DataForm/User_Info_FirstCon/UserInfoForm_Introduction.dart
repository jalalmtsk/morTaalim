import 'package:flutter/material.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/Page5_SchoolInfo.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/page2_age.dart';
import 'package:provider/provider.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import 'Page1_Welcome.dart';
import 'Page2_LanguageSelector.dart';
import 'Page3_NameAge.dart';
import 'Page4_CityCountry.dart';
import 'Page5a_StudentChoice.dart';
import 'Page6_Banner.dart';
import 'Page7_AvatarAndGender.dart';
import 'onboarding_style.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

class UserInfoForm extends StatefulWidget {
  const UserInfoForm({Key? key}) : super(key: key);

  @override
  State<UserInfoForm> createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int totalPages = 9;

  // Index of each page, so the student branch can jump over the school page.
  static const int _studentPage = 5;
  static const int _schoolPage = 6;
  static const int _bannerPage = 7;
  bool _skippedSchool = false;

  bool canGoNextFromLanguage = false;

  @override
  void initState() {
    super.initState();
  }

  void _nextPage() {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    if (_currentPage == _bannerPage && _skippedSchool) {
      _goTo(_studentPage);
      return;
    }
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(Onb.background), context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onLanguageSelected() {
    setState(() => canGoNextFromLanguage = true);
    _nextPage();
  }

  /// Pages redesigned as full-bleed illustrated scenes: they paint their own
  /// background, header and back button, and handle the keyboard themselves.
  static const Set<int> _scenePages = {0, 1, 2, 3, 4, 5, 6, 7, 8};

  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / totalPages;
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final pad = MediaQuery.paddingOf(context);
    final isScene = _scenePages.contains(_currentPage);

    return Scaffold(
      backgroundColor: Onb.bgFallback,
      resizeToAvoidBottomInset: !isScene,
      body: Container(
        decoration: const BoxDecoration(
          color: Onb.bgFallback,
          image: DecorationImage(
            image: AssetImage(Onb.background),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                WelcomePage(onGetStarted: _nextPage),
                LanguageTouch(onLanguageSelected: _onLanguageSelected, onBack: _prevPage),
                // ✅ onUnderAge supprimé — AgeCheckPage n'a plus qu'un seul callback
                AgeCheckPage(onNext: _nextPage, onBack: _prevPage),
                NameAgePage(onNext: _nextPage, onBack: _prevPage),
                CityCountryPage(onNext: _nextPage, onBack: _prevPage),
                StudentChoicePage(
                  onBack: _prevPage,
                  onYes: () {
                    _skippedSchool = false;
                    _goTo(_schoolPage);
                  },
                  onNo: () {
                    _skippedSchool = true;
                    _goTo(_bannerPage);
                  },
                ),
                SchoolInfoPage(onNext: _nextPage, onBack: _prevPage),
                UserInfoBannerPage(onNext: _nextPage, onBack: _prevPage),
                UserInfoAvatarAndGender(onBack: _prevPage),
              ],
            ),

            // Progress bar (classic pages only)
            if (!isScene)
              Positioned(
                top: pad.top + 16,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.7),
                    valueColor: const AlwaysStoppedAnimation<Color>(Onb.accent),
                  ),
                ),
              ),

            // Page dots (all pages)
            Positioned(
              bottom: pad.bottom + 18,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: KidDots(count: totalPages, active: _currentPage, size: 10),
                ),
              ),
            ),

            // Back button (classic pages only — scene pages draw their own)
            if (!isScene && _currentPage > 1)
              Positioned(
                bottom: pad.bottom + 20,
                left: 20,
                child: FloatingActionButton(
                  heroTag: "backButton",
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: Colors.deepOrange,
                  elevation: 4,
                  onPressed: () {
                    audioManager.playEventSound('cancelButton');
                    _prevPage();
                  },
                  child: const Icon(Icons.arrow_back, size: 24),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
