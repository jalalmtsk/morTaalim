// word_definitions.dart

final Map<String, String> _definitions = {
  'Flick': 'A funny fox who loves dancing.',
  'rain': 'Water falling from the sky.',
  'bunny': 'A small, fluffy rabbit.',
  'forest': 'A large area covered with trees and plants.',
  'danced': 'To move rhythmically to music.',
  'mud': 'Wet, soft earth.',
  'twirl': 'A quick spinning movement.',
  'hop': 'To jump lightly on one foot.',
  'time' : "To Dance Baby"
  // Add more definitions as needed
};

String getDefinitionFor(String word) {
  return _definitions[word.replaceAll(RegExp(r'[^\w\s]'), '')] ?? 'No definition found.';
}
