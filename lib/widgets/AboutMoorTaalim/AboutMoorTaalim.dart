import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mortaalim/widgets/AboutMoorTaalim/FeedbackPage.dart';
import 'package:mortaalim/widgets/AboutMoorTaalim/PrivacyPolicyPage.dart';
import 'package:mortaalim/widgets/AboutMoorTaalim/TermsOfUsePage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutMoorTaalimPage extends StatefulWidget {
  const AboutMoorTaalimPage({Key? key}) : super(key: key);

  @override
  State<AboutMoorTaalimPage> createState() => _AboutMoorTaalimPageState();
}

class _AboutMoorTaalimPageState extends State<AboutMoorTaalimPage> {
  String appVersion = "Loading...";
  final GlobalKey<FormState> _feedbackFormKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();

  bool _expandedMission = false;
  bool _expandedFuture = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "${info.version} (Build ${info.buildNumber})";
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open link")),
      );
    }
  }

  Future<void> _launchAppStoreRating() async {
    const storeUrl = "https://play.google.com/store/apps/details?id=your.package.name";
    await _launchURL(storeUrl);
  }

  void _showRateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enjoying MoorTaalim?"),
        content: const Text("If you like our app, please give us 5 stars on the store!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No, thanks"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchAppStoreRating();
            },
            child: const Text("Rate now"),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Feedback"),
        content: Form(
          key: _feedbackFormKey,
          child: TextFormField(
            controller: _feedbackController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Tell us what you think...",
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your feedback';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context);
            _feedbackController.clear();
          }, child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (_feedbackFormKey.currentState!.validate()) {
                // Here you could send the feedback to your server or email
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thank you for your feedback!")),
                );
                _feedbackController.clear();
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      icon: FaIcon(icon, color: color),
      iconSize: 40,
      onPressed: onPressed,
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required String content,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            ListTile(
              leading: Icon(icon, color: Colors.deepOrange),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: Colors.deepOrange),
              onTap: onToggle,
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.feedback),
        label: const Text("Feedback"),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeedbackPage())),
      ),
      appBar: AppBar(
        title: const Text("About MoorTaalim"),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: const AssetImage("assets/icons/logo3.png"),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(height: 15),
                const Text(
                  "MoorTaalim",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "Version $appVersion",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 15),
                const Text(
                  "An innovative educational platform blending learning, games, and culture "
                      "to make education fun and engaging for students in Morocco and beyond.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildExpandableCard(
            title: "Our Mission",
            icon: Icons.flag,
            content:
            "MoorTaalim aims to empower students by providing interactive educational content "
                "that respects Moroccan culture and promotes a love of learning. We believe education "
                "should be enjoyable, accessible, and culturally relevant.",
            expanded: _expandedMission,
            onToggle: () {
              setState(() => _expandedMission = !_expandedMission);
            },
          ),

          const SizedBox(height: 12),

          _buildExpandableCard(
            title: "Future Plans",
            icon: Icons.upcoming,
            content:
            "We're continuously working to add new courses, exciting multiplayer games, "
                "and advanced features like personalized learning paths and community forums "
                "to connect learners and educators.",
            expanded: _expandedFuture,
            onToggle: () {
              setState(() => _expandedFuture = !_expandedFuture);
            },
          ),

          const SizedBox(height: 20),

          const Divider(),

          const SizedBox(height: 10),

          // Social Media Section
          const Text(
            "Follow us on",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(
                FontAwesomeIcons.facebook,
                Colors.blue,
                    () => _launchURL("https://facebook.com/moortaalim"),
              ),
              const SizedBox(width: 15),
              _buildSocialIcon(
                FontAwesomeIcons.instagram,
                Colors.purple,
                    () => _launchURL("https://instagram.com/moortaalim"),
              ),
              const SizedBox(width: 15),
              _buildSocialIcon(
                FontAwesomeIcons.tiktok,
                Colors.black,
                    () => _launchURL("https://tiktok.com/@moortaalim"),
              ),
              const SizedBox(width: 15),
              _buildSocialIcon(
                FontAwesomeIcons.youtube,
                Colors.red,
                    () => _launchURL("https://youtube.com/moortaalim"),
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Divider(),

          const SizedBox(height: 10),

          // Contact Info
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.email, color: Colors.deepOrange),
              title: const Text("Contact Us"),
              subtitle: const Text("moortaalim@gmail.com"),
              onTap: () => _launchURL("mailto:moortaalim@gmail.com"),
            ),
          ),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.blueGrey),
              title: const Text("Privacy Policy"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyPage())),
            ),
          ),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.gavel, color: Colors.brown),
              title: const Text("Terms of Use"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TermsOfUsePage())),
            ),
          ),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.people, color: Colors.green),
              title: const Text("Credits"),
              onTap: () => Navigator.of(context).pushNamed("Credits"),
            ),
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              "© ${DateTime.now().year} MoorTaalim. All rights reserved.",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
