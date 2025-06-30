import 'package:flutter/material.dart';
import 'package:mortaalim/games/Tracing_Alphabet_app/TracingAlphabetPage.dart';

class LanguageSelectorPage extends StatelessWidget {
  const LanguageSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.of(context).pushNamed("Index");
        }, icon: Icon(Icons.arrow_back)),
        title: const Text('Choose Language / اختر اللغة'),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlphabetTracingPage(language: 'french'),
                  ),
                );
              },
              child: const Text('French Letters (A, B, C...)'),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlphabetTracingPage(language: 'arabic',),
                  ),
                );
              },
              child: const Text('حروف عربية'),
            ),
          ],
        ),
      ),
    );
  }
}
