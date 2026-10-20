import 'dart:collection';
import 'dart:math';

/// Brain Builder — puzzle engine (pure Dart, no Flutter).
///
/// 6 worlds × 12 levels. Every level is generated from a fixed seed (same
/// puzzle on every device) and checked with a BFS solver: it must be solvable,
/// need its world's mechanic, and sit in the move range of its difficulty.

enum BBDir { up, right, down, left }

extension BBDirX on BBDir {
  int get dx => const [0, 1, 0, -1][index];
  int get dy => const [-1, 0, 1, 0][index];

  /// Wall bit for this side of a cell: N=1, E=2, S=4, W=8.
  int get bit => const [1, 2, 4, 8][index];
  BBDir get opposite => BBDir.values[(index + 2) % 4];
}

/// One mechanic per world, in map order.
enum BBMode { bridge, portal, ice, gear, moon, buddy }

const int bbWorldCount = 6;
const int bbLevelsPerWorld = 12;
const int bbLevelCount = bbWorldCount * bbLevelsPerWorld;

int bbWorldOf(int level) => (level - 1) ~/ bbLevelsPerWorld;
int bbIndexInWorld(int level) => (level - 1) % bbLevelsPerWorld;
BBMode bbModeOf(int level) => BBMode.values[bbWorldOf(level).clamp(0, bbWorldCount - 1)];

/// Flag bits: bit 0 = red buttons pressed, bit 1 = blue buttons pressed, bit 2 = gear turned.
const int bbGearBit = 4;

class BBState {
  final int p1, p2, mask, flags;
  const BBState(this.p1, this.p2, this.mask, this.flags);
}

class BBStep1 {
  final int to, mask, flags;
  final List<int> path; // every cell entered (a portal jump adds the destination)
  final bool teleported;
  const BBStep1(this.to, this.mask, this.flags, this.path, this.teleported);
}

class BBMove {
  final BBState to;
  final BBStep1? r1, r2; // null = that robot did not move
  const BBMove(this.to, this.r1, this.r2);
}

class BBLevel {
  final int number;
  final BBMode mode;
  final int cols, rows;
  final List<int> walls; // per-cell wall bits
  final int start, goal;
  final int start2, goal2; // second robot (buddy), -1 when unused
  final List<int> gems; // little stars to collect before the goal counts
  final Map<int, int> gates; // cell → colour (0 red, 1 blue): blocked until its button is pressed
  final Map<int, int> buttons; // cell → colour
  final Map<int, int> portals; // cell → twin cell
  final Set<int> switches; // gear switch cells (toggle the gear bit when entered)
  final Set<int> doorsA; // closed until the gear is turned
  final Set<int> doorsB; // open until the gear is turned

  BBLevel({
    required this.number,
    required this.mode,
    required this.cols,
    required this.rows,
    required this.walls,
    required this.start,
    required this.goal,
    this.start2 = -1,
    this.goal2 = -1,
    this.gems = const [],
    this.gates = const {},
    this.buttons = const {},
    this.portals = const {},
    this.switches = const {},
    this.doorsA = const {},
    this.doorsB = const {},
  });

  BBLevel copyWith({Map<int, int>? buttons, Map<int, int>? portals, Set<int>? switches}) => BBLevel(
        number: number,
        mode: mode,
        cols: cols,
        rows: rows,
        walls: walls,
        start: start,
        goal: goal,
        start2: start2,
        goal2: goal2,
        gems: gems,
        gates: gates,
        buttons: buttons ?? this.buttons,
        portals: portals ?? this.portals,
        switches: switches ?? this.switches,
        doorsA: doorsA,
        doorsB: doorsB,
      );

  /// Fewest moves to win from the start (0 = unsolvable).
  late final int optimal = solve(initial)?.length ?? 0;

  bool get slides => mode == BBMode.ice;
  bool get dark => mode == BBMode.moon;
  bool get buddy => start2 >= 0;
  int get cells => cols * rows;
  int get fullMask => (1 << gems.length) - 1;
  BBState get initial => BBState(start, buddy ? start2 : 0, 0, 0);
  int col(int i) => i % cols;
  int row(int i) => i ~/ cols;
  bool blocked(int i, BBDir d) => walls[i] & d.bit != 0;

  bool closed(int cell, int flags) {
    final c = gates[cell];
    if (c != null && flags & (1 << c) == 0) return true;
    if (doorsA.contains(cell) && flags & bbGearBit == 0) return true;
    if (doorsB.contains(cell) && flags & bbGearBit != 0) return true;
    return false;
  }

  /// Moves one robot one step (or slides on ice). [other] = cell it can't enter.
  BBStep1? step1(int pos, int mask, int flags, BBDir d, {int other = -1}) {
    if (blocked(pos, d)) return null;
    final path = <int>[];
    var p = pos, m = mask, fl = flags;
    var tele = false;
    while (true) {
      final n = p + d.dy * cols + d.dx;
      if (closed(n, fl) || n == other) break;
      p = n;
      path.add(p);
      final g = gems.indexOf(p);
      if (g >= 0) m |= 1 << g;
      final b = buttons[p];
      if (b != null) fl |= 1 << b;
      if (switches.contains(p)) fl ^= bbGearBit;
      final twin = portals[p];
      if (twin != null) {
        p = twin;
        path.add(p);
        tele = true;
        break;
      }
      if (!slides || p == goal || blocked(p, d)) break;
    }
    if (path.isEmpty) return null;
    return BBStep1(p, m, fl, path, tele);
  }

  /// One input: every robot moves the same way. Null = nothing can move.
  BBMove? move(BBState s, BBDir d) {
    if (!buddy) {
      final r = step1(s.p1, s.mask, s.flags, d);
      return r == null ? null : BBMove(BBState(r.to, 0, r.mask, r.flags), r, null);
    }
    final r1 = step1(s.p1, s.mask, s.flags, d);
    final q1 = r1?.to ?? s.p1;
    final m1 = r1?.mask ?? s.mask, f1 = r1?.flags ?? s.flags;
    final r2 = step1(s.p2, m1, f1, d, other: q1);
    final q2 = r2?.to ?? s.p2;
    if (q1 == q2) return null;
    if (q1 == s.p1 && q2 == s.p2) return null;
    return BBMove(BBState(q1, q2, r2?.mask ?? m1, r2?.flags ?? f1), r1, r2);
  }

  bool isWin(BBState s) => s.p1 == goal && s.mask == fullMask && (!buddy || s.p2 == goal2);

  int _key(BBState s) => ((s.p1 * cells + s.p2) * (fullMask + 1) + s.mask) * 8 + s.flags;

  /// Shortest list of moves from [s] to a win, or null if impossible.
  List<BBDir>? solve(BBState s) {
    if (isWin(s)) return const [];
    final size = cells * cells * (fullMask + 1) * 8;
    final prev = List<int>.filled(size, -1);
    final how = List<int>.filled(size, 0);
    final k0 = _key(s);
    prev[k0] = k0;
    final q = Queue<BBState>()..add(s);
    while (q.isNotEmpty) {
      final x = q.removeFirst();
      final kx = _key(x);
      for (final d in BBDir.values) {
        final mv = move(x, d);
        if (mv == null) continue;
        final y = mv.to;
        final ky = _key(y);
        if (prev[ky] != -1) continue;
        prev[ky] = kx;
        how[ky] = d.index;
        if (isWin(y)) {
          final out = <BBDir>[];
          var c = ky;
          while (c != k0) {
            out.add(BBDir.values[how[c]]);
            c = prev[c];
          }
          return out.reversed.toList();
        }
        q.add(y);
      }
    }
    return null;
  }
}

// ─── Level design table ─────────────────────────────────────────────────────

class _Spec {
  final int cols, rows;
  final double density; // maze: share of extra openings; ice/buddy field: share of walls / openings
  final int gems, extra, minMoves;
  const _Spec(this.cols, this.rows, this.density, this.gems, this.extra, this.minMoves);
  int get maxMoves => minMoves + max(8, minMoves ~/ 2);
}

const Map<BBMode, List<_Spec>> _specs = {
  BBMode.bridge: [
    _Spec(4, 4, .0, 0, 0, 6), _Spec(4, 4, .1, 0, 0, 6), _Spec(5, 5, .05, 0, 1, 8), _Spec(5, 5, .1, 0, 1, 9),
    _Spec(5, 5, .1, 1, 1, 10), _Spec(5, 6, .08, 0, 1, 11), _Spec(6, 6, .08, 0, 2, 12), _Spec(6, 6, .1, 1, 1, 13),
    _Spec(6, 6, .08, 0, 2, 14), _Spec(6, 7, .1, 1, 2, 15), _Spec(7, 7, .08, 0, 2, 16), _Spec(7, 7, .1, 1, 2, 18),
  ],
  BBMode.portal: [
    _Spec(5, 5, .05, 0, 1, 6), _Spec(5, 5, .08, 0, 1, 7), _Spec(5, 5, .1, 0, 1, 8), _Spec(5, 6, .08, 0, 1, 9),
    _Spec(6, 6, .08, 0, 1, 10), _Spec(6, 6, .1, 1, 1, 11), _Spec(6, 6, .08, 0, 2, 12), _Spec(6, 7, .1, 1, 1, 13),
    _Spec(6, 7, .08, 0, 2, 14), _Spec(7, 7, .1, 1, 2, 15), _Spec(7, 7, .08, 1, 2, 16), _Spec(7, 7, .1, 1, 2, 18),
  ],
  BBMode.ice: [
    _Spec(4, 4, .22, 0, 0, 3), _Spec(4, 4, .25, 0, 0, 4), _Spec(5, 5, .22, 0, 0, 4), _Spec(5, 5, .25, 0, 0, 5),
    _Spec(5, 5, .25, 1, 0, 5), _Spec(5, 6, .25, 0, 0, 6), _Spec(6, 6, .25, 0, 0, 6), _Spec(6, 6, .25, 1, 0, 7),
    _Spec(6, 6, .28, 1, 0, 7), _Spec(6, 7, .25, 1, 0, 8), _Spec(7, 7, .25, 2, 0, 8), _Spec(7, 7, .28, 2, 0, 9),
  ],
  BBMode.gear: [
    _Spec(5, 5, .05, 0, 1, 7), _Spec(5, 5, .08, 0, 1, 8), _Spec(5, 5, .1, 0, 1, 9), _Spec(5, 6, .08, 0, 1, 10),
    _Spec(6, 6, .08, 0, 1, 11), _Spec(6, 6, .1, 0, 2, 12), _Spec(6, 6, .1, 1, 1, 12), _Spec(6, 7, .08, 0, 2, 13),
    _Spec(6, 7, .1, 1, 2, 14), _Spec(7, 7, .08, 0, 2, 15), _Spec(7, 7, .1, 1, 2, 16), _Spec(7, 7, .1, 1, 2, 18),
  ],
  BBMode.moon: [
    _Spec(4, 4, .05, 0, 0, 6), _Spec(4, 5, .05, 0, 0, 7), _Spec(5, 5, .05, 0, 0, 8), _Spec(5, 5, .08, 0, 0, 9),
    _Spec(5, 6, .05, 1, 0, 10), _Spec(6, 6, .05, 0, 0, 12), _Spec(6, 6, .08, 1, 0, 13), _Spec(6, 6, .05, 1, 0, 14),
    _Spec(6, 7, .08, 1, 0, 15), _Spec(7, 7, .05, 1, 0, 16), _Spec(7, 7, .08, 2, 0, 18), _Spec(7, 7, .05, 2, 0, 20),
  ],
  BBMode.buddy: [
    _Spec(4, 4, .35, 0, 0, 4), _Spec(4, 4, .3, 0, 0, 5), _Spec(5, 5, .35, 0, 0, 5), _Spec(5, 5, .3, 0, 0, 6),
    _Spec(5, 5, .3, 0, 1, 7), _Spec(5, 6, .3, 0, 0, 7), _Spec(6, 6, .3, 0, 1, 8), _Spec(6, 6, .3, 0, 1, 9),
    _Spec(6, 6, .25, 0, 1, 10), _Spec(6, 7, .3, 0, 1, 10), _Spec(7, 7, .3, 0, 1, 11), _Spec(7, 7, .25, 0, 1, 12),
  ],
};

final Map<int, BBLevel> _cache = {};

/// The puzzle for level [n] (1-based). Deterministic and cached.
BBLevel bbLevel(int n) => _cache.putIfAbsent(n, () => _build(n.clamp(1, bbLevelCount)));

BBLevel _build(int n) {
  final mode = bbModeOf(n);
  final sp = _specs[mode]![bbIndexInWorld(n)];
  BBLevel? best;
  var bestScore = 1 << 30;
  int score(int o) => o < sp.minMoves ? sp.minMoves - o : (o > sp.maxMoves ? o - sp.maxMoves : 0);
  for (var attempt = 0; attempt < 300; attempt++) {
    final r = Random(n * 7919 + attempt * 131 + 7);
    final l = _gen(n, mode, sp, r);
    if (l == null || l.optimal == 0 || !_needsMechanic(l)) continue;
    final sc = score(l.optimal);
    if (sc == 0) return l;
    if (sc < bestScore) {
      best = l;
      bestScore = sc;
    }
  }
  return best ?? _gen(n, BBMode.moon, _specs[BBMode.moon]!.first, Random(n))!;
}

bool _needsMechanic(BBLevel l) {
  if ((l.mode == BBMode.bridge || l.mode == BBMode.buddy) && l.gates.isNotEmpty) {
    return l.copyWith(buttons: const {}).solve(l.initial) == null;
  }
  if (l.mode == BBMode.portal && l.portals.isNotEmpty) {
    return l.copyWith(portals: const {}).solve(l.initial) == null;
  }
  if (l.mode == BBMode.gear && l.doorsA.isNotEmpty) {
    return l.copyWith(switches: const {}).solve(l.initial) == null;
  }
  return true;
}

// ─── Generators ────────────────────────────────────────────────────────────

bool _inside(int cols, int rows, int i, BBDir d) {
  final c = i % cols + d.dx, r = i ~/ cols + d.dy;
  return c >= 0 && c < cols && r >= 0 && r < rows;
}

void _setWall(List<int> w, int cols, int i, BBDir d, bool on) {
  final j = i + d.dy * cols + d.dx;
  if (on) {
    w[i] |= d.bit;
    w[j] |= d.opposite.bit;
  } else {
    w[i] &= ~d.bit;
    w[j] &= ~d.opposite.bit;
  }
}

int _bits(int v) => (v & 1) + (v >> 1 & 1) + (v >> 2 & 1) + (v >> 3 & 1);

List<int> _maze(int c, int rw, double dens, Random r) {
  final total = c * rw;
  final w = List<int>.filled(total, 15);
  final seen = List<bool>.filled(total, false);
  final stack = <int>[r.nextInt(total)];
  seen[stack.first] = true;
  while (stack.isNotEmpty) {
    final cur = stack.last;
    final opts = [
      for (final d in BBDir.values)
        if (_inside(c, rw, cur, d) && !seen[cur + d.dy * c + d.dx]) d
    ];
    if (opts.isEmpty) {
      stack.removeLast();
      continue;
    }
    final d = opts[r.nextInt(opts.length)];
    _setWall(w, c, cur, d, false);
    final nx = cur + d.dy * c + d.dx;
    seen[nx] = true;
    stack.add(nx);
  }
  for (var i = 0; i < total; i++) {
    for (final d in const [BBDir.right, BBDir.down]) {
      if (_inside(c, rw, i, d) && w[i] & d.bit != 0 && r.nextDouble() < dens) _setWall(w, c, i, d, false);
    }
  }
  return w;
}

List<int> _openField(int c, int rw, double dens, Random r) {
  final total = c * rw;
  final w = List<int>.filled(total, 0);
  for (var i = 0; i < total; i++) {
    if (i ~/ c == 0) w[i] |= BBDir.up.bit;
    if (i % c == c - 1) w[i] |= BBDir.right.bit;
    if (i ~/ c == rw - 1) w[i] |= BBDir.down.bit;
    if (i % c == 0) w[i] |= BBDir.left.bit;
  }
  for (var i = 0; i < total; i++) {
    for (final d in const [BBDir.right, BBDir.down]) {
      if (_inside(c, rw, i, d) && r.nextDouble() < dens) _setWall(w, c, i, d, true);
    }
  }
  return w;
}

/// BFS over open edges. Returns (distance map, previous-cell map).
(Map<int, int>, Map<int, int>) _bfs(List<int> w, int c, int src, [Set<int> blockedCells = const {}]) {
  final dist = <int, int>{src: 0};
  final prev = <int, int>{src: -1};
  final q = Queue<int>()..add(src);
  while (q.isNotEmpty) {
    final p = q.removeFirst();
    for (final d in BBDir.values) {
      if (w[p] & d.bit != 0) continue;
      final n = p + d.dy * c + d.dx;
      if (dist.containsKey(n) || blockedCells.contains(n)) continue;
      dist[n] = dist[p]! + 1;
      prev[n] = p;
      q.add(n);
    }
  }
  return (dist, prev);
}

List<int> _path(Map<int, int> prev, int t) {
  final out = <int>[];
  int? c = t;
  while (c != null && c != -1) {
    out.add(c);
    c = prev[c];
  }
  return out.reversed.toList();
}

List<int> _sample(int n, int k, Random r) {
  final idx = List<int>.generate(n, (i) => i)..shuffle(r);
  return (idx.take(k).toList())..sort();
}

List<int> _placeGems(List<int> w, int c, int rw, int start, int goal, int count, Random r, [Set<int> avoid = const {}]) {
  if (count == 0) return const [];
  final (dist, _) = _bfs(w, c, start);
  final score = <int, int>{};
  for (var i = 0; i < c * rw; i++) {
    if (i == start || i == goal || avoid.contains(i) || (dist[i] ?? -1) < 2) continue;
    score[i] = dist[i]! + (_bits(w[i]) == 3 ? 6 : 0) + r.nextInt(6);
  }
  final cands = score.keys.toList()..sort((a, b) => score[b]!.compareTo(score[a]!));
  final gems = <int>[];
  for (final i in cands) {
    if (gems.length == count) break;
    if (gems.every((g) => (g % c - i % c).abs() + (g ~/ c - i ~/ c).abs() >= 2)) gems.add(i);
  }
  return gems;
}

BBLevel? _gen(int n, BBMode mode, _Spec sp, Random r) {
  final c = sp.cols, rw = sp.rows, total = c * rw;

  if (mode == BBMode.ice) {
    final w = _openField(c, rw, sp.density, r);
    final start = (rw - 1) * c + r.nextInt(c);
    BBLevel? best;
    for (var g = 0; g < total; g++) {
      if (g == start) continue;
      final l = BBLevel(number: n, mode: mode, cols: c, rows: rw, walls: w, start: start, goal: g);
      final o = l.optimal;
      if (o == 0 || o > sp.maxMoves) continue;
      if (best == null || o > best.optimal) best = l;
    }
    if (best == null) return null;
    if (sp.gems == 0) return best;
    final touched = <int>{};
    final seen = <int>{start};
    final q = Queue<int>()..add(start);
    while (q.isNotEmpty) {
      final p = q.removeFirst();
      for (final d in BBDir.values) {
        final st = best.step1(p, 0, 0, d);
        if (st == null) continue;
        touched.addAll(st.path);
        if (seen.add(st.to)) q.add(st.to);
      }
    }
    final pool = touched.where((x) => x != start && x != best!.goal).toList();
    if (pool.length < sp.gems) return null;
    pool.shuffle(r);
    return BBLevel(number: n, mode: mode, cols: c, rows: rw, walls: w, start: start, goal: best.goal, gems: pool.take(sp.gems).toList());
  }

  final w = _maze(c, rw, sp.density, r);

  if (mode == BBMode.buddy) {
    final cells = List<int>.generate(total, (i) => i)..shuffle(r);
    final s1 = cells[0], g1 = cells[1], s2 = cells[2], g2 = cells[3];
    if (sp.extra == 0) {
      return BBLevel(number: n, mode: mode, cols: c, rows: rw, walls: w, start: s1, goal: g1, start2: s2, goal2: g2);
    }
    final colour = r.nextInt(2);
    return BBLevel(
      number: n, mode: mode, cols: c, rows: rw, walls: w, start: s1, goal: g1, start2: s2, goal2: g2,
      gates: {cells[4]: colour}, buttons: {cells[5]: colour},
    );
  }

  var start = (rw - 1) * c, goal = c - 1;
  if (r.nextDouble() < .5) {
    start = total - 1;
    goal = 0;
  }
  final (_, prev0) = _bfs(w, c, start);
  final p = _path(prev0, goal);

  if (mode == BBMode.moon || sp.extra == 0) {
    return BBLevel(number: n, mode: mode, cols: c, rows: rw, walls: w, start: start, goal: goal,
        gems: _placeGems(w, c, rw, start, goal, sp.gems, r));
  }

  if (p.length < 5) return null;
  final mid = p.sublist(2, p.length - 2);
  if (mid.length < sp.extra + 1) return null;

  if (mode == BBMode.bridge) {
    final gates = <int, int>{};
    final buttons = <int, int>{};
    final picks = _sample(mid.length, sp.extra, r);
    for (var k = 0; k < picks.length; k++) {
      gates[mid[picks[k]]] = k;
    }
    var blocked = gates.keys.toSet();
    for (var colour = 0; colour < sp.extra; colour++) {
      final (d2, _) = _bfs(w, c, start, blocked);
      var cand = d2.keys.where((x) => !p.contains(x) && x != start && !buttons.containsKey(x)).toList();
      if (cand.isEmpty) {
        cand = d2.keys.where((x) => x != start && !buttons.containsKey(x) && !gates.containsKey(x)).toList();
      }
      if (cand.isEmpty) return null;
      cand.sort((a, b) => d2[b]!.compareTo(d2[a]!));
      buttons[cand[min(cand.length - 1, r.nextInt(3))]] = colour;
      blocked = {for (final e in gates.entries) if (e.value > colour) e.key};
    }
    final gems = _placeGems(w, c, rw, start, goal, sp.gems, r, {...gates.keys, ...buttons.keys});
    return BBLevel(number: n, mode: mode, cols: c, rows: rw, walls: w, start: start, goal: goal, gems: gems, gates: gates, buttons: buttons);
  }

  if (mode == BBMode.portal) {
    final wc = [...w];
    for (final k in _sample(p.length - 1, sp.extra, r)) {
      final a = p[k], b = p[k + 1];
      for (final d in BBDir.values) {
        if (_inside(c, rw, a, d) && a + d.dy * c + d.dx == b) _setWall(wc, c, a, d, true);
      }
    }
    final (d1, _) = _bfs(wc, c, start);
    if (d1.containsKey(goal)) return null;
    final portals = <int, int>{};
    final used = <int>{};
    var from = start;
    for (var i = 0; i < sp.extra; i++) {
      final (ds, _) = _bfs(wc, c, from);
      if (ds.containsKey(goal)) break;
      final next = p.where((x) => !ds.containsKey(x)).toList();
      if (next.isEmpty) break;
      final (dn, _) = _bfs(wc, c, next.first);
      final a = ds.keys.where((x) => !used.contains(x) && x != start && !p.contains(x)).toList();
      final b = dn.keys.where((x) => !used.contains(x) && x != goal).toList();
      if (a.isEmpty || b.isEmpty) return null;
      a.sort((x, y) => ds[y]!.compareTo(ds[x]!));
      final pa = a[min(a.length - 1, r.nextInt(2))];
      final pb = b[r.nextInt(b.length)];
      portals[pa] = pb;
      portals[pb] = pa;
      used.addAll([pa, pb]);
      from = next.first;
    }
    final gems = _placeGems(wc, c, rw, start, goal, sp.gems, r, portals.keys.toSet());
    return BBLevel(number: n, mode: mode, cols: c, rows: rw, walls: wc, start: start, goal: goal, gems: gems, portals: portals);
  }

  // Gear factory
  final doorsA = [for (final i in _sample(mid.length, sp.extra, r)) mid[i]];
  final (dA, _) = _bfs(w, c, start, doorsA.toSet());
  final cand = dA.keys.where((x) => !p.contains(x) && x != start).toList();
  if (cand.isEmpty) return null;
  cand.sort((a, b) => dA[b]!.compareTo(dA[a]!));
  final sw = cand[min(cand.length - 1, r.nextInt(3))];
  final (_, prevS) = _bfs(w, c, start);
  final swPath = _path(prevS, sw);
  final doorsB = <int>[];
  if (sp.extra > 1) {
    final opts = p.skip(1).where((x) => !doorsA.contains(x) && !swPath.contains(x) && x != goal).toList();
    if (opts.isNotEmpty) doorsB.add(opts[r.nextInt(opts.length)]);
  }
  final gems = _placeGems(w, c, rw, start, goal, sp.gems, r, {...doorsA, ...doorsB, sw});
  return BBLevel(
    number: n, mode: mode, cols: c, rows: rw, walls: w, start: start, goal: goal, gems: gems,
    switches: {sw}, doorsA: doorsA.toSet(), doorsB: doorsB.toSet(),
  );
}
