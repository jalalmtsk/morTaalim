import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mortaalim/main.dart';

class GoogleAccountCard extends StatefulWidget {
  final Function()? onDisconnectCallback;

  const GoogleAccountCard({super.key, this.onDisconnectCallback});

  @override
  State<GoogleAccountCard> createState() => _GoogleAccountCardState();
}

class _GoogleAccountCardState extends State<GoogleAccountCard> {
  bool _isConnecting = false;
  String? _googleError;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isConnecting = true;
      _googleError = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(tr(context).signedInWithGoogle)),
        );
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _googleError = e.toString();
      });
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnectGoogle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null &&
          user.providerData.any((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID)) {
        await user.unlink(GoogleAuthProvider.PROVIDER_ID);
        await GoogleSignIn().signOut();
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.signInAnonymously();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(tr(context).disconnectedNowinanonymousmode)),
          );
          widget.onDisconnectCallback?.call();
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${tr(context).failedToDisconnect}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(tr(context).googleAccount,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (user != null &&
                user.providerData.any((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${tr(context).connected}: ${user.email ?? "${tr(context).googleAccount}"}",
                          style: const TextStyle(color: Colors.green),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label:  Text(tr(context).disconnect),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title:  Text("${tr(context).disconnected} ${tr(context).googleAccount}"),
                          content:  Text(
                              tr(context).areYouSureYouWantToDisconnectYourGoogleAccountYouWillBeSwitchedToAnonymousMode),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child:  Text(tr(context).cancel),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child:  Text(tr(context).disconnected),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _disconnectGoogle();
                      }
                    },
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(tr(context).notConnectedYet, style: TextStyle(color: Colors.orange)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: _isConnecting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.login),
                    label: Text(
                      _isConnecting ? "${tr(context).connecting}..." : "${tr(context).connectGoogleAccount}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isConnecting ? null : _signInWithGoogle,
                  ),
                  if (_googleError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _googleError!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
