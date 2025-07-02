import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicCredit {
  final String title;
  final String artist;
  final String license;
  final String licenseUrl;

  MusicCredit({
    required this.title,
    required this.artist,
    required this.license,
    required this.licenseUrl,
  });
}

class CreditsPage extends StatelessWidget {
  CreditsPage({super.key});

  final List<MusicCredit> credits = [
    MusicCredit(
      title: 'Happy Happy Game Show',
      artist: 'Kevin MacLeod (incompetech.com)',
      license: 'Licensed under Creative Commons: By Attribution 4.0 License',
      licenseUrl: 'http://creativecommons.org/licenses/by/4.0/',
    ),
    MusicCredit(
      title: 'Happy Boy Theme',
      artist: 'Kevin MacLeod (incompetech.com)',
      license: 'Licensed under Creative Commons: By Attribution 4.0 License',
      licenseUrl: 'http://creativecommons.org/licenses/by/4.0/',
    ),
    MusicCredit(
      title: 'Happy Bee - Surf',
      artist: 'Kevin MacLeod (incompetech.com)',
      license: 'Licensed under Creative Commons: By Attribution 4.0 License',
      licenseUrl: 'http://creativecommons.org/licenses/by/4.0/',
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back)),
        title: const Text('Credits'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Music Credits',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: credits.length,
                itemBuilder: (context, index) {
                  final credit = credits[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          '"${credit.title}" by ${credit.artist}',
                          style: const TextStyle(fontSize: 18),
                        ),
                          subtitle: Text(
                            credit.license,
                            style: const TextStyle(fontSize: 16),
                          ),

                      ),
                    ),
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
