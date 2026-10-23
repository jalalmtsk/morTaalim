import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MoorTaalim reward rules — one place for every XP / gold / gem amount.
//
//  XP    = effort & learning. Every activity gives some, better play gives
//          more. It fills the level bar (avatar frames, titles, level gems).
//  Gold  = the everyday coin. Earned for finishing things, mostly the FIRST
//          time. Spent on unlocking games, courses, languages and hints.
//  Gems  = rare. Only for mastery (first 3 stars), finishing a whole world,
//          levelling up, daily treasure / quests and milestones. Spent on
//          avatars, banners and frames.
//
// Rough targets for a child playing ~20 min a day:
//   ≈ 180 XP, ≈ 40–60 gold, ≈ 5–8 gems per day.
//   (Gold is kept scarce on purpose; XP is generous so levels move fast.)
// ═══════════════════════════════════════════════════════════════════════════

class Reward {
  final int xp, gold, gems;
  const Reward({this.xp = 0, this.gold = 0, this.gems = 0});
  static const none = Reward();
  Reward operator +(Reward o) => Reward(xp: xp + o.xp, gold: gold + o.gold, gems: gems + o.gems);
  bool get isEmpty => xp == 0 && gold == 0 && gems == 0;
  @override
  String toString() => 'Reward(xp: $xp, gold: $gold, gems: $gems)';
}

class Rewards {
  Rewards._();

  // ── level curve ────────────────────────────────────────────────────────
  /// XP needed to go from [level] to [level] + 1: 50, 75, 100, 125 …
  static int xpToNext(int level) => 50 + 25 * (max(1, level) - 1);

  /// Total XP needed to reach [level] (level 1 = 0 XP).
  static int totalXpFor(int level) {
    if (level <= 1) return 0;
    final n = level - 1; // steps from level 1
    return 50 * n + 25 * n * (n - 1) ~/ 2;
  }

  /// Gems given when the child reaches [level]: 2, and 5 on every 5th level.
  static int gemsForLevel(int level) => level % 5 == 0 ? 5 : 2;

  // ── level-based games (stars 1–3) ──────────────────────────────────────
  /// Market, Garden, Passport, Mystery Quest, Brain Builder, Puzzle Land …
  ///  [tier]      1 (easy) … 4 (hard) — usually the world / difficulty.
  ///  [stars]     stars just earned (1–3).
  ///  [prevStars] best stars before this play (0 = first time).
  ///  [bonusGems] for finishing a whole world / country / new plant …
  static Reward level({required int tier, required int stars, required int prevStars, int bonusGems = 0}) {
    final t = tier.clamp(1, 4);
    final s = stars.clamp(0, 3);
    if (s == 0) return const Reward(xp: 4);
    final first = prevStars <= 0;
    final gained = max(0, s - prevStars);
    final xp = (first || gained > 0) ? 14 + 6 * t + 5 * s : 6 + 3 * t;
    final gold = first ? 4 + 2 * t + s : (gained > 0 ? 2 * gained : 1);
    final gems = (s == 3 && prevStars < 3 ? 1 : 0) + bonusGems;
    return Reward(xp: xp, gold: gold, gems: gems);
  }

  /// Same, when the store only tells how many stars were newly won.
  static Reward levelFromGain({required int tier, required int stars, required int gained, int bonusGems = 0}) =>
      level(tier: tier, stars: stars, prevStars: gained >= stars ? 0 : (gained > 0 ? stars - gained : stars), bonusGems: bonusGems);

  // ── quiz / exercise / arcade sessions ──────────────────────────────────
  /// One finished round: [correct] good answers out of [total].
  ///  XP   3 per good answer + 8 for finishing (max 60)
  ///  gold 1 per 3 good answers + 2 for a perfect round (max 8)
  ///  gems 1 for a perfect round of 10+ questions [perfectGem]
  static Reward session({required int correct, required int total, bool finished = true, bool perfectGem = false}) {
    final c = max(0, correct);
    final perfect = finished && total > 0 && c >= total;
    final xp = min(60, 3 * c + (finished ? 8 : 0));
    final gold = min(8, c ~/ 3 + (perfect ? 2 : 0));
    final gems = (perfect && perfectGem && total >= 10) ? 1 : 0;
    return Reward(xp: xp, gold: gold, gems: gems);
  }

  /// Score-based arcade games (piano tiles, jumping board …): XP grows slowly with the score.
  static Reward arcade(int score, {int perXp = 5, int perGold = 25}) =>
      Reward(xp: min(45, 4 + (score * 3) ~/ (perXp * 2)), gold: min(5, score ~/ (perGold * 2)));

  /// End of an endless practice run (math, matching … with lives):
  /// a small bonus on top of the 1 XP per good answer.
  static Reward practiceEnd(int score) {
    if (score < 3) return const Reward(xp: 2);
    return Reward(xp: min(18, (score * 3) ~/ 2), gold: min(5, score ~/ 5) + (score >= 10 ? 1 : 0));
  }

  /// Endless "next level" games (Memory, Shape sorter …): grows with the
  /// level reached but stays small, since they can be replayed forever.
  static Reward endlessLevel({required int level, required int stars}) {
    final t = (1 + level ~/ 3).clamp(1, 4);
    return Reward(xp: 10 + 3 * t + 3 * stars.clamp(1, 3), gold: 1 + t);
  }

  /// Alphabet tracing: every 10 new letters learnt.
  static const alphabetMilestone = Reward(gold: 4, xp: 12);

  /// Alphabet tracing: a whole alphabet finished.
  static const alphabetComplete = Reward(gold: 12, gems: 2, xp: 30);

  // ── learning content ───────────────────────────────────────────────────
  /// A lesson / story / course chapter read to the end.
  static Reward lesson({bool first = true}) => first ? const Reward(xp: 20, gold: 4) : const Reward(xp: 6);

  /// A video watched to the end.
  static const video = Reward(xp: 6, gold: 1);

  /// Creative play (drawing, free piano …): a little XP, no farming.
  static const creative = Reward(xp: 8, gold: 1);

  // ── daily & meta ───────────────────────────────────────────────────────
  static const duaa = Reward(gold: 2, xp: 5);
  static const newBadge = Reward(gold: 5, gems: 1, xp: 15);
  static const unlockSomething = Reward(xp: 15);

  // ── shop ───────────────────────────────────────────────────────────────
  /// Gold needed to buy one gem in the trade dialog (gems stay rare).
  static const goldPerGem = 50;

  /// Hint price in level games.
  static const hintGold = 10;
}

extension RewardGrant on ExperienceManager {
  /// Gives a whole [Reward] at once (gold → gems → XP, so banners queue nicely).
  void grant(BuildContext context, Reward r) {
    if (!context.mounted || r.isEmpty) return;
    if (r.gold > 0) addGold(context, r.gold);
    if (r.gems > 0) addGems(context, r.gems);
    if (r.xp > 0) addXP(r.xp, context: context);
  }
}
