import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../main.dart';

class BackupTutorialPage extends StatelessWidget {
  const BackupTutorialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();

    final List<_TutorialStep> steps = [
      _TutorialStep(
        assetPath: 'assets/animations/UI_Animations/TechnologyNetwork.json',
        isAnimation: true,
        titleKey: 'backupWhatIs',
        descriptionKey: 'backupWhatIsDesc',
      ),
      _TutorialStep(
        assetPath: 'assets/images/UI/utilities/SaveButton.jpg',
        isAnimation: false,
        titleKey: 'backupHowSave',
        descriptionKey: 'backupHowSaveDesc',
      ),
      _TutorialStep(
        assetPath: 'assets/animations/UI_Animations/TechnologyNetwork.json',
        isAnimation: true,
        titleKey: 'backupHowRestore',
        descriptionKey: 'backupHowRestoreDesc',
      ),
    ];

    return Scaffold(
      body: PageView.builder(
        controller: controller,
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (step.isAnimation)
                  Lottie.asset(step.assetPath, width: 220, height: 220, repeat: true)
                else
                  Image.asset(step.assetPath, width: 220, height: 220, fit: BoxFit.contain),
                const SizedBox(height: 32),
                Text(
                  tr(context).backupWhatIs, // <-- use the key directly
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  tr(context).backupWhatIsDesc, // <-- use the key directly
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (index > 0)
                      TextButton(
                        onPressed: () => controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                        child: Text(tr(context).back),
                      )
                    else
                      const SizedBox(width: 64), // spacer

                    if (index < steps.length - 1)
                      ElevatedButton(
                        onPressed: () => controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                        child: Text(tr(context).next),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr(context).done),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TutorialStep {
  final String assetPath;
  final bool isAnimation;
  final String titleKey;
  final String descriptionKey;

  _TutorialStep({
    required this.assetPath,
    required this.isAnimation,
    required this.titleKey,
    required this.descriptionKey,
  });
}
