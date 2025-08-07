import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../XpSystem.dart';
import '../tools/SplashPage/splashScreen.dart';
import 'LogIn.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          final xpManager = Provider.of<ExperienceManager>(context, listen: false);
          if (xpManager.lastLogin == null || xpManager.lastLogin!.isBefore(DateTime.now().subtract(const Duration(seconds: 2)))) {
            xpManager.onAppStart(snapshot.data!.uid);
          }
          return const SplashPage(); // ✅ no more callback
        } else {
          return LoginPage();
        }
      },
    );
  }
}