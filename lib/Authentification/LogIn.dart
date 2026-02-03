import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../XpSystem.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;

  // Animated welcome text
  final List<String> _welcomeTexts = [
    "MoorTaalim",
    "Welcome",
    "Bienvenue",
    "مرحبا",
    "Benvenuto",
    "MoorTaalim",
    "Merhaba",
    "Willkommen",
    "MoorTaalim",
    "Bienvenido",
    "ようこそ",
  ];

  int _currentTextIndex = 0;
  String _displayedText = "";
  Timer? _typingTimer;
  Timer? _changeTextTimer;

  late AnimationController _logoController;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playBackgroundMusic('assets/audios/BackGround_Audio/CuteBabySong_bg.mp3');
    _setupLogoAnimation();
    _startTypewriterEffect();
  }

  void _setupLogoAnimation() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _logoController.forward();
  }

  void _startTypewriterEffect() {
    _typeText(_welcomeTexts[_currentTextIndex]);
    _changeTextTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _currentTextIndex = (_currentTextIndex + 1) % _welcomeTexts.length;
      _typeText(_welcomeTexts[_currentTextIndex]);
    });
  }

  void _typeText(String text) {
    _typingTimer?.cancel();
    _displayedText = "";
    int index = 0;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (index < text.length) {
        setState(() => _displayedText += text[index]);
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _changeTextTimer?.cancel();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    if (!await _checkConnection()) return;

    final confirmed = await _showConfirmationDialog(
      tr(context).loginWithoutGoogle,
        tr(context).loginWithoutGoogleDescription
    );
    if (!confirmed) return;

    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      _showFriendlyError(e);
    } finally {
      _setLoading(false);
    }
  }
/*
  Future<void> _signInWithGoogle() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound("clickButton");
    if (!await _checkConnection()) return;

    final confirmed = await _showConfirmationDialog(
      tr(context).loginWithGoogle,
        tr(context).loginWithGoogleDescription    );
    if (!confirmed) return;

    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _setLoading(false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      UserCredential userCredential;

      if (currentUser != null && currentUser.isAnonymous) {
        userCredential = await currentUser.linkWithCredential(credential);
      } else {
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
      } else {
        _showError("Erreur : utilisateur non trouvé après connexion.");
      }
    } catch (e) {
      _showFriendlyError(e);
    } finally {
      _setLoading(false);
    }
  }


 */
  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final experienceManager = Provider.of<ExperienceManager>(context, listen: false);
      experienceManager.onAppStart(user.uid);
    }
  }

  Future<bool> _checkConnection() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      _showError(tr(context).noInternetConnection);
      audioManager.playEventSound("invalid");


      return false;
    }
    return true;
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  void _showFriendlyError(Object e) {
    debugPrint("FULL GOOGLE LOGIN ERROR: $e");
    setState(() => _errorMessage = tr(context).noInternetConnection); // Show the real error for testing
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () {
              audioManager.playEventSound("cancelButton");
              Navigator.of(context).pop(false);
    } ,
            child:  Text(tr(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              audioManager.playEventSound('clickButton');
              Navigator.of(context).pop(true);
              audioManager.stopMusic();
               },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child:  Text(tr(context).confirm),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget _buildLoginButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: color.withOpacity(0.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Language selector dropdown
                // Stylized language selector button
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Locale>(
                        value: Provider.of<ExperienceManager>(context).locale,
                        icon: const Icon(Icons.language, color: Colors.black87),
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        items: const [
                          DropdownMenuItem(value: Locale('fr'), child: Text('🇫🇷 FR')),
                          DropdownMenuItem(value: Locale('en'), child: Text('🇺🇸 EN')),
                          DropdownMenuItem(value: Locale('ar'), child: Text('🇸🇦 AR')),
                          DropdownMenuItem(value: Locale('de'), child: Text('🇩🇪 DE')),
                          DropdownMenuItem(value: Locale('zgh'), child: Text('🇲🇦 ZGH')),
                          // Ajoute d’autres langues si nécessaire
                        ],
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null) {
                            MyAppStateHelper.changeLanguage(context, newLocale);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // Animated Logo
                ScaleTransition(
                  scale: _logoScale,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/logo3.png',
                      height: 140,
                      width: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Typewriter Welcome Text
                Text(
                  _displayedText,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // Lottie animation
                Image.asset(
                  'assets/icons/MoorTaalimLogoChildren_AuthScreen.png',
                  width: 240,
                  height: 240,
                ),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _buildLoginButton(
                  text:tr(context).enjoy ,
                  onPressed: (){
                    audioManager.playEventSound("clickButton");
                    _signInAnonymously();
                  },
                  color: Colors.deepOrange,
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 30),
                 Text(
                  tr(context).manualBackupNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }
}



