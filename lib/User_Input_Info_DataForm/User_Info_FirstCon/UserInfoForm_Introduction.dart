import 'package:flutter/material.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/Page5_SchoolInfo.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/page2_age.dart';
import 'package:provider/provider.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import 'Page1_Welcome.dart';
import 'Page2_LanguageSelector.dart';
import 'Page3_NameAge.dart';
import 'Page4_CityCountry.dart';
import 'Page6_Banner.dart';
import 'Page7_AvatarAndGender.dart';



class UserInfoForm extends StatefulWidget {
  const UserInfoForm({Key? key}) : super(key: key);

  @override
  State<UserInfoForm> createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int totalPages = 8;


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

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onLanguageSelected() {
    setState(() {
      canGoNextFromLanguage = true;
    });
    _nextPage();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / totalPages;
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade600, Colors.orange.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                physics: NeverScrollableScrollPhysics(),
                children: [
                  WelcomePage(onGetStarted: _nextPage),
                  LanguageTouch(
                    onLanguageSelected: _onLanguageSelected,),
                  AgeCheckPage(onNext: _nextPage,),
                  NameAgePage(onNext: _nextPage),
                  CityCountryPage(onNext: _nextPage),
                  SchoolInfoPage(onNext: _nextPage),
                  UserInfoBannerPage(onNext: _nextPage),
                  UserInfoAvatarAndGender(),

                ],
              ),

              if (_currentPage > 0) ...[
                // Progress bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),

                // Page indicators
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalPages - 1, (index) {
                      final isActive = index + 1 == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: isActive ? 16 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),

                // Back button
                if (_currentPage > 1)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: FloatingActionButton(
                      heroTag: "backButton",
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: Colors.deepOrange,
                      elevation: 4,
                      onPressed: ()
                      {
                        audioManager.playEventSound('cancelButton');
                        _prevPage();
                      },
                      child: const Icon(Icons.arrow_back, size: 24),
                    ),
                  ),

              ],
            ],
          ),
        ),
      ),
    );
  }
}
