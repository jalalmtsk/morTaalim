import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Stories.dart';
import 'LanguageManager.dart';
import '../../XpSystem.dart';

// ─── Quiz questions per story ──────────────────────────────────────────────────
// Each question: text, 4 options (index 0 = correct), optional emoji
class _QuizQuestion {
  final String question;
  final List<String> options; // index 0 is ALWAYS correct
  final String emoji;
  const _QuizQuestion({required this.question, required this.options, this.emoji = '🤔'});
}

// Map: story title → list of 3 questions
final Map<String, List<_QuizQuestion>> _storyQuizzes = {
  'Flick the Dancing Fox': [
    _QuizQuestion(
      question: 'What did Flick love to do?',
      emoji: '🦊',
      options: ['Dance in the rain', 'Sleep all day', 'Eat fish', 'Climb trees'],
    ),
    _QuizQuestion(
      question: 'Who did Flick invite to the rain dance party?',
      emoji: '🐰',
      options: ['Benny the bunny', 'A bear', 'A turtle', 'A bird'],
    ),
    _QuizQuestion(
      question: 'What appeared in the sky at the end?',
      emoji: '🌈',
      options: ['A rainbow', 'A storm', 'The moon', 'A kite'],
    ),
  ],
  'Sunny the Squirrel': [
    _QuizQuestion(
      question: 'What did Sunny find in the forest?',
      emoji: '🌰',
      options: ['A big pile of acorns', 'A golden egg', 'A lost puppy', 'A treasure map'],
    ),
    _QuizQuestion(
      question: 'What did Sunny decide to do with the acorns?',
      emoji: '🤝',
      options: ['Share with friends', 'Eat them alone', 'Hide them underground', 'Trade them for honey'],
    ),
    _QuizQuestion(
      question: 'How did Sunny feel at the end of the day?',
      emoji: '😊',
      options: ['Happy and thankful', 'Tired and grumpy', 'Bored and lonely', 'Scared and cold'],
    ),
  ],
  'Nina the Sleepy Narwhal': [
    _QuizQuestion(
      question: 'Where does Nina live?',
      emoji: '🌊',
      options: ['In the deep blue sea', 'In a pond', 'In the jungle', 'On a mountain'],
    ),
    _QuizQuestion(
      question: 'What happened when Nina napped on a turtle?',
      emoji: '🐢',
      options: ['It swam very fast!', 'It fell asleep too', 'It sang a song', 'It flew into the sky'],
    ),
    _QuizQuestion(
      question: 'What was the surprise on the rock?',
      emoji: '🐙',
      options: ['A sleeping octopus', 'A treasure chest', 'A baby shark', 'A singing crab'],
    ),
  ],
};

// ═════════════════════════════════════════════════════════════════════════════
class StoryQuizPage extends StatefulWidget {
  final Story story;
  final AppLanguage language;
  final Color accentColor;

  const StoryQuizPage({
    super.key,
    required this.story,
    this.language = AppLanguage.en,
    this.accentColor = const Color(0xFF7C4DFF),
  });

  @override
  State<StoryQuizPage> createState() => _StoryQuizPageState();
}

class _StoryQuizPageState extends State<StoryQuizPage> with TickerProviderStateMixin {
  late List<_QuizQuestion> _questions;
  late List<List<String>> _shuffledOptions; // shuffled per question
  late List<int> _correctIndexes;           // where correct answer ended up after shuffle

  int _currentQ = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _correctCount = 0;
  bool _showResult = false;

  late AnimationController _cardCtrl;
  late Animation<double> _cardScale;
  late AnimationController _resultCtrl;
  late Animation<double> _resultScale;
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _setupQuestions();

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _cardScale = CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut);

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _resultScale = CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut);

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shake = Tween(begin: 0.0, end: 1.0).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _resultCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _setupQuestions() {
    final raw = _storyQuizzes[widget.story.title] ?? _defaultQuestions(widget.story);
    _questions = raw;

    // Shuffle options but remember where correct (index 0) landed
    final rng = Random();
    _shuffledOptions = [];
    _correctIndexes = [];
    for (final q in raw) {
      final opts = List<String>.from(q.options);
      final correct = opts[0]; // correct is always index 0 in source
      opts.shuffle(rng);
      _shuffledOptions.add(opts);
      _correctIndexes.add(opts.indexOf(correct));
    }
  }

  List<_QuizQuestion> _defaultQuestions(Story story) {
    return [
      _QuizQuestion(
        question: 'What is the main character\'s name in "${story.title}"?',
        emoji: '⭐',
        options: [
          story.pages.isNotEmpty ? story.pages[0].characterName : 'Unknown',
          'Max', 'Luna', 'Spike',
        ],
      ),
      _QuizQuestion(
        question: 'How many pages does this story have?',
        emoji: '📖',
        options: [
          '${story.pages.length}',
          '${story.pages.length + 1}',
          '${story.pages.length + 2}',
          '1',
        ],
      ),
      _QuizQuestion(
        question: 'Did you enjoy this story?',
        emoji: '😊',
        options: ['Yes, it was great!', 'It was okay', 'Not really', 'I fell asleep'],
      ),
    ];
  }

  void _onAnswer(int index) async {
    if (_answered) return;
    final correct = index == _correctIndexes[_currentQ];
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (correct) _correctCount++;
    });

    if (!correct) {
      _shakeCtrl.forward(from: 0);
    }

    await Future.delayed(const Duration(milliseconds: 1200));

    if (_currentQ < _questions.length - 1) {
      // Next question
      await _cardCtrl.reverse();
      setState(() {
        _currentQ++;
        _selectedIndex = null;
        _answered = false;
      });
      _cardCtrl.forward(from: 0);
    } else {
      // Show result
      // Award XP
      if (mounted) {
        final xp = Provider.of<ExperienceManager>(context, listen: false);
        xp.addXP(_correctCount * 5, context: context);
      }
      setState(() => _showResult = true);
      _resultCtrl.forward(from: 0);
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_showResult) return _buildResultScreen();

    final q   = _questions[_currentQ];
    final opts = _shuffledOptions[_currentQ];
    final correctIdx = _correctIndexes[_currentQ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.accentColor.withOpacity(0.85),
              const Color(0xFF1A0050),
              const Color(0xFF0D1A40),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '🧠 Story Quiz',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                            ),
                          ),
                          Text(
                            widget.story.title,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Score so far
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⭐ $_correctCount / ${_currentQ + (_answered ? 1 : 0)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress dots
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_questions.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: i == _currentQ ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: i < _currentQ
                        ? const Color(0xFFFFD700)
                        : i == _currentQ
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                  ),
                )),
              ),

              const Spacer(),

              // Question card
              ScaleTransition(
                scale: _cardScale,
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_answered && _selectedIndex != correctIdx
                        ? sin(_shake.value * pi * 6) * 10
                        : 0, 0),
                    child: child,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(q.emoji, style: const TextStyle(fontSize: 52)),
                        const SizedBox(height: 14),
                        Text(
                          q.question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.bold, height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Answer options — 2×2 grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: List.generate(opts.length, (i) {
                    Color btnColor = Colors.white.withOpacity(0.15);
                    Color borderColor = Colors.white.withOpacity(0.3);
                    IconData? trailingIcon;

                    if (_answered) {
                      if (i == correctIdx) {
                        btnColor = const Color(0xFF4CAF50).withOpacity(0.85);
                        borderColor = Colors.greenAccent;
                        trailingIcon = Icons.check_circle_rounded;
                      } else if (i == _selectedIndex) {
                        btnColor = const Color(0xFFE53935).withOpacity(0.75);
                        borderColor = Colors.redAccent;
                        trailingIcon = Icons.cancel_rounded;
                      }
                    }

                    return GestureDetector(
                      onTap: () => _onAnswer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: btnColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: _answered && i == correctIdx
                              ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 12)]
                              : [],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    opts[i],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (trailingIcon != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(trailingIcon, color: Colors.white, size: 18),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Result screen ──────────────────────────────────────────────────────────
  Widget _buildResultScreen() {
    final perfect = _correctCount == _questions.length;
    final good    = _correctCount >= _questions.length * 0.67;
    final emoji   = perfect ? '🏆' : good ? '🌟' : '💪';
    final title   = perfect ? 'Perfect Score!' : good ? 'Great Job!' : 'Keep Practicing!';
    final xpEarned = _correctCount * 2;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: perfect
                ? [const Color(0xFFFF9800), const Color(0xFFFF6D00), const Color(0xFF8B0000)]
                : good
                ? [const Color(0xFF7C4DFF), const Color(0xFF3D1A8A)]
                : [const Color(0xFF37474F), const Color(0xFF1A237E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _resultScale,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 80)),
                    const SizedBox(height: 16),
                    Text(title,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_correctCount out of ${_questions.length} correct',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    // XP badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 16)],
                      ),
                      child: Text(
                        '⭐ +$xpEarned XP Earned!',
                        style: const TextStyle(
                          color: Colors.brown, fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          i < _correctCount ? '⭐' : '☆',
                          style: const TextStyle(fontSize: 40),
                        ),
                      )),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            onPressed: () {
                              setState(() {
                                _currentQ = 0;
                                _selectedIndex = null;
                                _answered = false;
                                _correctCount = 0;
                                _showResult = false;
                              });
                              _setupQuestions();
                              _cardCtrl.forward(from: 0);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 8,
                            ),
                            icon: const Icon(Icons.home_rounded, color: Colors.brown),
                            label: const Text('Done!',
                                style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 15)),
                            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst || r.settings.name == 'AppStories'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}