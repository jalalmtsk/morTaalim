import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BackupTutorialPage extends StatelessWidget {
  const BackupTutorialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();

    final List<_TutorialStep> steps = [
      _TutorialStep(
        animation: 'assets/animations/FirstTouchAnimations/progerss.json',
        title: "What is Backup?",
        description: "A backup code saves your progress securely so you can restore it later or on another device.",
      ),
      _TutorialStep(
        animation: 'assets/animations/FirstTouchAnimations/UploadingCloud.json',
        title: "How to Save",
        description: "Tap 'Save Backup' and copy your unique code. Store it somewhere safe – it’s your key to recovery.",
      ),
      _TutorialStep(
        animation: 'assets/lottie/restore_data.json',
        title: "How to Restore",
        description: "Use 'Load Backup' and paste your saved code. Your progress will be restored instantly.",
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
                Lottie.asset(step.animation, width: 220, height: 220, repeat: true),
                const SizedBox(height: 32),
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
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
                        child: const Text("Back"),
                      )
                    else
                      const SizedBox(width: 64), // spacer

                    if (index < steps.length - 1)
                      ElevatedButton(
                        onPressed: () => controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                        child: const Text("Next"),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Done"),
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
  final String animation;
  final String title;
  final String description;

  _TutorialStep({
    required this.animation,
    required this.title,
    required this.description,
  });
}
