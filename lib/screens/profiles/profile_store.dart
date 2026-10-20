import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart' as app show prefs;
import 'package:mortaalim/screens/main_home_screen/Profile/Customize/profile_look.dart';

/// One child on this device.
class KidProfile {
  final String id;
  String name;
  String avatar;
  String gender;
  int level;
  KidProfile({required this.id, this.name = '', this.avatar = '', this.gender = '', this.level = 1});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatar': avatar, 'gender': gender, 'level': level};
  factory KidProfile.fromJson(Map<String, dynamic> j) => KidProfile(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        avatar: (j['avatar'] ?? '') as String,
        gender: (j['gender'] ?? '') as String,
        level: (j['level'] ?? 1) as int,
      );
}

/// Multi-child profiles.
///
/// The whole app reads its data from plain SharedPreferences keys. Rather than
/// rewriting every key, the active child's data lives in the normal keys and
/// every other child's data is parked as one JSON snapshot under
/// `mt_pdata_<id>`. Switching = park the current child, clear, restore the
/// other one, reload the managers. Device-wide settings (sound, theme, parent
/// settings, ads, ban…) are never parked, so they are shared by all children.
class ProfileStore {
  ProfileStore._();

  static const int maxProfiles = 4;
  static const _listKey = 'mt_profiles';
  static const _activeKey = 'mt_active_profile';
  static const _dataPrefix = 'mt_pdata_';

  static const _globalPrefixes = ['mt_', 'ps_', 'flutter.'];
  static const _globalKeys = {
    'adsEnabled',
    'banned',
    'email',
    'app_notifications_enabled',
    'dismissedNotificationId',
    'showAyatCard',
    'showDuaaDialog',
    'selected_theme_index',
    'loading_theme_library',
    'bgVolume',
    'sfxVolume',
    'buttonVolume',
    'alertVolume',
    'isBgMuted',
    'isSfxMuted',
    'isButtonMuted',
    'isAlertMuted',
    'hapticsEnabled',
  };

  static bool isGlobal(String k) => _globalKeys.contains(k) || _globalPrefixes.any(k.startsWith);

  static SharedPreferences? _p;
  static Future<SharedPreferences> _prefs() async => _p ??= await SharedPreferences.getInstance();

  /// Id of the child currently playing ('p1' for the original/first child).
  static String activeId = 'p1';

  static List<KidProfile> _read(SharedPreferences p) {
    final raw = p.getString(_listKey);
    if (raw == null) return [];
    try {
      return [for (final j in jsonDecode(raw) as List) KidProfile.fromJson(Map<String, dynamic>.from(j as Map))];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(List<KidProfile> list) async =>
      (await _prefs()).setString(_listKey, jsonEncode([for (final k in list) k.toJson()]));

  /// Creates the first profile from the existing data on first run, and
  /// refreshes the active child's card info (name / avatar / level).
  static Future<List<KidProfile>> load(ExperienceManager xp) async {
    final p = await _prefs();
    activeId = p.getString(_activeKey) ?? 'p1';
    var list = _read(p);
    if (list.isEmpty) {
      list = [KidProfile(id: 'p1')];
      activeId = 'p1';
      await p.setString(_activeKey, 'p1');
    }
    if (!list.any((k) => k.id == activeId)) {
      list.add(KidProfile(id: activeId));
    }
    _fillFrom(list.firstWhere((k) => k.id == activeId), xp, p);
    await _write(list);
    return list;
  }

  static void _fillFrom(KidProfile k, ExperienceManager xp, SharedPreferences p) {
    k.name = xp.userProfile.fullName.trim();
    k.avatar = xp.selectedAvatar;
    k.gender = xp.userProfile.gender.isNotEmpty ? xp.userProfile.gender : (p.getString('gender') ?? '');
    k.level = xp.level;
  }

  static int count(SharedPreferences p) => _read(p).length;

  static bool isOnboarded(SharedPreferences p) => p.getBool('onboarding_completed') ?? false;

  /// Firestore document for the active child: the first child keeps the
  /// account's own document, the others get `<uid>_<id>`.
  static String cloudDocId(String uid) {
    var id = activeId;
    try {
      id = app.prefs.getString(_activeKey) ?? 'p1';
    } catch (_) {}
    return id == 'p1' ? uid : '${uid}_$id';
  }

  static Map<String, dynamic> _snapshot(SharedPreferences p) {
    final out = <String, dynamic>{};
    for (final k in p.getKeys()) {
      if (isGlobal(k)) continue;
      final v = p.get(k);
      if (v is bool) {
        out[k] = {'t': 'b', 'v': v};
      } else if (v is int) {
        out[k] = {'t': 'i', 'v': v};
      } else if (v is double) {
        out[k] = {'t': 'd', 'v': v};
      } else if (v is String) {
        out[k] = {'t': 's', 'v': v};
      } else if (v is List) {
        out[k] = {'t': 'l', 'v': v.map((e) => '$e').toList()};
      }
    }
    return out;
  }

  static Future<void> _restore(SharedPreferences p, Map<String, dynamic> snap) async {
    for (final e in snap.entries) {
      final m = Map<String, dynamic>.from(e.value as Map);
      final v = m['v'];
      switch (m['t']) {
        case 'b':
          await p.setBool(e.key, v as bool);
        case 'i':
          await p.setInt(e.key, (v as num).toInt());
        case 'd':
          await p.setDouble(e.key, (v as num).toDouble());
        case 's':
          await p.setString(e.key, v as String);
        case 'l':
          await p.setStringList(e.key, List<String>.from(v as List));
      }
    }
  }

  /// Makes [id] the active child and reloads the app data for them.
  static Future<void> switchTo(String id, ExperienceManager xp) async {
    final p = await _prefs();
    final list = _read(p);
    if (id == activeId) return;

    // 1. park the current child
    await xp.saveNow();
    final cur = list.where((k) => k.id == activeId);
    if (cur.isNotEmpty) _fillFrom(cur.first, xp, p);
    await p.setString('$_dataPrefix$activeId', jsonEncode(_snapshot(p)));

    // 2. clear the child keys
    for (final k in p.getKeys().toList()) {
      if (!isGlobal(k)) await p.remove(k);
    }

    // 3. restore the other child (a brand new one starts empty, in the same app language)
    final lang = xp.userProfile.preferredLanguage;
    final raw = p.getString('$_dataPrefix$id');
    if (raw != null) {
      try {
        await _restore(p, Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {}
      await p.remove('$_dataPrefix$id');
    } else {
      await p.setString('preferredLanguage', lang);
    }

    activeId = id;
    await p.setString(_activeKey, id);
    await _write(list);

    // 4. reload what is kept in memory
    await xp.loadData();
    await ProfileTitleStore.load();
    xp.syncWithFirebaseIfOnline();
  }

  /// Adds an empty child slot and returns its id (null if full).
  static Future<String?> create() async {
    final p = await _prefs();
    final list = _read(p);
    if (list.length >= maxProfiles) return null;
    var n = 1;
    while (list.any((k) => k.id == 'p$n')) {
      n++;
    }
    list.add(KidProfile(id: 'p$n'));
    await _write(list);
    return 'p$n';
  }

  /// Removes a child that is not the one currently playing.
  static Future<bool> delete(String id) async {
    if (id == activeId) return false;
    final p = await _prefs();
    final list = _read(p)..removeWhere((k) => k.id == id);
    await p.remove('$_dataPrefix$id');
    await _write(list);
    return true;
  }

  /// Renames a child that is not playing (the active one is renamed via its profile).
  static Future<void> rename(String id, String name) async {
    final p = await _prefs();
    final list = _read(p);
    for (final k in list) {
      if (k.id == id) k.name = name.trim();
    }
    await _write(list);
    if (id != activeId) {
      final raw = p.getString('$_dataPrefix$id');
      if (raw != null) {
        final snap = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        snap['name'] = {'t': 's', 'v': name.trim()};
        await p.setString('$_dataPrefix$id', jsonEncode(snap));
      }
    }
  }
}
