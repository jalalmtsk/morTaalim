import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Privacy Policy",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Last updated: January 2025",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              const Text(
                "1. Introduction",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "Welcome to MoorTaalim. Your privacy is very important to us. "
                    "This Privacy Policy explains how we collect, use, and protect your personal information "
                    "when you use our application.",
              ),
              const SizedBox(height: 20),

              const Text(
                "2. Information We Collect",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "- Personal Information: Name, email, and username if provided.\n"
                    "- Usage Data: App interactions, language preferences, and progress data.\n"
                    "- Device Information: Device type, operating system, and app version.",
              ),
              const SizedBox(height: 20),

              const Text(
                "3. How We Use Your Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "We use your data to:\n"
                    "- Improve app functionality and user experience.\n"
                    "- Provide support and respond to inquiries.\n"
                    "- Send notifications if you opt in.",
              ),
              const SizedBox(height: 20),

              const Text(
                "4. Data Sharing",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "We do not sell your personal information. "
                    "However, we may share data with trusted third-party services "
                    "only to provide app-related functionalities such as analytics or ads.",
              ),
              const SizedBox(height: 20),

              const Text(
                "5. Security",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "We implement appropriate technical and organizational measures "
                    "to protect your information from unauthorized access or misuse.",
              ),
              const SizedBox(height: 20),

              const Text(
                "6. Your Rights",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "You may:\n"
                    "- Request to access, modify, or delete your personal data.\n"
                    "- Opt out of notifications or data collection where applicable.",
              ),
              const SizedBox(height: 20),

              const Text(
                "7. Children's Privacy",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "MoorTaalim is designed for children with parental supervision features. "
                    "We do not knowingly collect personal information from children without consent from a parent or guardian.",
              ),
              const SizedBox(height: 20),

              const Text(
                "8. Contact Us",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "If you have any questions about this Privacy Policy, you can contact us at:\n"
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
