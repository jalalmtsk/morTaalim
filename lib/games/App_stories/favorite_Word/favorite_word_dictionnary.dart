import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteWordsManager {
  static const String _key = 'favorite_words';

  static Future<void> addWord(String word, String definition) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    // Deserialize current favorites
    final favorites = rawList.map((e) => FavoriteWord.fromJson(json.decode(e))).toList();

    // Check if already added
    final exists = favorites.any((f) => f.word == word);
    if (!exists) {
      favorites.add(FavoriteWord(word: word, definition: definition));
      // Serialize back
      final encodedList = favorites.map((f) => json.encode(f.toJson())).toList();
      await prefs.setStringList(_key, encodedList);
    }
  }

  static Future<void> removeWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    final favorites = rawList.map((e) => FavoriteWord.fromJson(json.decode(e))).toList();

    favorites.removeWhere((f) => f.word == word);

    final encodedList = favorites.map((f) => json.encode(f.toJson())).toList();
    await prefs.setStringList(_key, encodedList);
  }

  static Future<List<FavoriteWord>> getWords() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    return rawList.map((e) => FavoriteWord.fromJson(json.decode(e))).toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}


class FavoriteWord {
  final String word;
  final String definition;

  FavoriteWord({required this.word, required this.definition});

  Map<String, dynamic> toJson() => {
    'word': word,
    'definition': definition,
  };

  factory FavoriteWord.fromJson(Map<String, dynamic> json) {
    return FavoriteWord(
      word: json['word'],
      definition: json['definition'],
    );
  }
}

