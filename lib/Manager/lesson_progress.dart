import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which lessons a child has opened in each subject, the last
/// subject they worked on, and a daily goal (open one lesson today → reward,
/// once a day). Each section (courses, IT, …) has its own [scope].
class LessonTracker {
  final String scope;
  const LessonTracker(this.scope);

  static const int goalReward = 20;

  String get _p => scope.isEmpty ? '' : '${scope}_';
  String get _kLast => '${_p}lesson_last_subject';
  String get _kToday => '${_p}lesson_goal_day';
  String get _kClaimed => '${_p}lesson_goal_claimed_day';
  String _kDone(String subject) => '${_p}lessons_done_$subject';

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// Call when a lesson/exercise of [subject] is opened.
  Future<void> record(String subject, int lessonIndex) async {
    final p = await SharedPreferences.getInstance();
    final done = (p.getStringList(_kDone(subject)) ?? const []).toSet()..add('$lessonIndex');
    await p.setStringList(_kDone(subject), done.toList());
    await p.setString(_kLast, subject);
    await p.setString(_kToday, _today());
    await ActivityLog.markToday();
  }

  /// Indexes of the lessons opened in [subject].
  Future<Set<int>> doneIn(String subject) async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kDone(subject)) ?? const []).map(int.tryParse).whereType<int>().toSet();
  }

  Future<LessonSnapshot> load(Iterable<String> subjects) async {
    final p = await SharedPreferences.getInstance();
    return LessonSnapshot(
      done: {for (final s in subjects) s: (p.getStringList(_kDone(s)) ?? const []).length},
      lastSubject: p.getString(_kLast),
      learnedToday: p.getString(_kToday) == _today(),
      claimedToday: p.getString(_kClaimed) == _today(),
    );
  }

  /// Marks today's goal as rewarded. Returns false if it already was.
  Future<bool> claimToday() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_kClaimed) == _today()) return false;
    await p.setString(_kClaimed, _today());
    return true;
  }
}

/// School courses (Math, French, …).
class LessonProgress {
  LessonProgress._();
  static const LessonTracker courses = LessonTracker('');
  static const LessonTracker it = LessonTracker('it');
  static const int goalReward = LessonTracker.goalReward;

  static Future<void> record(String subject, int lessonIndex) => courses.record(subject, lessonIndex);
  static Future<LessonSnapshot> load(Iterable<String> subjects) => courses.load(subjects);
  static Future<bool> claimToday() => courses.claimToday();
}

/// Days on which the child learned or played (for the learning streak).
class ActivityLog {
  ActivityLog._();
  static const _kDays = 'activity_days';

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static Future<void> markToday() async {
    final p = await SharedPreferences.getInstance();
    final days = (p.getStringList(_kDays) ?? const []).toList();
    final today = _key(DateTime.now());
    if (days.contains(today)) return;
    days.add(today);
    if (days.length > 120) days.removeRange(0, days.length - 120);
    await p.setStringList(_kDays, days);
  }

  /// Consecutive active days ending today (or yesterday, so the streak
  /// doesn't look broken before the child has played today).
  static Future<int> streak() async {
    final p = await SharedPreferences.getInstance();
    final days = (p.getStringList(_kDays) ?? const []).toSet();
    var d = DateTime.now();
    if (!days.contains(_key(d))) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(_key(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }
}

class LessonSnapshot {
  final Map<String, int> done;
  final String? lastSubject;
  final bool learnedToday, claimedToday;
  const LessonSnapshot({required this.done, this.lastSubject, required this.learnedToday, required this.claimedToday});
  static const empty = LessonSnapshot(done: {}, learnedToday: false, claimedToday: false);
}
