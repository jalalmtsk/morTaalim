import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AS_MatchDrop extends StatefulWidget {
  @override
  _AS_MatchDropState createState() => _AS_MatchDropState();
}

class _AS_MatchDropState extends State<AS_MatchDrop> {
  final AudioPlayer audioPlayer = AudioPlayer();

  final List<Map<String, String>> animals = [
    {'name': 'Dog', 'sound': 'sounds/dog.mp3', 'image': 'images/dog.png'},
    {'name': 'Cat', 'sound': 'sounds/cat.mp3', 'image': 'images/cat.png'},
    {'name': 'Lion', 'sound': 'sounds/lion.mp3', 'image': 'images/lion.png'},
  ];

  String feedback = 'Drag the animal to its sound!';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exercise Mode 2')),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text(feedback, style: TextStyle(fontSize: 20)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: animals.map((animal) {
              return Draggable<Map<String, String>>(
                data: animal,
                feedback: Image.asset(animal['image']!, width: 80),
                child: Image.asset(animal['image']!, width: 80),
              );
            }).toList(),
          ),
          SizedBox(height: 50),
          Wrap(
            spacing: 20,
            children: animals.map((animal) {
              return DragTarget<Map<String, String>>(
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.green[100],
                    child: Center(child: Text('Play Sound')),
                  );
                },
                onWillAccept: (data) => data!['name'] == animal['name'],
                onAccept: (data) {
                  setState(() {
                    feedback = 'Correct! ${data['name']}';
                  });
                  audioPlayer.play();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
