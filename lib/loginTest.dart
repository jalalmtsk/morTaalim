import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'XpSystem.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInAnonymously();

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

        try {
          await experienceManager.initUser();
        } catch (e) {
          // Handle initUser failure gracefully (probably offline)
          if (kDebugMode) {
            print('Failed to init user (offline?): $e');
          }
          // Optionally show a non-blocking message or just ignore
        }

        experienceManager.onAppStart(user.uid);
      } else {
        setState(() {
          _errorMessage = "Erreur: utilisateur non trouvé après connexion.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de connexion : $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bienvenue sur MoorTaalim",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _signInAnonymously,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Connexion Anonyme", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
