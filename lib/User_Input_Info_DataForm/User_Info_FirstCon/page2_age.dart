import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── NOTE : AdHelper.setChildMode() supprimé ─────────────────────────────────
// La config COPPA est fixée une fois pour toutes dans AdHelper.initializeAds().
// La sélection d'âge ici sert uniquement à personnaliser l'expérience (niveau,
// difficulté, langue) — elle n'affecte plus jamais les annonces.
// ─────────────────────────────────────────────────────────────────────────────

class AgeRange {
  final String label;
  final int minAge;
  final int maxAge;
  final String emoji;

  const AgeRange({
    required this.label,
    required this.minAge,
    required this.maxAge,
    required this.emoji,
  });
}

// ✅ Uniquement les tranches pertinentes pour une appli primaire
const List<AgeRange> ageRanges = [
  AgeRange(label: "3 – 6",   minAge: 3,  maxAge: 6,  emoji: "🧸"),
  AgeRange(label: "7 – 9",   minAge: 7,  maxAge: 9,  emoji: "🎒"),
  AgeRange(label: "10 – 12", minAge: 10, maxAge: 12, emoji: "📚"),
];

class AgeCheckPage extends StatefulWidget {
  final VoidCallback? onNext;

  const AgeCheckPage({Key? key, this.onNext}) : super(key: key);

  @override
  State<AgeCheckPage> createState() => _AgeCheckPageState();
}

class _AgeCheckPageState extends State<AgeCheckPage> {
  AgeRange? selectedRange;

  Future<void> _saveAge(AgeRange range) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('age', range.minAge);
    await prefs.setBool('age_check_completed', true);
    // ✅ isChild et setChildMode supprimés — pubs toujours en mode enfant
  }

  void _onConfirm() async {
    if (selectedRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context).pleaseEnterYourAge),
          backgroundColor: Colors.deepOrange.shade700,
        ),
      );
      return;
    }

    await _saveAge(selectedRange!);
    widget.onNext?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/FirstTouchAnimations/Thinking.json',
                width: 200,
                repeat: false,
              ),

              const SizedBox(height: 12),

              Text(
                tr(context).pleaseEnterYourAge,
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.4,
                children: ageRanges.map((range) {
                  final isSelected = selectedRange == range;
                  return GestureDetector(
                    onTap: () => setState(() => selectedRange = range),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(range.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            range.label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.deepOrange
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              AnimatedOpacity(
                opacity: selectedRange != null ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _onConfirm,
                  child: Text(
                    tr(context).confirm,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (selectedRange != null)
                Text(
                  "${selectedRange!.emoji}  ${selectedRange!.label} ${tr(context).age}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}