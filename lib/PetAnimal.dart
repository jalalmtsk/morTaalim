import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class VirtualPetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Pet',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PetHomePage(),
    );
  }
}

class PetHomePage extends StatefulWidget {
  @override
  _PetHomePageState createState() => _PetHomePageState();
}

class _PetHomePageState extends State<PetHomePage> {
  int _level = 1;
  double _hunger = 0.0; // 0 = empty, 1 = full
  List<String> _badges = [];

  static const double feedAmount = 0.25; // each feed adds 25% hunger

  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadPetState();
  }

  Future<void> _loadPetState() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _level = prefs.getInt('level') ?? 1;
      _hunger = prefs.getDouble('hunger') ?? 0.0;
      _badges = prefs.getStringList('badges') ?? [];
    });
  }

  Future<void> _savePetState() async {
    await prefs.setInt('level', _level);
    await prefs.setDouble('hunger', _hunger);
    await prefs.setStringList('badges', _badges);
  }

  void _feedPet() {
    setState(() {
      _hunger += feedAmount;
      if (_hunger >= 1.0) {
        _hunger = 1.0;
        _levelUp();
      }
    });
    _savePetState();
  }

  void _levelUp() {
    _level++;
    _hunger = 0.0;

    // Give badge reward every 2 levels
    if (_level % 2 == 0) {
      _badges.add("Level $_level Achieved!");
    }
  }

  String get petImage {
    // Return different asset name or url depending on level
    if (_level < 3) return 'assets/pet_stage1.png';
    if (_level < 5) return 'assets/pet_stage2.png';
    return 'assets/pet_stage3.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Pet Companion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Pet Level: $_level', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),

            // Pet image placeholder (replace with actual pet images in assets)
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.lightGreen[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: Center(
                child: Text(
                  'Pet Image\nStage $_level',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, color: Colors.green[900]),
                ),
              ),
              // Use this if you have images in assets:
              // child: Image.asset(petImage, fit: BoxFit.contain),
            ),

            SizedBox(height: 30),

            LinearProgressIndicator(
              value: _hunger,
              minHeight: 20,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
            SizedBox(height: 10),
            Text('Hunger: ${(_hunger * 100).toInt()}%'),

            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _hunger < 1.0 ? _feedPet : null,
              icon: Icon(Icons.restaurant),
              label: Text('Feed Pet'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),

            SizedBox(height: 40),
            Text('Badges Earned:', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Expanded(
              child: _badges.isEmpty
                  ? Text('No badges yet. Feed your pet to earn badges!')
                  : ListView.builder(
                itemCount: _badges.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.emoji_events, color: Colors.amber),
                    title: Text(_badges[index]),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
