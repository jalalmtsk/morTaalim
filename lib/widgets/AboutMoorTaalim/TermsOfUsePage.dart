import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms of Use"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Terms of Use",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Last updated: January 2025",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              const Text(
                "1. Acceptance of Terms",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "By using MoorTaalim, you agree to comply with these Terms of Use. "
                    "If you do not agree with these terms, please do not use the application.",
              ),
              const SizedBox(height: 20),

              const Text(
                "2. License to Use",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "MoorTaalim grants you a personal, non-transferable, and non-exclusive license "
                    "to use the app for educational and personal purposes only.",
              ),
              const SizedBox(height: 20),

              const Text(
                "3. User Responsibilities",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "When using MoorTaalim, you agree to:\n"
                    "- Not misuse the application or its content.\n"
                    "- Not attempt to hack, reverse-engineer, or disrupt the app.\n"
                    "- Provide accurate information if required for account features.",
              ),
              const SizedBox(height: 20),

              const Text(
                "4. Intellectual Property",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "All content, logos, graphics, and designs within MoorTaalim are the property "
                    "of MoorTaalim and protected by copyright laws. Unauthorized use is strictly prohibited.",
              ),
              const SizedBox(height: 20),

              const Text(
                "5. Limitation of Liability",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "MoorTaalim is provided on an 'as-is' basis. We are not liable for any damages, "
                    "losses, or data issues arising from the use of the app.",
              ),
              const SizedBox(height: 20),

              const Text(
                "6. Modifications to Terms",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "We reserve the right to modify these Terms of Use at any time. "
                    "Continued use of the app after changes implies acceptance of the updated terms.",
              ),
              const SizedBox(height: 20),

              const Text(
                "7. Termination",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "We reserve the right to suspend or terminate your access to MoorTaalim "
                    "if you violate these terms or engage in prohibited conduct.",
              ),
              const SizedBox(height: 20),

              const Text(
                "8. Contact Us",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "If you have any questions about these Terms of Use, please contact us at:\n"
                    "support@moortaalim.com",
              ),
              const SizedBox(height: 30),

              // Copyright
              Center(
                child: Text(
                  "© ${DateTime.now().year} MoorTaalim. All rights reserved.",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
