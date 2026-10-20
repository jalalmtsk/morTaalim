import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything the Parents Space stores (all local, SharedPreferences).
class ParentSettings {
  ParentSettings._();
  static final ParentSettings I = ParentSettings._();

  // Screen time
  bool limitOn = false;
  int limitMin = 30;
  bool quietOn = false;
  List<QuietRange> quiet = [
    QuietRange('night', 20 * 60 + 30, 7 * 60, {1, 2, 3, 4, 5, 6, 7}),
    QuietRange('school', 8 * 60 + 30, 16 * 60 + 30, {1, 2, 3, 4, 5}),
  ];
  bool breakOn = false;
  int breakMin = 30;
  int bonusDate = 0; // yyyymmdd of the day bonus minutes apply
  int bonusMin = 0;

  // Content
  Map<String, bool> sections = {'games': true, 'stories': true, 'religion': true, 'creativity': true, 'ai': false};
  Set<String> focus = {'math', 'french', 'arabic', 'islamicEducation'};
  String learnLang = 'ar';

  bool _loaded = false;

  bool allows(String section) => sections[section] ?? true;

  Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    limitOn = p.getBool('ps_limit_on') ?? false;
    limitMin = p.getInt('ps_limit_min') ?? 30;
    quietOn = p.getBool('ps_quiet_on') ?? false;
    final q = p.getString('ps_quiet');
    if (q != null) {
      try {
        quiet = (jsonDecode(q) as List).map((e) => QuietRange.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    breakOn = p.getBool('ps_break_on') ?? false;
    breakMin = p.getInt('ps_break_min') ?? 30;
    bonusDate = p.getInt('ps_bonus_date') ?? 0;
    bonusMin = p.getInt('ps_bonus_min') ?? 0;
    final s = p.getString('ps_sections');
    if (s != null) {
      try {
        sections = {...sections, ...(jsonDecode(s) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as bool))};
      } catch (_) {}
    }
    focus = (p.getStringList('ps_focus') ?? focus.toList()).toSet();
    learnLang = p.getString('ps_learn_lang') ?? learnLang;
    _loaded = true;
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ps_limit_on', limitOn);
    await p.setInt('ps_limit_min', limitMin);
    await p.setBool('ps_quiet_on', quietOn);
    await p.setString('ps_quiet', jsonEncode(quiet.map((e) => e.toJson()).toList()));
    await p.setBool('ps_break_on', breakOn);
    await p.setInt('ps_break_min', breakMin);
    await p.setInt('ps_bonus_date', bonusDate);
    await p.setInt('ps_bonus_min', bonusMin);
    await p.setString('ps_sections', jsonEncode(sections));
    await p.setStringList('ps_focus', focus.toList());
    await p.setString('ps_learn_lang', learnLang);
  }

  /// Minutes allowed today (limit + any bonus granted today).
  int get allowedToday => limitMin + (bonusDate == Usage.dayKey(DateTime.now()) ? bonusMin : 0);

  QuietRange? activeQuiet(DateTime now) {
    if (!quietOn) return null;
    final m = now.hour * 60 + now.minute;
    for (final r in quiet) {
      if (r.contains(now, m)) return r;
    }
    return null;
  }
}

class QuietRange {
  String name; // 'night', 'school' or custom
  int start, end; // minutes after midnight
  Set<int> days; // 1 = Monday … 7 = Sunday (day the range starts)
  QuietRange(this.name, this.start, this.end, this.days);

  bool contains(DateTime now, int m) {
    if (start <= end) return days.contains(now.weekday) && m >= start && m < end;
    // overnight range (e.g. 20:30 → 07:00)
    if (m >= start) return days.contains(now.weekday);
    final yesterday = now.weekday == 1 ? 7 : now.weekday - 1;
    return m < end && days.contains(yesterday);
  }

  Map<String, dynamic> toJson() => {'n': name, 's': start, 'e': end, 'd': days.toList()};
  factory QuietRange.fromJson(Map<String, dynamic> j) =>
      QuietRange(j['n'] as String, j['s'] as int, j['e'] as int, (j['d'] as List).map((e) => e as int).toSet());

  static String hm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

/// Seconds the app was used, per day.
class Usage {
  Usage._();
  static int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
  static String _k(DateTime d) => 'usage_${dayKey(d)}';

  static Future<void> add(int seconds) async {
    final p = await SharedPreferences.getInstance();
    final k = _k(DateTime.now());
    await p.setInt(k, (p.getInt(k) ?? 0) + seconds);
  }

  static Future<int> secondsOn(DateTime d) async => (await SharedPreferences.getInstance()).getInt(_k(d)) ?? 0;

  /// Monday → Sunday of the week containing [d], in seconds.
  static Future<List<int>> week(DateTime d) async {
    final p = await SharedPreferences.getInstance();
    final monday = DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
    return [for (var i = 0; i < 7; i++) p.getInt(_k(monday.add(Duration(days: i)))) ?? 0];
  }
}

/// Recent activity log (lessons, games, drawings, badges, verses…).
class FeedItem {
  final String type; // lesson | game | drawing | badge | listen
  final String ref; // subject / game title / badge id
  final DateTime at;
  const FeedItem(this.type, this.ref, this.at);
  Map<String, dynamic> toJson() => {'t': type, 'r': ref, 'a': at.millisecondsSinceEpoch};
  factory FeedItem.fromJson(Map<String, dynamic> j) =>
      FeedItem(j['t'] as String, j['r'] as String, DateTime.fromMillisecondsSinceEpoch(j['a'] as int));
}

class ActivityFeed {
  ActivityFeed._();
  static const _k = 'activity_feed';

  static Future<void> add(String type, String ref) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList(_k) ?? <String>[];
      list.add(jsonEncode(FeedItem(type, ref, DateTime.now()).toJson()));
      if (list.length > 400) list.removeRange(0, list.length - 400);
      await p.setStringList(_k, list);
    } catch (_) {}
  }

  static Future<List<FeedItem>> all() async {
    final p = await SharedPreferences.getInstance();
    final out = <FeedItem>[];
    for (final s in p.getStringList(_k) ?? const <String>[]) {
      try {
        out.add(FeedItem.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    return out;
  }
}

/// Real-life goal set by a parent, shown to the child as a quest.
class FamilyGoal {
  String id;
  String title;
  String kind; // lessons | activities | games
  int target;
  String reward;
  String image; // asset
  bool visible;
  DateTime created;
  DateTime? deadline;
  bool rewarded;

  FamilyGoal({
    required this.id,
    required this.title,
    required this.kind,
    required this.target,
    required this.reward,
    required this.image,
    this.visible = true,
    required this.created,
    this.deadline,
    this.rewarded = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ti': title,
        'k': kind,
        'ta': target,
        'r': reward,
        'im': image,
        'v': visible,
        'c': created.millisecondsSinceEpoch,
        'd': deadline?.millisecondsSinceEpoch,
        'rw': rewarded,
      };

  factory FamilyGoal.fromJson(Map<String, dynamic> j) => FamilyGoal(
        id: j['id'] as String,
        title: j['ti'] as String,
        kind: j['k'] as String,
        target: j['ta'] as int,
        reward: j['r'] as String,
        image: j['im'] as String,
        visible: j['v'] as bool? ?? true,
        created: DateTime.fromMillisecondsSinceEpoch(j['c'] as int),
        deadline: j['d'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['d'] as int),
        rewarded: j['rw'] as bool? ?? false,
      );

  /// Progress counted from the activity log since the goal was created.
  int progress(List<FeedItem> feed) {
    final n = feed.where((f) {
      if (f.at.isBefore(created)) return false;
      return switch (kind) {
        'lessons' => f.type == 'lesson',
        'games' => f.type == 'game',
        _ => true,
      };
    }).length;
    return min(n, target);
  }
}

class FamilyGoals {
  FamilyGoals._();
  static const _k = 'family_goals';

  static Future<List<FamilyGoal>> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_k);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List).map((e) => FamilyGoal.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<FamilyGoal> goals) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_k, jsonEncode(goals.map((g) => g.toJson()).toList()));
  }
}

/// Level at the start of each week (for "+N levels" in the weekly report).
class WeekLevel {
  WeekLevel._();
  static String key(DateTime d) {
    final m = DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
    return 'week_level_${Usage.dayKey(m)}';
  }

  static Future<void> note(int level) async {
    final p = await SharedPreferences.getInstance();
    final k = key(DateTime.now());
    if (!p.containsKey(k)) await p.setInt(k, level);
  }

  static Future<int?> at(DateTime d) async => (await SharedPreferences.getInstance()).getInt(key(d));
}

/// Lessons available per subject (bars fill against these).
const Map<String, int> subjectTotals = {'math': 8, 'french': 3, 'arabic': 0, 'islamicEducation': 3, 'science': 4};

Future<Map<String, int>> lessonsPerSubject() async {
  final p = await SharedPreferences.getInstance();
  return {for (final s in subjectTotals.keys) s: (p.getStringList('lessons_done_$s') ?? const []).length};
}

String fmtDuration(BuildContext context, int seconds) {
  final m = seconds ~/ 60;
  if (m < 60) return '$m min';
  return '${m ~/ 60} h ${(m % 60).toString().padLeft(2, '0')}';
}
