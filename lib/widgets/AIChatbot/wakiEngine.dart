import 'BrainTools/Memory_Correction.dart';
import 'WakiBrain/creative.dart';
import 'WakiBrain/dailyLife.dart';
import 'WakiBrain/emotions.dart';
import 'WakiBrain/fun.dart';
import 'WakiBrain/generalKnowledge.dart';
import 'WakiBrain/greetings.dart';
import 'WakiBrain/learning.dart';
import 'WakiBrain/randomBonus.dart';

class WakiBrain {
  static final List<Map<String, String>> allKnowledgeBases = [
    greetings,
    learning,
    emotions,
    fun,
    creative,
    dailyLife,
    generalKnowledge,
    randomBonus,
  ];

  static String? _lastQuestion;
  static String? get lastQuestion => _lastQuestion;

  // Levenshtein distance
  static int levenshteinDistance(String s, String t) {
    final m = s.length;
    final n = t.length;
    List<List<int>> d = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) d[i][0] = i;
    for (int j = 0; j <= n; j++) d[0][j] = j;

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,        // deletion
          d[i][j - 1] + 1,        // insertion
          d[i - 1][j - 1] + cost  // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return d[m][n];
  }

  static String getReply(String input, {String? userName}) {
    input = input.toLowerCase().trim();

    // Avoid repeating the same question
    if (_lastQuestion != null && _lastQuestion == input) {
      return "Tu m'as déjà demandé ça ! Essaie de poser autre chose 😊";
    }
    _lastQuestion = input;

    // Check memory for correction
    final memory = CorrectionsMemory();
    final correction = memory.getCorrection(input);
    if (correction != null) {
      return _personalize(correction, userName);
    }

    final words = input.split(RegExp(r'\s+'));
    List<String> substrings = [];
    for (int start = 0; start < words.length; start++) {
      for (int end = start + 1; end <= words.length; end++) {
        substrings.add(words.sublist(start, end).join(' '));
      }
    }

    String? bestKey;
    String? bestAnswer;
    int bestScore = 1000;

    // 1. Exact and contains match
    for (final category in allKnowledgeBases) {
      for (final key in category.keys) {
        if (input.contains(key)) {
          var answer = category[key]!;
          return _personalize(answer, userName);
        }
      }
    }

    // 2. Fuzzy matching
    for (final category in allKnowledgeBases) {
      for (final key in category.keys) {
        for (final chunk in substrings) {
          int dist = levenshteinDistance(chunk, key);
          if (dist < bestScore && dist <= 4) {
            bestKey = key;
            bestAnswer = category[key];
            bestScore = dist;
          }
        }
      }
    }

    if (bestAnswer != null) {
      return _personalize(bestAnswer, userName);
    }

    return "Je ne suis pas sûr de comprendre... Essaie une autre question, ou parle-moi d'apprentissage, d'émotions, ou demande-moi une blague ! 😄";
  }

  static String _personalize(String answer, String? userName) {
    if (userName != null && answer.contains("{user}")) {
      return answer.replaceAll("{user}", userName);
    }
    return answer;
  }

  static void learnCorrection(String question, String correctedAnswer) {
    final memory = CorrectionsMemory();
    memory.addCorrection(question, correctedAnswer);
  }
}
