import 'package:flutter/material.dart';
import '../games/WordExplorer/WordExplorerPage.dart';
import 'Page1_Welcome.dart';
import 'Page3_NameAge.dart';
import 'Page4_CityCountry.dart';

// import other pages...

class UserInfoFormFlow extends StatefulWidget {
  const UserInfoFormFlow({Key? key}) : super(key: key);

  @override
  State<UserInfoFormFlow> createState() => _UserInfoFormFlowState();
}

class _UserInfoFormFlowState extends State<UserInfoFormFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 7) { // 8 pages: 0 to 7
      _pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Info Flow'),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        physics: NeverScrollableScrollPhysics(), // control nav only by buttons
        children: const [
          WelcomePage(),
          LanguageSelectionPage(),
          NameAgePage(),
          CityCountryPage(),
          // add more pages here
          // Page5(),
          // Page6(),
          // Page7(),
          // Page8(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              ElevatedButton(
                onPressed: _prevPage,
                child: Text('Back'),
              )
            else
              SizedBox(width: 75), // space placeholder
            Text('Page ${_currentPage + 1} / 8'),
            ElevatedButton(
              onPressed: _nextPage,
              child: Text(_currentPage == 7 ? 'Finish' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }
}
