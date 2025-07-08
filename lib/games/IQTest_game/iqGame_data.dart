import 'package:flutter/material.dart';

import 'Section_Selector.dart';

void main() {
  runApp(const IQTestApp());
}

class IQTestApp extends StatelessWidget {
  const IQTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IQ Test Game',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: const SectionSelector(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Models and Data ---

class Section {
  final String title;
  final List<Question> questions;
  final IconData icon;

  Section({required this.title, required this.questions, required this.icon});
}

class Question {
  final String question;
  final List<String> options;
  final String answer;
  final String hint;

  Question(
      {required this.question,
        required this.options,
        required this.answer,
        required this.hint});
}

final List<Section> sections = [
  Section(
    title: 'Pattern Recognition',
    icon: Icons.pattern,
    questions: [
      Question(
        question: 'What comes next? 2, 4, 8, 16, ?',
        options: ['18', '24', '32', '20'],
        answer: '32',
        hint: 'Multiply by 2 each time',
      ),
      Question(
        question: 'Find the next number: 1, 1, 2, 3, 5, ?',
        options: ['8', '7', '6', '10'],
        answer: '8',
        hint: 'Fibonacci sequence',
      ),
      Question(
        question: 'Odd one out: Circle, Triangle, Square, Apple',
        options: ['Circle', 'Apple', 'Triangle', 'Square'],
        answer: 'Apple',
        hint: 'Only one is not a shape',
      ),
      Question(
        question: 'Which is the odd one? 3, 5, 7, 9, 11',
        options: ['3', '5', '7', '9'],
        answer: '9',
        hint: 'Only one is not a prime number',
      ),
      Question(
        question: 'Choose the odd word: Blue, Red, Yellow, Circle',
        options: ['Blue', 'Red', 'Circle', 'Yellow'],
        answer: 'Circle',
        hint: 'One is not a color',
      ),
    ],
  ),
  Section(
    title: 'Math Reasoning',
    icon: Icons.calculate,
    questions: [
      Question(
        question: 'What is 5 + 3 × 2?',
        options: ['16', '11', '13', '10'],
        answer: '11',
        hint: 'BODMAS rule',
      ),
      Question(
        question: 'Which number is divisible by 3?\n9, 11, 14, 17',
        options: ['9', '11', '14', '17'],
        answer: '9',
        hint: 'Divisibility by 3',
      ),
      Question(
        question: 'Solve: (12 - 4) ÷ 2 + 6 = ?',
        options: ['10', '8', '9', '12'],
        answer: '10',
        hint: 'Do brackets first',
      ),
      Question(
        question: 'What is the square root of 81?',
        options: ['7', '8', '9', '10'],
        answer: '9',
        hint: '9 × 9 = 81',
      ),
      Question(
        question: 'Which number is smallest?\n-2, -10, -5, 0',
        options: ['-2', '-10', '-5', '0'],
        answer: '-10',
        hint: 'Negative numbers are less than positive',
      ),
    ],
  ),
];