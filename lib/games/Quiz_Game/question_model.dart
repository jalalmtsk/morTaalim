import 'dart:math';

class Question {
  final String questionText;
  final List<String> options;
  final int correctIndex;

  Question(this.questionText, this.options, this.correctIndex);

  /// Returns a new Question instance with shuffled options and updated correctIndex
  Question shuffled() {
    final rnd = Random();
    List<String> shuffledOptions = List.from(options);
    shuffledOptions.shuffle(rnd);

    // Find the new index of the original correct answer after shuffle
    final newCorrectIndex = shuffledOptions.indexOf(options[correctIndex]);

    return Question(questionText, shuffledOptions, newCorrectIndex);
  }
}
