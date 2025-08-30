import 'package:flutter/material.dart';
import 'package:mortaalim/TestingBeforeProdcution/Hezz2FinalGame/Screen/GameScreen.dart';
import 'package:mortaalim/TestingBeforeProdcution/Hezz2FinalGame/Models/GameCardEnums.dart';


class CardGameLauncher extends StatefulWidget {
  const CardGameLauncher({super.key});
  @override
  State<CardGameLauncher> createState() => _GameLauncherState();
}

class _GameLauncherState extends State<CardGameLauncher> {
  GameMode mode = GameMode.local;
  GameModeType gameMode = GameModeType.playToWin;
  int handSize = 7;
  int botCount = 2;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Bright Cards',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Match suit or rank. Special cards: 2 (draw2+skip), 1 (skip), 7 (change suit).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 28),

                _buildSettingRow(
                  title: 'Starting Hand Size',
                  child: DropdownButton<int>(
                    value: handSize,
                    items: List.generate(11, (i) => i + 1)
                        .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                        .toList(),
                    onChanged: (v) => setState(() => handSize = v ?? 7),
                  ),
                ),

                _buildSettingRow(
                  title: 'Number of Bots',
                  child: DropdownButton<int>(
                    value: botCount,
                    items: [1, 2, 3, 4]
                        .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                        .toList(),
                    onChanged: (v) => setState(() => botCount = v ?? 2),
                  ),
                ),

                _buildSettingRow(
                  title: 'Connection Mode',
                  child: DropdownButton<GameMode>(
                    value: mode,
                    items: const [
                      DropdownMenuItem(value: GameMode.local, child: Text('Local')),
                      DropdownMenuItem(value: GameMode.online, child: Text('Online')),
                    ],
                    onChanged: (v) => setState(() => mode = v ?? GameMode.local),
                  ),
                ),

                _buildSettingRow(
                  title: 'Game Mode',
                  child: DropdownButton<GameModeType>(
                    value: gameMode,
                    items: const [
                      DropdownMenuItem(value: GameModeType.playToWin, child: Text('Play To Win')),
                      DropdownMenuItem(value: GameModeType.elimination, child: Text('Elimination')),
                    ],
                    onChanged: (v) => setState(() => gameMode = v ?? GameModeType.playToWin),
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            startHandSize: handSize,
                            botCount: botCount,
                            mode: mode,
                            gameModeType: gameMode,
                          ),
                        ),
                      );
                    },
                    child: const Text('Start Game', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          child,
        ],
      ),
    );
  }
}
