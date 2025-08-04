import 'package:flutter/material.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage>
    with SingleTickerProviderStateMixin {
  final List<String> _languages = ['English', 'Français', 'العربية', 'Español', 'Deutsch', '中文'];
  int? _selectedIndex;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final Color _primaryColor = Colors.deepOrange.shade700;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectLanguage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Optionally notify parent or provider here about selection
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Your Language',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              'Choose the language you want to use in the app.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: List.generate(_languages.length, (index) {
                final isSelected = _selectedIndex == index;
                return ChoiceChip(
                  label: Text(
                    _languages[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : _primaryColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: _primaryColor,
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (_) => _selectLanguage(index),
                );
              }),
            ),

            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: _selectedIndex == null ? null : () {
                // Handle next action or save language selection here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language Selected: ${_languages[_selectedIndex!]}'),
                    backgroundColor: _primaryColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
                // You could also trigger navigation or state update here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Continue',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            )
          ],
        ),
      ),
    );
  }
}
