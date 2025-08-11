import 'package:shared_preferences/shared_preferences.dart';

class YoutubeProgressManager {
  static const _kCompletedVideosKey = 'youtube_completed_videos';

  Set<String> _completedVideoIds = {};

  // Constructor
  YoutubeProgressManager({
    Set<String>? completedVideoIds,
  }) : _completedVideoIds = completedVideoIds ?? {};

  // Getters
  Set<String> get completedVideoIds => _completedVideoIds;

  // Returns the count of completed videos as an integer
  int get totalVideosCompleted => _completedVideoIds.length;

  // Setter (replace entire set)
  set completedVideoIds(Set<String> ids) => _completedVideoIds = ids;

  // Check if a video is completed
  bool isVideoCompleted(String videoId) => _completedVideoIds.contains(videoId);

  // Load from SharedPreferences
  static Future<YoutubeProgressManager> fromPrefs(SharedPreferences prefs) async {
    final completedList = prefs.getStringList(_kCompletedVideosKey) ?? [];
    return YoutubeProgressManager(completedVideoIds: completedList.toSet());
  }

  // Save to SharedPreferences
  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setStringList(_kCompletedVideosKey, _completedVideoIds.toList());
  }

  // Clear progress
  Future<void> clearPrefs(SharedPreferences prefs) async {
    await prefs.remove(_kCompletedVideosKey);
    _completedVideoIds.clear();
  }

  // Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'youtubeCompletedVideos': _completedVideoIds.toList(),
      'youtubeCompletedVideosCount': _completedVideoIds.length,
    };
  }

  // Load from Map (e.g. Firebase or API)
  void loadFromMap(Map<String, dynamic> map) {
    final completed = map['youtubeCompletedVideos'];
    if (completed is List) {
      _completedVideoIds = completed.map((e) => e.toString()).toSet();
    }
  }
}
