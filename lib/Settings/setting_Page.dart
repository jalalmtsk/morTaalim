import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../XpSystem.dart';
import '../tools/audio_tool/Audio_Manager.dart';

class SettingsPage extends StatefulWidget {
  final void Function(Locale) onChangeLocale;

  const SettingsPage({super.key, required this.onChangeLocale});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false;
  bool notificationsOn = true;
  String username = "Player";
  String appVersion = "Loading...";
  bool parentalLockEnabled = false;
  String parentalPin = '';
  int screenTimeLimitMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
      notificationsOn = prefs.getBool('notificationsOn') ?? true;
      username = prefs.getString('username') ?? 'Player';
      parentalLockEnabled = prefs.getBool('parentalLockEnabled') ?? false;
      parentalPin = prefs.getString('parentalPin') ?? '';
      screenTimeLimitMinutes = prefs.getInt('screenTimeLimitMinutes') ?? 0;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "${info.version} (build ${info.buildNumber})";
    });
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to open link.")),
      );
    }
  }

  Future<void> _setParentalPin() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: parentalPin);
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.setParentalPin),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: AppLocalizations.of(context)!.enterPin),
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          actions: [
            TextButton(child: Text(AppLocalizations.of(context)!.cancel), onPressed: () => Navigator.pop(context)),
            TextButton(child: Text(AppLocalizations.of(context)!.save), onPressed: () => Navigator.pop(context, controller.text)),
          ],
        );
      },
    );
    if (pin != null && pin.isNotEmpty) {
      setState(() {
        parentalPin = pin;
        parentalLockEnabled = true;
      });
      await _savePref('parentalPin', pin);
      await _savePref('parentalLockEnabled', true);
    }
  }

  Future<void> _setScreenTimeLimit() async {
    final input = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
            text: screenTimeLimitMinutes == 0 ? '' : screenTimeLimitMinutes.toString());
        return AlertDialog(
          title: Text("Set Screen Limit"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Enter Minutes"),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(child: Text(AppLocalizations.of(context)!.cancel), onPressed: () => Navigator.pop(context)),
            TextButton(child: Text(AppLocalizations.of(context)!.save), onPressed: () => Navigator.pop(context, controller.text)),
          ],
        );
      },
    );

    if (input != null) {
      final minutes = int.tryParse(input) ?? 0;
      setState(() => screenTimeLimitMinutes = minutes);
      await _savePref('screenTimeLimitMinutes', minutes);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.settings),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _buildSectionTitle('general'),

          SwitchListTile(
            title: Text(tr.darkMode),
            value: darkMode,
            onChanged: (val) {
              setState(() => darkMode = val);
              _savePref('darkMode', val);
            },
          ),

          SwitchListTile(
            title: Text(tr.notifications),
            value: notificationsOn,
            onChanged: (val) {
              setState(() => notificationsOn = val);
              _savePref('notificationsOn', val);
            },
          ),

          ListTile(
            title: Text(tr.language),
            trailing: DropdownButton<Locale>(
              value: Localizations.localeOf(context),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) widget.onChangeLocale(newLocale);
              },
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                DropdownMenuItem(value: Locale('it'), child: Text('Italiano')),
              ],
            ),
          ),

          ListTile(
            title: Text('${tr.username}: $username'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController(text: username);
                    return AlertDialog(
                      title: Text(tr.changeName),
                      content: TextField(
                        controller: controller,
                        decoration: InputDecoration(hintText: tr.enterNewName),
                      ),
                      actions: [
                        TextButton(child: Text(tr.cancel), onPressed: () => Navigator.pop(context)),
                        TextButton(child: Text(tr.save), onPressed: () => Navigator.pop(context, controller.text)),
                      ],
                    );
                  },
                );
                if (name != null) {
                  setState(() => username = name);
                  _savePref('username', name);
                }
              },
            ),
          ),

          _buildSectionTitle("Audio"),

          ListTile(
            leading: const Icon(Icons.music_note, color: Colors.deepOrange),
            title: const Text("Background Music"),
            subtitle: Slider(
              value: audioManager.bgVolume,
              onChanged: (v) {
                audioManager.setBgVolume(v);
                _savePref('musicVolume', v);
              },
              min: 0,
              max: 1,
            ),
            trailing: IconButton(
              icon: Icon(audioManager.isBgMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: audioManager.toggleBgMute,
            ),
          ),

          ListTile(
            leading: const Icon(Icons.speaker, color: Colors.blue),
            title: const Text("SFX"),
            subtitle: Slider(
              value: audioManager.sfxVolume,
              onChanged: (v) => audioManager.setSfxVolume(v),
              min: 0,
              max: 1,
            ),
            trailing: IconButton(
              icon: Icon(audioManager.isSfxMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: audioManager.toggleSfxMute,
            ),
          ),

          _buildSectionTitle("Security & Parental Controls"),

          SwitchListTile(
            title: Text(tr.parentalLock),
            subtitle: parentalLockEnabled
                ? Text(tr.parentalLockEnabled)
                : Text(tr.parentalLockDisabled),
            value: parentalLockEnabled,
            onChanged: (val) async {
              if (val) {
                await _setParentalPin();
              } else {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: Text(tr.enterPinToDisable),
                      content: TextField(
                        controller: controller,
                        decoration: InputDecoration(hintText: tr.enterPin),
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      actions: [
                        TextButton(child: Text(tr.cancel), onPressed: () => Navigator.pop(context, false)),
                        TextButton(
                          child: Text(tr.confirm),
                          onPressed: () {
                            if (controller.text == parentalPin) {
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr.incorrectPin)),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
                if (confirmed == true) {
                  setState(() {
                    parentalLockEnabled = false;
                    parentalPin = '';
                  });
                  _savePref('parentalLockEnabled', false);
                  _savePref('parentalPin', '');
                }
              }
            },
          ),

          ListTile(
            title: Text(tr.screenTimeLimit),
            subtitle: screenTimeLimitMinutes == 0
                ? Text(tr.noLimit)
                : Text('$screenTimeLimitMinutes ${tr.minutes}'),
            trailing: TextButton(
              child: Text(tr.set),
              onPressed: _setScreenTimeLimit,
            ),
          ),

          _buildSectionTitle("About & Support"),

          ListTile(
            title: Text(tr.aboutApp),
            subtitle: Text(appVersion),
            leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
          ),
          ListTile(
            title: Text(tr.contactSupport),
            leading: const Icon(Icons.email, color: Colors.deepPurple),
            onTap: () => _launchURL("mailto:support@example.com"),
          ),
          ListTile(
            title: Text(tr.privacyPolicy),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () => _launchURL("https://example.com/privacy"),
          ),
          ListTile(
            title: Text(tr.termsOfUse),
            leading: const Icon(Icons.gavel),
            onTap: () => _launchURL("https://example.com/terms"),
          ),
          ListTile(
            title: Text(tr.rateApp),
            leading: const Icon(Icons.star_rate, color: Colors.amber),
            onTap: () => _launchURL("https://play.google.com/store/apps/details?id=com.example.mortaalim"),
          ),
        ],
      ),
    );
  }
}
