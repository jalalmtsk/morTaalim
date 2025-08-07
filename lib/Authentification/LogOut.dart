import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DisconnectButton extends StatelessWidget {
  final VoidCallback? onSignedOut;

  const DisconnectButton({Key? key, this.onSignedOut}) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();  // <--- important!

      // Optional: Callback after sign out
      if (onSignedOut != null) onSignedOut!();

      // Navigate to login or landing screen (replace '/login' with your route)
      Navigator.of(context).pushReplacementNamed('Auth');
    } catch (e) {
      // Handle errors here, e.g., show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Déconnexion'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange, // match your theme
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => _signOut(context),
    );
  }
}

/*
DisconnectButton(
  onSignedOut: () {
    print("User signed out!");
    // Do any other cleanup if needed
  },
),
 */