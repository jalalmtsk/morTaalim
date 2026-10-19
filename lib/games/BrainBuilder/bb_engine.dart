import 'dart:collection';
import 'dart:math';

/// Brain Builder — puzzle engine (pure Dart, no Flutter).
///
/// Every level is generated from a fixed seed, so level N is always the same
/// puzzle on every device. Each level is solved with a BFS, which gives the
/// fewest-moves solution (used for the star rating and for hints).

enum BBDir { up, right, down, left }

extension BBDirX on BBDir {
  int get dx => const [0, 1, 0, -1][index];
  int get dy => const [-1, 0, 1, 0][index];

  /// Wall bit for this side of a cell: N=1, E=2, S=4, W=8.
  int get bit => const [1, 2, 4, 8][index];
  BBDir get opposite => BBDir.values[(index + 2) % 4];
}

/// World 1 = walk the maze, World 2 = collect stars first, World 3 = ice (slide until a wall).
enum BBMode { walk, collect, slide }

const int bbLevelCount = 30;
const int bbLevelsPerWorld = 10;

int bbWorldOf(int level) => (level - 1) ~/ bbLevelsPerWorld;
BBMode bbModeOf(int level) => BBMode.values[bbWorldOf(level)];

class BBStep {
  final int to;
  final int mask;
  final List<int> path; // every cell entered, in order (last == to)
  const BBStep(this.to, this.mask, this.path);
}

class BBLevel {
  final int number;
  final int cols, rows;
  final List<int> walls; // per-cell wall bits
  final int start, goal;
  final List<int> gems; // little stars to collect before the goal counts
  final BBMode mode;

  BBLevel({
    required this.number,
    required this.cols,
    required this.rows,
    required this.walls,
    required this.start,
    required this.goal,
    required this.gems,
    required this.mode,
  });

  /// Fewest moves to win from the start (0 = unsolvable).
  late final int optimal = solve(start, 0)?.length ?? 0;

  bool get slides => mode == BBMode.slide;
  int get fullMask => (1 << gems.length) - 1;
  int col(int i) => i % cols;
  int row(int i) => i ~/ cols;
  bool blocked(int i, BBDir d) => walls[i] & d.bit != 0;

  /// Moves one step (walk) or slides until a wall / the goal (ice).
  /// Returns null when a wall is right there.
  BBStep? step(int pos, int mask, BBDir d) {
    if (blocked(pos, d)) return null;
    final path = <int>[];
    var p = pos, m = mask;
    while (true) {
      p += d.dy * cols + d.dx;
      path.add(p);
      final g = gems.indexOf(p);
      if (g >= 0) m |= 1 << g;
      if (!slides || p == goal || blocked(p, d)) break;
    }
    return BBStep(p, m, path);
  }

  bool isWin(int pos, int mask) => pos == goal && mask == fullMask;

  /// Shortest list of moves from (pos, mask) to a win, or null if impossible.
  List<BBDir>? solve(int pos, int mask) {
    if (isWin(pos, mask)) return const [];
    final w = 1 << gems.length;
    final n = cols * rows * w;
    final prev = List<int>.filled(n, -1);
    final how = List<int>.filled(n, -1);
    final s0 = pos * w + mask;
    prev[s0] = s0;
    final q = Queue<int>()..add(s0);
    while (q.isNotEmpty) {
      final s = q.removeFirst();
      final p = s ~/ w, m = s % w;
      for (final d in BBDir.values) {
        final st = step(p, m, d);
        if (st == null) continue;
        final ns = st.to * w + st.mask;
        if (prev[ns] != -1) continue;
        prev[ns] = s;
        how[ns] = d.index;
        if (isWin(st.to, st.mask)) {
          final out = <BBDir>[];
          var c = ns;
          while (c != s0) {
            out.add(BBDir.values[how[c]]);
            c = prev[c];
          }
          return out.reversed.toList();
        }
        q.add(ns);
      }
    }
    return null;
  }
}

// ─── Level design table ─────────────────────────────────────────────────────

class _Spec {
  final int cols, rows;
  final double density; // walk/collect: share of extra openings (loops); slide: share of walls
  final int gems, minMoves, maxMoves;
  const _Spec(this.cols, this.rows, this.density, this.gems, this.minMoves, this.maxMoves);
}

const List<_Spec> _specs = [
  // World 1 — Maze Meadow (walk)
  _Spec(4, 4, 0.00, 0, 6, 12),
  _Spec(4, 4, 0.10, 0, 6, 12),
  _Spec(5, 5, 0.05, 0, 8, 16),
  _Spec(5, 5, 0.10, 0, 9, 18),
  _Spec(5, 6, 0.08, 0, 10, 20),
  _Spec(6, 6, 0.08, 0, 12, 22),
  _Spec(6, 6, 0.12, 0, 13, 24),
  _Spec(6, 7, 0.10, 0, 14, 26),
  _Spec(7, 7, 0.10, 0, 16, 28),
  _Spec(7, 7, 0.05, 0, 18, 30),
  // World 2 — Star Garden (collect)
  _Spec(5, 5, 0.15, 1, 8, 20),
  _Spec(5, 5, 0.15, 1, 9, 22),
  _Spec(5, 6, 0.15, 2, 10, 24),
  _Spec(6, 6, 0.15, 2, 12, 26),
  _Spec(6, 6, 0.18, 2, 13, 28),
  _Spec(6, 7, 0.15, 2, 14, 30),
  _Spec(6, 7, 0.18, 3, 15, 32),
  _Spec(7, 7, 0.15, 3, 16, 34),
  _Spec(7, 7, 0.18, 3, 18, 36),
  _Spec(7, 8, 0.15, 3, 20, 40),
  // World 3 — Ice Islands (slide)
  _Spec(4, 4, 0.22, 0, 3, 5),
  _Spec(5, 5, 0.22, 0, 3, 6),
  _Spec(5, 5, 0.25, 0, 4, 7),
  _Spec(5, 6, 0.25, 0, 5, 8),
  _Spec(6, 6, 0.25, 0, 5, 9),
  _Spec(6, 6, 0.25, 1, 5, 10),
  _Spec(6, 6, 0.28, 1, 6, 11),
  _Spec(6, 7, 0.25, 2, 6, 12),
  _Spec(7, 7, 0.25, 2, 7, 13),
  _Spec(7, 7, 0.28, 2, 8, 14),
];

final Map<int, BBLevel> _cache = {};

/// The puzzle for level [n] (1-based). Deterministic and cached.
BBLevel bbLevel(int n) => _cache.putIfAbsent(n, () => _build(n));

BBLevel _build(int n) {
  final sp = _specs[max(0, min(n - 1, _specs.length - 1))];
  final mode = bbModeOf(max(1, min(n, bbLevelCount)));
  BBLevel? best;
  int score(BBLevel l) => l.optimal < sp.minMoves ? sp.minMoves - l.optimal : (l.optimal > sp.maxMoves ? l.optimal - sp.maxMoves : 0);
  for (var attempt = 0; attempt < 400; attempt++) {
    final rnd = Random(n * 10007 + attempt * 131 + 7);
    final l = mode == BBMode.slide ? _slide(n, sp, rnd) : _maze(n, sp, rnd, mode);
    if (l == null || l.optimal == 0) continue;
    if (score(l) == 0) return l;
    if (best == null || score(l) < score(best)) best = l;
  }
  return best ?? _maze(n, sp, Random(n), BBMode.walk);
}

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

List<int> _distances(List<int> w, int cols, int rows, int from) {
  final dist = List<int>.filled(cols * rows, -1)..[from] = 0;
  final q = Queue<int>()..add(from);
  while (q.isNotEmpty) {
    final p = q.removeFirst();
    for (final d in BBDir.values) {
      if (w[p] & d.bit != 0) continue;
      final nx = p + d.dy * cols + d.dx;
      if (dist[nx] != -1) continue;
      dist[nx] = dist[p] + 1;
      q.add(nx);
    }
  }
  return dist;
}

/// Perfect maze (recursive backtracker) + a few extra openings for loops.
BBLevel _maze(int n, _Spec sp, Random r, BBMode mode) {
  final c = sp.cols, rw = sp.rows, total = c * rw;
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
      if (_inside(c, rw, i, d) && w[i] & d.bit != 0 && r.nextDouble() < sp.density) _setWall(w, c, i, d, false);
    }
  }
  final start = (rw - 1) * c; // bottom-left
  final goal = c - 1; // top-right
  final gems = <int>[];
  if (sp.gems > 0) {
    final dist = _distances(w, c, rw, start);
    final score = <int, int>{
      for (var i = 0; i < total; i++)
        if (i != start && i != goal && dist[i] >= 2) i: dist[i] + (_bits(w[i]) == 3 ? 6 : 0) + r.nextInt(6)
    };
    final cands = score.keys.toList()..sort((a, b) => score[b]!.compareTo(score[a]!));
    for (final i in cands) {
      if (gems.length == sp.gems) break;
      final far = gems.every((g) => (g % c - i % c).abs() + (g ~/ c - i ~/ c).abs() >= 2);
      if (far) gems.add(i);
    }
  }
  return BBLevel(number: n, cols: c, rows: rw, walls: w, start: start, goal: goal, gems: gems, mode: mode);
}

/// Ice level: open field with scattered walls; goal chosen to need many slides.
BBLevel? _slide(int n, _Spec sp, Random r) {
  final c = sp.cols, rw = sp.rows, total = c * rw;
  final w = List<int>.filled(total, 0);
  for (var i = 0; i < total; i++) {
    if (i ~/ c == 0) w[i] |= BBDir.up.bit;
    if (i % c == c - 1) w[i] |= BBDir.right.bit;
    if (i ~/ c == rw - 1) w[i] |= BBDir.down.bit;
    if (i % c == 0) w[i] |= BBDir.left.bit;
  }
  for (var i = 0; i < total; i++) {
    for (final d in const [BBDir.right, BBDir.down]) {
      if (_inside(c, rw, i, d) && r.nextDouble() < sp.density) _setWall(w, c, i, d, true);
    }
  }
  final start = (rw - 1) * c + r.nextInt(c);

  BBLevel make(int goal, List<int> gems) =>
      BBLevel(number: n, cols: c, rows: rw, walls: w, start: start, goal: goal, gems: gems, mode: BBMode.slide);

  BBLevel? best;
  for (var g = 0; g < total; g++) {
    if (g == start) continue;
    final l = make(g, const []);
    final o = l.optimal;
    if (o == 0 || o > sp.maxMoves) continue;
    if (best == null || o > best.optimal) best = l;
  }
  if (best == null) return null;
  if (sp.gems == 0) return best;

  // Cells Robo can actually pass through → candidate star spots.
  final touched = <int>{};
  final seen = <int>{start};
  final q = Queue<int>()..add(start);
  while (q.isNotEmpty) {
    final p = q.removeFirst();
    for (final d in BBDir.values) {
      final st = best.step(p, 0, d);
      if (st == null) continue;
      touched.addAll(st.path);
      if (seen.add(st.to)) q.add(st.to);
    }
  }
  final pool = touched.where((x) => x != start && x != best!.goal).toList();
  if (pool.length < sp.gems) return null;
  for (var t = 0; t < 40; t++) {
    pool.shuffle(r);
    final l = make(best.goal, pool.take(sp.gems).toList());
    if (l.optimal > best.optimal) return l;
  }
  return null;
}
