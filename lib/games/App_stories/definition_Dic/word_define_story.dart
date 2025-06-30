Map<String, String> getAllDefinitions() {
  return {
    'Flick': 'A funny fox who loves dancing.',
    'rain': 'Water falling from the sky.',
    'bunny': 'A small, fluffy rabbit.',
    'forest': 'A large area covered with trees and animals.',
    'time' : "To Dance Baby"

    // Add more...
  };
}

String getDefinitionFor(String word) {
  return getAllDefinitions()[word] ?? 'No definition found.';
}
