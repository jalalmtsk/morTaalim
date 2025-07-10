import 'package:flutter/material.dart';
import 'dart:async';

import 'package:mortaalim/IndexPage.dart';


class TestApp extends StatelessWidget {
  const TestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Onboarding Chat',
      home: const GenderSelectionPage(),
      routes: {
        '/onboarding': (_) => const OnboardingChatPage(selectedGender: '',),
        '/Index': (_) => Index(onChangeLocale: (local){ Locale('en');}),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// 1. Gender Selection Page (Choose boy or girl avatar)
class GenderSelectionPage extends StatelessWidget {
  const GenderSelectionPage({super.key});

  void _selectGender(BuildContext context, String gender) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingChatPage(selectedGender: gender),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = 140;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Character'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/Untitled design-2.png', // replace with your image path
              fit: BoxFit.cover,
            ),
          ),

          // Content on top of the background
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Who are you?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White for better contrast
                      shadows: [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black45,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => _selectGender(context, 'boy'),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: avatarSize / 2,
                              backgroundImage: const AssetImage('assets/images/red.jpg'),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Boy',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _selectGender(context, 'girl'),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: avatarSize / 2,
                              backgroundImage: const AssetImage('assets/images/18.jpg'),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Girl',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  }
}

// 2. Onboarding chat with selected avatar
class OnboardingChatPage extends StatefulWidget {
  final String selectedGender;
  const OnboardingChatPage({super.key, required this.selectedGender});

  @override
  State<OnboardingChatPage> createState() => _OnboardingChatPageState();
}

class _OnboardingChatPageState extends State<OnboardingChatPage> {
  final PageController _pageController = PageController();

  final List<String> messages = [
    "Hi! I'm your friend and guide 😊",
    "I'll help you explore this app!",
    "You can learn and play with me.",
    "Swipe right to go to the next message.",
    "Ready? Let's start the adventure!",
  ];

  late final List<String> avatars;

  int _currentPage = 0;
  String _displayedText = '';
  int _typingCharIndex = 0;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    avatars = List.generate(messages.length,
            (index) => widget.selectedGender == 'boy' ? 'assets/boy.png' : 'assets/girl.png');
    _startTypingAnimation();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTypingAnimation() {
    _typingTimer?.cancel();
    _typingCharIndex = 0;
    _displayedText = '';

    _typingTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_typingCharIndex < messages[_currentPage].length) {
        setState(() {
          _displayedText += messages[_currentPage][_typingCharIndex];
          _typingCharIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onPageChanged(int page) {
    if (page == messages.length) {
      Navigator.pushReplacementNamed(context, '/Index');
      return;
    }
    setState(() {
      _currentPage = page;
    });
    _startTypingAnimation();
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/Index');
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = 80; // Bigger avatar size for onboarding

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Chat'),
        backgroundColor: Colors.lightBlue,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Skip',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: messages.length + 1,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              if (index == messages.length) {
                return const Center(child: CircularProgressIndicator());
              }
              return Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundImage: AssetImage(avatars[index]),
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.shade200,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _currentPage == index ? _displayedText : '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Dots indicator
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(messages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: _currentPage == index ? 20 : 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.blueAccent
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(7),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

