import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../XpSystem.dart';
import '../main.dart'; // Your ExperienceManager provider




String appVersion = "1.0.0";

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});


  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content vertically
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),

            // Music on/off row
            Row(
              children: [
                Icon(
                 Icons.music_note,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 10),
                const Text('Music'),
                const Spacer(),

              ],
            ),

            const SizedBox(height: 20),

            // Volume control slider
            Row(
              children: [
                const Icon(Icons.volume_down, color: Colors.deepOrange),

                const Icon(Icons.volume_up, color: Colors.deepOrange),
              ],
            ),


            ListTile(
              title: Text(tr(context).progressReports),
              leading: const Icon(Icons.insert_chart),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // TODO: connect this to your reports page or functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr(context).progressReportsComingSoon)),
                );
              },
            ),




const Divider(height: 20,),
            SwitchListTile(
              title: const Text('Enable Ads'),
              value: context.watch<ExperienceManager>().adsEnabled,
              onChanged: (value) {
                context.read<ExperienceManager>().setAdsEnabled(value);
              },
            ),

            ListTile(
              title: Text(tr(context).rateApp),
              leading: const Icon(Icons.star_rate, color: Colors.amber),
            ),

            ListTile(
              title: Text(tr(context).aboutApp),
              subtitle: Text(appVersion),
              leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
            ),

            const Divider(height: 32),

            // Exit button
            ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Exit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
              },
            ),
          ],
        ),
      ),
    );
  }
}
