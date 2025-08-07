import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../tools/audio_tool/Audio_Manager.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool bgExpanded = true;
  bool sfxExpanded = false;
  bool buttonExpanded = false;
  bool alertExpanded = false;
  bool _isConnecting = false;
  String? _googleError;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isConnecting = true;
      _googleError = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() {
          _isConnecting = false;
        });
        return; // User cancelled
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecté avec succès via Google !')),
        );
        setState(() {}); // refresh UI with new user state
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _googleError = e.message ?? "Erreur lors de la connexion avec Google.";
      });
    } catch (e) {
      setState(() {
        _googleError = "Erreur inattendue : $e";
      });
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnectGoogle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Unlink Google provider if linked
        if (user.providerData.any((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID)) {
          await user.unlink(GoogleAuthProvider.PROVIDER_ID);
        }
        // Sign out from Google and Firebase
        await GoogleSignIn().signOut();
        await FirebaseAuth.instance.signOut();

        // Optionally sign in anonymously after disconnect
        await FirebaseAuth.instance.signInAnonymously();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Compte Google déconnecté. Vous êtes maintenant en mode anonyme.")),
          );
          setState(() {}); // Refresh UI
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de la déconnexion : $e")),
        );
      }
    }
  }

  Widget buildVolumeControl({
    required String title,
    required bool expanded,
    required Function(bool) onExpandChanged,
    required bool isMuted,
    required Function toggleMute,
    required double volume,
    required Function(double) onVolumeChanged,
    required IconData icon,
    required Color color,
    bool showTestButton = false,
    VoidCallback? onTest,
  }) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: (v) {
            audioManager.playEventSound("PopClick");
            onExpandChanged(v);
          },
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(40),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          trailing: Switch(
            value: !isMuted,
            onChanged: (_) {
              audioManager.playEventSound('toggleButton');
              toggleMute();
            },
            activeColor: color,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                      icon:
                      Icon(Icons.volume_down, color: isMuted ? Colors.grey : color),
                      onPressed: isMuted
                          ? null
                          : () {
                        audioManager.playEventSound('clickButton2');
                        onVolumeChanged((volume - 0.1).clamp(0.0, 1.0));
                      }),
                  Expanded(
                    child: Slider(
                      value: volume,
                      min: 0,
                      max: 1,
                      divisions: 10,
                      activeColor: color,
                      onChanged: isMuted ? null : (v) => onVolumeChanged(v),
                    ),
                  ),
                  Text(
                    "${(volume * 100).round()}%",
                    style: TextStyle(
                        color: isMuted ? Colors.grey : color, fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up, color: isMuted ? Colors.grey : color),
                    onPressed: isMuted
                        ? null
                        : () {
                      audioManager.playEventSound('clickButton2');
                      onVolumeChanged((volume + 0.1).clamp(0.0, 1.0));
                    },
                  ),
                  if (showTestButton)
                    IconButton(
                      icon: Icon(Icons.play_arrow, color: color),
                      onPressed: isMuted ? null : onTest,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
      backgroundColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      audioManager.playEventSound('cancelButton');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, size: 26, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(),

              // Content
              Expanded(
                child: ListView(
                  children: [
                    buildVolumeControl(
                      title: "Background Music",
                      expanded: bgExpanded,
                      onExpandChanged: (v) => setState(() => bgExpanded = v),
                      isMuted: audioManager.isBgMuted,
                      toggleMute: audioManager.toggleBgMute,
                      volume: audioManager.bgVolume,
                      onVolumeChanged: audioManager.setBgVolume,
                      icon: Icons.music_note,
                      color: Colors.deepOrange,
                    ),
                    buildVolumeControl(
                      title: "Sound Effects",
                      expanded: sfxExpanded,
                      onExpandChanged: (v) => setState(() => sfxExpanded = v),
                      isMuted: audioManager.isSfxMuted,
                      toggleMute: audioManager.toggleSfxMute,
                      volume: audioManager.sfxVolume,
                      onVolumeChanged: audioManager.setSfxVolume,
                      icon: Icons.speaker,
                      color: Colors.blue,
                      showTestButton: true,
                      onTest: () => audioManager.playSfx(
                          'assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3'),
                    ),
                    buildVolumeControl(
                      title: "Button Sounds",
                      expanded: buttonExpanded,
                      onExpandChanged: (v) => setState(() => buttonExpanded = v),
                      isMuted: audioManager.isButtonMuted,
                      toggleMute: audioManager.toggleButtonMute,
                      volume: audioManager.buttonVolume,
                      onVolumeChanged: audioManager.setButtonVolume,
                      icon: Icons.touch_app,
                      color: Colors.green,
                    ),
                    buildVolumeControl(
                      title: "Alerts & Notifications",
                      expanded: alertExpanded,
                      onExpandChanged: (v) => setState(() => alertExpanded = v),
                      isMuted: audioManager.isAlertMuted,
                      toggleMute: audioManager.toggleAlertMute,
                      volume: audioManager.alertVolume,
                      onVolumeChanged: audioManager.setAlertVolume,
                      icon: Icons.notifications,
                      color: Colors.purple,
                    ),

                    const SizedBox(height: 16),

                    // GOOGLE ACCOUNT SECTION
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Google Account",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            if (user != null &&
                                user.providerData.any(
                                        (p) => p.providerId == GoogleAuthProvider.PROVIDER_ID))
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Connected: ${user.email ?? "Google Account"}",
                                          style: const TextStyle(color: Colors.green),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.logout),
                                    label: const Text("Disconnect"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title:
                                          const Text("Disconnect Google Account"),
                                          content: const Text(
                                              "Are you sure you want to disconnect your Google account? You will be switched to anonymous mode."),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red),
                                              child: const Text("Disconnect"),
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
                                  const Text("Not connected yet",
                                      style: TextStyle(color: Colors.orange)),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    icon: _isConnecting
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Icon(Icons.login),
                                    label: Text(
                                      _isConnecting
                                          ? "Connecting..."
                                          : "Connect Google Account",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed:
                                    _isConnecting ? null : _signInWithGoogle,
                                  ),
                                  if (_googleError != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _googleError!,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 14),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reset Audio Settings"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () => audioManager.resetAudioSettings(),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }),
                    const SizedBox(height: 12),

                    Text("Version $appVersion"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
