import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgeCheckPage extends StatefulWidget {
  final VoidCallback? onNext;

  const AgeCheckPage({Key? key, this.onNext}) : super(key: key);

  @override
  State<AgeCheckPage> createState() => _AgeCheckPageState();
}

class _AgeCheckPageState extends State<AgeCheckPage> {
  int selectedAge = 20; // default age
  final List<int> ages = List.generate(80, (index) => index + 3); // 3–80

  Future<void> saveAge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("age", selectedAge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                width: 250,
                'assets/animations/FirstTouchAnimations/Thinking.json',
                repeat: false
              ),

               Text(
                tr(context).pleaseEnterYourAge,
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                height: 180,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CupertinoPicker(
                  backgroundColor: Colors.transparent,
                  itemExtent: 50,
                  scrollController: FixedExtentScrollController(initialItem: 17),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedAge = ages[index];
                    });
                  },
                  children: ages
                      .map((age) => Center(
                    child: Text(
                      age.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepOrange,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                onPressed: () async {
                  await saveAge();
                  widget.onNext?.call();
                },
                child:  Text(
                  tr(context).confirm,
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                " ${tr(context).age}: $selectedAge",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              )
            ],
          ),
        ),
      ),
    );
  }
}
