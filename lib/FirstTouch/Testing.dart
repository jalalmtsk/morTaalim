import 'dart:ui'; // For FontFeature
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../XpSystem.dart'; // Adjust import to your project

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  late AnimationController _textAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _nameError;
  String? _ageError;

  final Color _primaryColor = Colors.deepOrange.shade700;
  final Color _backgroundColor = Colors.white;

  // Language options example
  final List<String> _languages = ['English', 'Français', 'العربية', 'Español'];
  int? _selectedLanguageIndex;

  @override
  void initState() {
    super.initState();

    _textAnimController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textAnimController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _textAnimController, curve: Curves.easeOutBack),
    );

    _textAnimController.forward();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _textAnimController.reset();
    _textAnimController.forward();
  }

  void _nextPage() {
    if (_currentPage == 1 && _selectedLanguageIndex == null) {
      // Require language selection before continuing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a language to continue'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_currentPage < 5) {
      _pageController.nextPage(
          duration: Duration(milliseconds: 600), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: Duration(milliseconds: 600), curve: Curves.easeInOut);
    }
  }

  void _finishOnboarding() {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    int? age = int.tryParse(ageText);

    setState(() {
      _nameError = name.isEmpty ? 'Please enter your name' : null;
      _ageError = (age == null || age <= 0) ? 'Please enter a valid age' : null;
    });

    if (_nameError == null && _ageError == null) {
      final experience = Provider.of<ExperienceManager>(context, listen: false);
      // Save name, age, and language

      print('User name: $name, age: $age, language: ${_languages[_selectedLanguageIndex!]}');

      // Navigate to main app screen
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textAnimController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Widget _animatedPageTransition({required Widget child}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(scale: _scaleAnimation, child: child),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 26 : 14,
          height: 14,
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : _primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(7),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: _primaryColor.withOpacity(0.5),
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ]
                : [],
          ),
          child: Center(
            child: isActive
                ? Text(
              '${i + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            )
                : null,
          ),
        );
      }),
    );
  }

  Widget _pageWrapper({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Welcome',
          style: TextStyle(
              color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          _animatedPageTransition(child: _pageWelcome()),
          _animatedPageTransition(child: _pageLanguageSelection()),
          _animatedPageTransition(child: _pageEducation()),
          _animatedPageTransition(child: _pageCourses()),
          _animatedPageTransition(child: _pageGames()),
          _animatedPageTransition(child: _pageProfileSetup()),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        color: _backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              ElevatedButton(
                onPressed: _prevPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: _primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new, size: 18),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
            else
              SizedBox(width: 90),
            _buildPageIndicator(),
            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 6,
                shadowColor: _primaryColor.withOpacity(0.5),
              ),
              child: Text(
                _currentPage == 5 ? 'Finish' : 'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PAGES ---

  Widget _pageWelcome() {
    return _pageWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Lottie.asset(
              'assets/animations/girl_studying.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Welcome to Our App',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Your journey towards knowledge starts here!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _pageLanguageSelection() {
    return _pageWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Choose Your Language',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 18),
          Text(
            'Select the language you want to use in the app.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28),

          // Language buttons
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: List.generate(_languages.length, (index) {
              final selected = _selectedLanguageIndex == index;
              return ChoiceChip(
                label: Text(
                  _languages[index],
                  style: TextStyle(
                    color: selected ? Colors.white : _primaryColor,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                selected: selected,
                selectedColor: _primaryColor,
                backgroundColor: _primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (_) {
                  setState(() {
                    _selectedLanguageIndex = index;
                  });
                },
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _pageEducation() {
    return _pageWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Lottie.asset(
              'assets/animations/menWining.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Learn Math, Science & Islamic Education',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Comprehensive lessons blending modern science and traditional teachings for holistic growth.',
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _pageCourses() {
    return _pageWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Lottie.asset(
              'assets/animations/courses.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Exams, Courses & Exercises',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Practice through quizzes, track your progress, and improve interactively.',
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _pageGames() {
    return _pageWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Lottie.asset(
              'assets/animations/superhero.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Engaging Games',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Enjoy fun educational games and stay tuned for exciting content coming soon!',
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _pageProfileSetup() {
    final experience = Provider.of<ExperienceManager>(context);
    final selectedBanner = experience.selectedBannerImage;
    final unlockedBanners = experience.unlockedBanners;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Let\'s set up your profile',
              style: TextStyle(
                  color: _primaryColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 18),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Enter your name',
                errorText: _nameError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              cursorColor: _primaryColor,
            ),
            SizedBox(height: 18),

            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter your age',
                errorText: _ageError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              cursorColor: _primaryColor,
            ),
            SizedBox(height: 24),

            Text(
              'Choose your banner',
              style: TextStyle(
                color: _primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),

            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: unlockedBanners.length,
                separatorBuilder: (_, __) => SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final bannerPath = unlockedBanners[index];
                  final isSelected = bannerPath == selectedBanner;

                  return GestureDetector(
                    onTap: () => experience.selectBannerImage(bannerPath),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 350),
                      width: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: _primaryColor, width: 4)
                            : Border.all(color: Colors.transparent),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.45),
                            blurRadius: 14,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          )
                        ]
                            : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          bannerPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[300],
                                child: Center(child: Icon(Icons.broken_image)),
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
