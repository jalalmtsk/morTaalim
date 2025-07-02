import 'package:flutter/material.dart';
import 'package:mortaalim/games/Tracing_Alphabet_app/TracingAlphabetPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelectorPage extends StatelessWidget {
  const LanguageSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    final languages = [
      LanguageOption(
        name: 'French Letters (A, B, C...)',
        languageCode: 'french',
        icon: Icons.language,
        color: Colors.deepOrange,
      ),
      LanguageOption(
        name: 'حروف عربية',
        languageCode: 'arabic',
        icon: Icons.menu_book,
        color: Colors.deepOrange.shade700,
      ),
      // You can add more languages here in the future!
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          tr.alphabetTracing,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        elevation: 6,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade200, Colors.deepOrange.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Fun top header with icon and welcome text
            const SizedBox(height: 10),
            Icon(Icons.menu_book, size: 90, color: Colors.deepOrange.shade400),
            const SizedBox(height: 16),
            Text(
              'Choose your language to start tracing!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Language options grid
            Expanded(
              child: GridView.builder(
                itemCount: languages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 per row
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  return LanguageCard(language: lang);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class LanguageOption {
  final String name;
  final String languageCode;
  final IconData icon;
  final Color color;

  LanguageOption({
    required this.name,
    required this.languageCode,
    required this.icon,
    required this.color,
  });
}


class LanguageCard extends StatefulWidget {
  final LanguageOption language;

  const LanguageCard({super.key, required this.language});

  @override
  State<LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<LanguageCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlphabetTracingPage(language: widget.language.languageCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          decoration: BoxDecoration(
            color: lang.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: lang.color.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(lang.icon, size: 52, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                lang.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black38,
                      offset: Offset(1, 1),
                    )
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
