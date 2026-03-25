// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/sound_service.dart';
import '../../services/profile_service.dart';

// ── Word banks ────────────────────────────────────────────────────────────────
const _kEasyWords = [
  'cat', 'dog', 'run', 'sun', 'hat', 'cup', 'pen', 'box', 'red', 'sky',
  'ant', 'egg', 'ice', 'owl', 'rat', 'arm', 'fan', 'fog', 'gem', 'hen',
  'jaw', 'lip', 'nap', 'pay', 'dig', 'log', 'mud', 'rot', 'sap', 'web',
  'zap', 'claw', 'dead', 'doom', 'gore', 'howl', 'lurch', 'moan',
];
const _kMedWords = [
  'brain', 'flesh', 'groan', 'horde', 'swarm', 'curse', 'crypt', 'blood',
  'crawl', 'decay', 'grave', 'haunt', 'lurk', 'night', 'panic', 'scream',
  'stalk', 'undead', 'vault', 'waste', 'apple', 'table', 'chair', 'house',
  'water', 'light', 'plant', 'river', 'stone', 'cloud', 'music', 'dance',
  'sleep', 'dream', 'smile', 'happy', 'smart', 'great', 'world', 'focus',
];
const _kHardWords = [
  'nightmare', 'infection', 'outbreak', 'shambling', 'graveyard',
  'relentless', 'survivor', 'barricade', 'apocalypse', 'desperate',
  'eliminate', 'devastate', 'overwhelm', 'catastrophe', 'unstoppable',
  'dangerous', 'terrifying', 'bloodthirsty', 'merciless', 'destruction',
];
const _kPowerFreeze = 'freeze';
const _kPowerBomb   = 'bomb';

enum ZombieDifficulty { easy, medium, hard }

// ── Zombie model ──────────────────────────────────────────────────────────────
class Zombie {
  final String id;
  final String word;
  double x, y, speed;
  final Color skinColor, wordColor;
  bool targeted, dying;
  double opacity, deathAnim, walkCycle;
  final ZombieType type;
  final int lane;

  Zombie({
    required this.id,
    required this.word,
    required this.x,
    required this.y,
    required this.speed,
    required this.skinColor,
    required this.wordColor,
    required this.lane,
    required this.type,
    this.targeted  = false,
    this.dying     = false,
    this.opacity   = 1.0,
    this.deathAnim = 0.0,
    this.walkCycle = 0.0,
  });
}

enum ZombieType { normal, fast, tank, freeze, bomb }

// ── Bullet ────────────────────────────────────────────────────────────────────
class ZBullet {
  double x, y;
  final double vx, vy, destX, destY;
  final Color color;
  double opacity;
  final bool isFinal;
  final String zombieId;

  ZBullet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.destX,
    required this.destY,
    required this.color,
    required this.zombieId,
    this.isFinal = false,
    this.opacity = 1.0,
  });

  bool get arrived {
    final dx = destX - x;
    final dy = destY - y;
    return (dx * vx + dy * vy) <= 0;
  }
}

// ── Particle ──────────────────────────────────────────────────────────────────
class ZParticle {
  double x, y, vx, vy, life, size;
  final Color color;
  ZParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.color, required this.size,
    this.life = 1.0,
  });
}

// ── Blood splat ───────────────────────────────────────────────────────────────
class BloodSplat {
  final double x, y, radius, opacity;
  BloodSplat({
    required this.x, required this.y,
    required this.radius, this.opacity = 0.4,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
class ZombieSurvivalGame extends StatefulWidget {
  const ZombieSurvivalGame({super.key});
  @override
  State<ZombieSurvivalGame> createState() => _ZombieSurvivalGameState();
}

class _ZombieSurvivalGameState extends State<ZombieSurvivalGame>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────────────────────
  ZombieDifficulty _difficulty = ZombieDifficulty.easy;
  bool _started = false, _gameOver = false, _paused = false;
  bool _waveAnnouncing = false;

  int _score = 0, _highScore = 0, _wave = 1, _kills = 0;
  int _baseHp = 10, _combo = 0, _maxCombo = 0;

  bool   _frozen = false;
  Timer? _freezeTimer;

  // ── Game objects ───────────────────────────────────────────────────────────
  final List<Zombie>    _zombies   = [];
  final List<ZBullet>   _bullets   = [];
  final List<ZParticle> _particles = [];
  final List<BloodSplat>_splats    = [];
  final _rng = Random();

  // ── Typing ─────────────────────────────────────────────────────────────────
  String  _typed  = '';
  Zombie? _locked;

  // ── Turret ─────────────────────────────────────────────────────────────────
  double _turretAngle       = 0.0;
  double _turretTargetAngle = 0.0;

  // ── Timers ─────────────────────────────────────────────────────────────────
  Timer?    _gameLoop, _spawnTimer;
  DateTime? _lastFrame;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  // ── Layout ─────────────────────────────────────────────────────────────────
  double _screenW = 900, _screenH = 600;
  double get _uiScale   => min(_screenW, _screenH) / 600.0;
  double get _fontScale => _uiScale.clamp(0.7, 1.35);
  static const double _baseX = 90.0;

  List<double> get _laneY => [
    _screenH * 0.28,
    _screenH * 0.52,
    _screenH * 0.76,
  ];

  final FocusNode _focus = FocusNode();

  // ── Cached config (rebuilt only on difficulty change) ──────────────────────
  late Map<String, dynamic> _cfg;
  late List<String> _wordBank;

  void _rebuildConfig() {
    _cfg = {
      ZombieDifficulty.easy: {
        'spawnMs': 3500, 'speedMin': 28.0, 'speedMax': 50.0,
        'max': 4, 'hpMax': 10,
      },
      ZombieDifficulty.medium: {
        'spawnMs': 2400, 'speedMin': 48.0, 'speedMax': 85.0,
        'max': 7, 'hpMax': 8,
      },
      ZombieDifficulty.hard: {
        'spawnMs': 1500, 'speedMin': 75.0, 'speedMax': 130.0,
        'max': 10, 'hpMax': 6,
      },
    }[_difficulty]!;

    _wordBank = {
      ZombieDifficulty.easy:   _kEasyWords,
      ZombieDifficulty.medium: _kMedWords,
      ZombieDifficulty.hard:   _kHardWords,
    }[_difficulty]!;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _rebuildConfig();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _loadHs();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _freezeTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  bool get _canPersistScore {
    final profile = ProfileService();
    return profile.hasProfile && !profile.isGuest;
  }

  Future<void> _loadHs() async {
    if (!_canPersistScore) {
      if (mounted) setState(() => _highScore = 0);
      return;
    }
    final p = await SharedPreferences.getInstance();
    final k = '${ProfileService().keyPrefix}zombie_hs_${_difficulty.name}';
    if (mounted) setState(() => _highScore = p.getInt(k) ?? 0);
  }

  Future<void> _saveHs() async {
    if (!_canPersistScore) return;
    if (_score <= _highScore) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(
      '${ProfileService().keyPrefix}zombie_hs_${_difficulty.name}',
      _score,
    );
    if (mounted) setState(() => _highScore = _score);
  }

  // ── Start ───────────────────────────────────────────────────────────────────
  void _startGame() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _freezeTimer?.cancel();
    setState(() {
      _started       = true;
      _gameOver      = false;
      _paused        = false;
      _score         = 0;
      _wave          = 1;
      _kills         = 0;
      _combo         = 0;
      _maxCombo      = 0;
      _baseHp        = _cfg['hpMax'] as int;
      _typed         = '';
      _locked        = null;
      _frozen        = false;
      _zombies.clear();
      _bullets.clear();
      _particles.clear();
      _splats.clear();
      _turretAngle       = 0;
      _turretTargetAngle = 0;
    });
    _lastFrame = DateTime.now();
    _gameLoop  = Timer.periodic(const Duration(milliseconds: 16), _tick);
    _announceWave();
  }

  void _endGame() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _freezeTimer?.cancel();
    _saveHs();
    setState(() => _gameOver = true);
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (!_paused) _lastFrame = DateTime.now();
  }

  // ── Wave system ─────────────────────────────────────────────────────────────
  void _announceWave() {
    setState(() => _waveAnnouncing = true);
    _waveCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && !_gameOver) {
        setState(() => _waveAnnouncing = false);
        _scheduleSpawn();
      }
    });
  }

  void _scheduleSpawn() {
    _spawnTimer?.cancel();
    if (_gameOver) return;
    final baseMs = _cfg['spawnMs'] as int;
    final ms = (baseMs * (1.0 / (1 + _wave * 0.08))).round().clamp(800, baseMs);
    _spawnTimer = Timer(Duration(milliseconds: ms), () {
      if (!_gameOver && !_paused && _started && !_waveAnnouncing) {
        _spawnZombie();
        _scheduleSpawn();
      } else if (!_gameOver) {
        _scheduleSpawn();
      }
    });
  }

  void _checkWaveAdvance() {
    if (_kills > 0 && _kills % 8 == 0) {
      final expectedWave = (_kills ~/ 8) + 1;
      if (expectedWave > _wave) {
        _wave = expectedWave;
        _announceWave();
      }
    }
  }

  // ── Spawn zombie ────────────────────────────────────────────────────────────
  void _spawnZombie() {
    final maxOnScreen = _cfg['max'] as int;
    if (_zombies.where((z) => !z.dying).length >= maxOnScreen) return;

    // Pick lane with fewest zombies
    final laneCounts = [0, 1, 2]
        .map((l) => _zombies.where((z) => z.lane == l && !z.dying).length)
        .toList();
    final lane = laneCounts.indexOf(laneCounts.reduce(min));

    final usedFirst = _zombies
        .where((z) => !z.dying && !z.targeted)
        .map((z) => z.word[0].toLowerCase())
        .toSet();

    ZombieType type = ZombieType.normal;
    String word;

    final roll = _rng.nextDouble();
    if (roll < 0.07 && _wave >= 2) {
      type = ZombieType.freeze;
      word = _kPowerFreeze;
    } else if (roll < 0.12 && _wave >= 3) {
      type = ZombieType.bomb;
      word = _kPowerBomb;
    } else if (roll < 0.22 && _wave >= 2) {
      type = ZombieType.fast;
      word = _pickWord(usedFirst, fromBank: _kEasyWords);
    } else if (roll < 0.30 && _wave >= 3) {
      type = ZombieType.tank;
      word = _pickWord(usedFirst, fromBank: _kHardWords);
    } else {
      word = _pickWord(usedFirst);
    }

    final minS = _cfg['speedMin'] as double;
    final maxS = _cfg['speedMax'] as double;
    double speed = minS + _rng.nextDouble() * (maxS - minS);
    if (type == ZombieType.fast) speed *= 1.8;
    if (type == ZombieType.tank) speed *= 0.5;
    speed *= (1.0 + _wave * 0.05);

    final y = _laneY[lane] + _rng.nextDouble() * 20 - 10;
    _zombies.add(Zombie(
      id:        '${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(9999)}',
      word:      word,
      x:         _screenW + 60,
      y:         y,
      speed:     speed,
      skinColor: _zombieColor(type),
      wordColor: _wordColor(type),
      lane:      lane,
      type:      type,
      walkCycle: _rng.nextDouble() * 2 * pi,
    ));
  }

  String _pickWord(Set<String> usedFirst, {List<String>? fromBank}) {
    final bank  = fromBank ?? _wordBank;
    final avail = bank.where((w) => !usedFirst.contains(w[0].toLowerCase())).toList();
    final pool  = avail.isNotEmpty ? avail : bank;
    return pool[_rng.nextInt(pool.length)];
  }

  Color _zombieColor(ZombieType t) => const {
    ZombieType.normal: Color(0xFF6B8C3E),
    ZombieType.fast:   Color(0xFF3E7A8C),
    ZombieType.tank:   Color(0xFF8C3E3E),
    ZombieType.freeze: Color(0xFF3E8C7A),
    ZombieType.bomb:   Color(0xFF8C6B3E),
  }[t]!;

  Color _wordColor(ZombieType t) => const {
    ZombieType.normal: Color(0xFFAAFF66),
    ZombieType.fast:   Color(0xFF66DDFF),
    ZombieType.tank:   Color(0xFFFF6666),
    ZombieType.freeze: Color(0xFF66FFEE),
    ZombieType.bomb:   Color(0xFFFFCC44),
  }[t]!;

  // ── Game tick ───────────────────────────────────────────────────────────────
  void _tick(Timer t) {
    if (_paused || _gameOver || !_started) return;

    final now = DateTime.now();
    final dt = _lastFrame == null
        ? 0.016
        : now.difference(_lastFrame!).inMilliseconds / 1000.0;
    _lastFrame = now;
    final safeDt = dt.clamp(0.0, 0.05);

    // ── Update logic (no setState here – done once below) ─────────────────
    // Move zombies
    for (final z in _zombies) {
      if (z.dying) {
        z.deathAnim += safeDt * 2.5;
        z.opacity    = (1.0 - z.deathAnim).clamp(0, 1);
      } else {
        z.walkCycle += safeDt * (z.speed / 30) * pi;
        if (!_frozen) z.x -= z.speed * safeDt;
      }
    }

    // Move bullets
    final deadBullets = <ZBullet>[];
    for (final b in _bullets) {
      b.x += b.vx * safeDt;
      b.y += b.vy * safeDt;
      if (b.arrived) {
        _onBulletHit(b);
        deadBullets.add(b);
      }
    }
    for (final b in deadBullets) _bullets.remove(b);

    // Update particles
    for (final p in _particles) {
      p.life -= safeDt * 2.0;
      p.x    += p.vx * safeDt;
      p.y    += p.vy * safeDt;
      p.vy   += 120 * safeDt;
    }

    // Smooth turret rotation
    final diff     = _turretTargetAngle - _turretAngle;
    _turretAngle  += diff * (safeDt * 10).clamp(0, 1);

    // Remove dead
    _zombies.removeWhere((z) => z.dying && z.opacity <= 0);
    _particles.removeWhere((p) => p.life <= 0);
    if (_splats.length > 30) _splats.removeRange(0, _splats.length - 30);

    // Check base reach
    final reachedBase = _zombies.where((z) => !z.dying && z.x <= _baseX + 20).toList();
    for (final z in reachedBase) {
      _zombieReachedBase(z);
    }

    // Single setState for the whole frame
    if (mounted) setState(() {});
  }

  void _zombieReachedBase(Zombie z) {
    _zombies.remove(z);
    if (_locked == z) { _locked = null; _typed = ''; }
    _baseHp--;
    _combo = 0;
    SoundService().playError();
    _spawnParticles(_baseX + 20, _screenH * 0.5, const Color(0xFFFF4444), count: 12, spread: 100);
    if (_baseHp <= 0) _endGame();
  }

  // ── Bullet system ───────────────────────────────────────────────────────────
  void _fireBullet(Zombie target, {bool isFinal = false}) {
    final tx = target.x;
    final ty = target.y - 10;
    final sx = _baseX + 40.0;
    final sy = _screenH * 0.5;

    final dx   = tx - sx;
    final dy   = ty - sy;
    final dist = sqrt(dx * dx + dy * dy);
    const speed = 800.0;

    Color col;
    if (target.type == ZombieType.freeze)    col = const Color(0xFF66FFEE);
    else if (target.type == ZombieType.bomb) col = const Color(0xFFFFCC44);
    else if (isFinal)                        col = Colors.white;
    else                                     col = const Color(0xFF88FF44);

    _bullets.add(ZBullet(
      x: sx, y: sy,
      vx: (dx / dist) * speed,
      vy: (dy / dist) * speed,
      destX: tx, destY: ty,
      color: col, zombieId: target.id,
      isFinal: isFinal,
    ));

    _turretTargetAngle = atan2(dy, dx);
  }

  void _onBulletHit(ZBullet b) {
    final z = _zombies.where((z) => z.id == b.zombieId && !z.dying).firstOrNull;
    if (z == null) return;

    if (b.isFinal) {
      z.dying = true;
      _spawnParticles(b.destX, b.destY, z.skinColor, count: 18);
      _splats.add(BloodSplat(
        x: z.x, y: z.y + 20,
        radius:  15 + _rng.nextDouble() * 12,
        opacity: 0.35 + _rng.nextDouble() * 0.2,
      ));

      if (z.type == ZombieType.freeze) _activateFreeze();
      if (z.type == ZombieType.bomb)   _activateBomb();

      _kills++;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;

      final comboMult = _combo >= 10 ? 3 : _combo >= 5 ? 2 : 1;
      final diffMult  = _difficulty == ZombieDifficulty.hard
          ? 3 : _difficulty == ZombieDifficulty.medium ? 2 : 1;
      _score += z.word.length * 10 * comboMult * diffMult;

      for (final zz in _zombies) {
        zz.targeted = false;
      }
      _locked = null;
      _typed  = '';

      SoundService().playStreak();
      _checkWaveAdvance();
    } else {
      _spawnParticles(b.destX, b.destY, b.color, count: 4, spread: 50, life: 0.4);
    }
  }

  void _activateFreeze() {
    _frozen = true;
    _freezeTimer?.cancel();
    _freezeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _frozen = false);
    });
    for (final z in _zombies) {
      if (!z.dying) _spawnParticles(z.x, z.y, const Color(0xFF66FFEE), count: 6);
    }
  }

  void _activateBomb() {
    // FIX: operator-precedence bug in original — properly grouped now
    for (final z in List<Zombie>.from(_zombies)) {
      if (!z.dying && (z.type == ZombieType.normal || z.type == ZombieType.fast)) {
        z.dying = true;
        _kills++;
        _score += 5;
        _spawnParticles(z.x, z.y, z.skinColor, count: 12);
        _splats.add(BloodSplat(x: z.x, y: z.y + 20, radius: 18));
      }
    }
    SoundService().playLevelComplete();
  }

  void _spawnParticles(double x, double y, Color col, {
    int count = 12, double spread = 160, double life = 1.0,
  }) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final s = 20 + _rng.nextDouble() * spread;
      _particles.add(ZParticle(
        x: x, y: y,
        vx: cos(a) * s, vy: sin(a) * s - 60,
        color: i % 3 == 0 ? Colors.white70 : col,
        size: 2 + _rng.nextDouble() * 4,
        life: life * (0.6 + _rng.nextDouble() * 0.4),
      ));
    }
  }

  // ── Key handler ─────────────────────────────────────────────────────────────
  void _handleKey(KeyEvent event) {
    if (!_started || _gameOver) return;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _togglePause();
      return;
    }
    if (_paused) return;

    String? char;
    if (event.character != null && event.character!.isNotEmpty) {
      char = event.character!;
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_typed.isNotEmpty) {
        setState(() {
          _typed = _typed.substring(0, _typed.length - 1);
          if (_typed.isEmpty) {
            _locked?.targeted = false;
            _locked = null;
          }
        });
      }
      return;
    }
    if (char == null) return;

    setState(() {
      // Acquire target
      if (_locked == null || !_zombies.contains(_locked) || _locked!.dying) {
        _locked = null;
        _typed  = '';
        for (final z in _zombies) {
          if (!z.dying && z.word.toLowerCase().startsWith(char!.toLowerCase())) {
            _locked = z;
            z.targeted = true;
            final dx = z.x - (_baseX + 40);
            final dy = z.y - _screenH * 0.5;
            _turretTargetAngle = atan2(dy, dx);
            break;
          }
        }
        if (_locked == null) {
          SoundService().playError();
          return;
        }
      }

      final z        = _locked!;
      final expected = z.word[_typed.length];

      if (char!.toLowerCase() == expected.toLowerCase()) {
        _typed += char;
        SoundService().playKeyClick();
        final isLast = _typed.length >= z.word.length;
        _fireBullet(z, isFinal: isLast);
      } else {
        SoundService().playError();
        _combo = 0;
      }
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0A),
      body: KeyboardListener(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (ctx, box) {
            _screenW = box.maxWidth;
            _screenH = box.maxHeight;
            return Stack(
              children: [
                // Static background – never repaints on its own
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(_screenW, _screenH),
                    painter: _ZombieBackgroundPainter(_screenW, _screenH),
                  ),
                ),
                if (_started && !_gameOver) ...[
                  // Blood splats – change infrequently
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size(_screenW, _screenH),
                      painter: _SplatPainter(_splats),
                    ),
                  ),
                  // All moving game objects in ONE painter (no per-zombie widgets)
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size(_screenW, _screenH),
                      painter: _ZombieGamePainter(
                        zombies:    _zombies,
                        bullets:    _bullets,
                        particles:  _particles,
                        locked:     _locked,
                        typed:      _typed,
                        baseX:      _baseX,
                        screenH:    _screenH,
                        turretAngle:_turretAngle,
                        baseHp:     _baseHp,
                        maxHp:      _cfg['hpMax'] as int,
                        pulse:      _pulseCtrl.value,
                        fontScale:  _fontScale,
                        uiScale:    _uiScale,
                      ),
                    ),
                  ),
                  // HUD (widget layer – changes only when stats change)
                  _buildHUD(),
                  // Typing bar
                  if (_typed.isNotEmpty || _locked != null)
                    _buildTypingBar(),
                  if (_frozen)         _buildFreezeOverlay(),
                  if (_waveAnnouncing) _buildWaveAnnounce(),
                ],
                if (!_started || _gameOver) _buildMenuOrOver(),
                if (_paused && _started && !_gameOver) _buildPauseScreen(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── HUD ─────────────────────────────────────────────────────────────────────
  Widget _buildHUD() {
    final comboMult = _combo >= 10 ? 3 : _combo >= 5 ? 2 : 1;
    final maxHp     = _cfg['hpMax'] as int;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
          ),
        ),
        child: Row(children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white60, size: 15),
            ),
          ),
          const SizedBox(width: 12),
          _ZHudChip('SCORE', '$_score', const Color(0xFFAAFF66)),
          const SizedBox(width: 10),
          _ZHudChip('BEST',  '$_highScore', const Color(0xFFFFD700)),
          const SizedBox(width: 10),
          _ZHudChip('WAVE',  '$_wave', const Color(0xFFFF6666)),
          const SizedBox(width: 10),
          _ZHudChip('KILLS', '$_kills', const Color(0xFFAA88FF)),
          const Spacer(),

          // Base HP bar
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              const Text('🏚 BASE', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
              const SizedBox(width: 6),
              SizedBox(
                width: 100, height: 10,
                child: Stack(children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (_baseHp / maxHp).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          _baseHp > maxHp * 0.5 ? const Color(0xFF88FF44) : const Color(0xFFFF8844),
                          _baseHp > maxHp * 0.5 ? const Color(0xFF44CC22) : const Color(0xFFFF4444),
                        ]),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [BoxShadow(
                          color: (_baseHp > maxHp * 0.5 ? Colors.green : Colors.red)
                              .withValues(alpha: 0.5),
                          blurRadius: 4,
                        )],
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 6),
              Text('$_baseHp/$maxHp', style: TextStyle(
                color: _baseHp <= 2 ? Colors.red : Colors.white70,
                fontSize: 11, fontWeight: FontWeight.bold,
              )),
            ]),
          ]),
          const SizedBox(width: 16),

          // Combo (only shown when active)
          if (_combo >= 3) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:  Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
                boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10)],
              ),
              child: Text(
                '${_combo}x COMBO${comboMult > 1 ? " (${comboMult}x pts)" : ""}',
                style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Freeze indicator
          if (_frozen) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF66FFEE).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF66FFEE).withValues(alpha: 0.6)),
              ),
              child: const Text('❄ FROZEN', style: TextStyle(
                color: Color(0xFF66FFEE), fontSize: 12, fontWeight: FontWeight.bold,
              )),
            ),
            const SizedBox(width: 10),
          ],

          // Pause
          GestureDetector(
            onTap: _togglePause,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pause, color: Colors.white60, size: 16),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Typing bar ──────────────────────────────────────────────────────────────
  Widget _buildTypingBar() {
    return Positioned(
      bottom: 14, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: (20 * _uiScale).clamp(14, 34),
            vertical:   (8  * _uiScale).clamp(6, 14),
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFAAFF66).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [BoxShadow(
              color: const Color(0xFFAAFF66).withValues(alpha: 0.18),
              blurRadius: 12,
            )],
          ),
          child: Text(
            _typed.isEmpty ? '...' : _typed,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: (16 * _fontScale).clamp(12, 24),
              color: const Color(0xFFAAFF66),
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5 * _fontScale,
              shadows: const [Shadow(color: Color(0xFFAAFF66), blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }

  // ── Freeze overlay ──────────────────────────────────────────────────────────
  Widget _buildFreezeOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: const Color(0xFF66FFEE).withValues(alpha: 0.06),
        ),
      ),
    );
  }

  // ── Wave announce ───────────────────────────────────────────────────────────
  Widget _buildWaveAnnounce() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, _) {
            final t = _waveCtrl.value;
            final alpha = (t < 0.2
                ? t / 0.2
                : t > 0.8
                ? (1 - t) / 0.2
                : 1.0).clamp(0.0, 1.0);
            return Center(
              child: Opacity(
                opacity: alpha,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('WAVE $_wave', style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: (52 * _fontScale).clamp(26, 54),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF4444),
                      letterSpacing: 6 * _fontScale,
                      shadows: const [
                        Shadow(color: Color(0xFFFF0000), blurRadius: 20),
                        Shadow(color: Color(0xFFFF0000), blurRadius: 40),
                      ],
                    )),
                    SizedBox(height: 6 * _uiScale),
                    const Text('INCOMING', style: TextStyle(
                      color: Colors.white54, fontSize: 16, letterSpacing: 8,
                    )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Menu / Game Over ────────────────────────────────────────────────────────
  Widget _buildMenuOrOver() {
    final isOver = _gameOver;
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isOver) ...[
                const Text('🧟', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 12),
                const Text('ZOMBIE SURVIVAL', style: TextStyle(
                  fontFamily: 'monospace', fontSize: 30, fontWeight: FontWeight.bold,
                  color: Color(0xFFAAFF66), letterSpacing: 4,
                  shadows: [Shadow(color: Color(0xFF44FF00), blurRadius: 16)],
                )),
                const SizedBox(height: 8),
                const Text('TYPE WORDS TO SHOOT ZOMBIES BEFORE THEY REACH YOUR BASE',
                  style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
              ] else ...[
                const Text('💀', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 12),
                const Text('BASE DESTROYED', style: TextStyle(
                  fontFamily: 'monospace', fontSize: 28, fontWeight: FontWeight.bold,
                  color: Color(0xFFFF4444), letterSpacing: 3,
                  shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 14)],
                )),
                const SizedBox(height: 20),
                _ZStatRow('SCORE',     '$_score'),
                _ZStatRow('BEST',      '$_highScore'),
                _ZStatRow('KILLS',     '$_kills'),
                _ZStatRow('MAX COMBO', '${_maxCombo}x'),
                _ZStatRow('WAVES',     '$_wave'),
              ],
              const SizedBox(height: 28),

              if (!isOver) ...[
                const Text('SELECT DIFFICULTY', style: TextStyle(
                  color: Colors.white30, fontSize: 11, letterSpacing: 3,
                )),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _zdiffBtn('EASY',   'Slow zombies\nShort words', ZombieDifficulty.easy,   const Color(0xFFAAFF66)),
                    const SizedBox(width: 12),
                    _zdiffBtn('MEDIUM', 'Med zombies\nMed words',   ZombieDifficulty.medium, const Color(0xFFFFD700)),
                    const SizedBox(width: 12),
                    _zdiffBtn('HARD',   'Fast zombies\nLong words', ZombieDifficulty.hard,   const Color(0xFFFF6666)),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(children: [
                    Text('HOW TO PLAY', style: TextStyle(
                      color: Colors.white30, fontSize: 10, letterSpacing: 3,
                    )),
                    SizedBox(height: 10),
                    _ZHowTo('🧟', 'Zombies walk left toward your base — type their word to shoot them'),
                    _ZHowTo('⌨',  'Each letter fires a bullet — finish the word to kill the zombie'),
                    _ZHowTo('❄',  'Type "freeze" on an ice zombie to freeze ALL zombies for 4 seconds'),
                    _ZHowTo('💣', 'Type "bomb" on a bomb zombie to clear all zombies on screen'),
                    _ZHowTo('❤',  'Base HP is reduced each time a zombie reaches it'),
                  ]),
                ),
                const SizedBox(height: 28),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isOver) ...[
                    _ZBtn('← MENU', Colors.white38, () => Navigator.pop(context)),
                    const SizedBox(width: 14),
                  ],
                  _ZBtn(isOver ? '▶ TRY AGAIN' : '▶ SURVIVE',
                      const Color(0xFFAAFF66), _startGame),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseScreen() {
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏸', style: TextStyle(fontSize: 46)),
            const SizedBox(height: 14),
            const Text('PAUSED', style: TextStyle(
              color: Colors.white, fontSize: 26,
              fontWeight: FontWeight.bold, letterSpacing: 6,
            )),
            const SizedBox(height: 30),
            _ZBtn('▶ RESUME', const Color(0xFFAAFF66), _togglePause),
            const SizedBox(height: 12),
            _ZBtn('← QUIT', Colors.white38, () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  // ── Difficulty button ───────────────────────────────────────────────────────
  Widget _zdiffBtn(String label, String sub, ZombieDifficulty d, Color col) {
    final sel = _difficulty == d;
    return GestureDetector(
      onTap: () {
        if (_difficulty == d) return;
        setState(() { _difficulty = d; });
        _rebuildConfig();
        _loadHs();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: sel ? col.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? col : Colors.white24, width: sel ? 2 : 1),
          boxShadow: sel ? [BoxShadow(color: col.withValues(alpha: 0.3), blurRadius: 12)] : null,
        ),
        child: Column(children: [
          Text(label, style: TextStyle(
            color: sel ? col : Colors.white54,
            fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1,
          )),
          const SizedBox(height: 5),
          Text(sub, textAlign: TextAlign.center, style: TextStyle(
            color: sel ? col.withValues(alpha: 0.8) : Colors.white30,
            fontSize: 10, height: 1.4,
          )),
          if (sel) ...[
            const SizedBox(height: 5),
            Icon(Icons.check_circle, color: col, size: 14),
          ],
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SINGLE UNIFIED GAME PAINTER
// Replaces: separate zombie widget stack, per-zombie AnimatedBuilders,
//           separate bullet painter, separate particle painter, base painter.
// One painter = one paint call per frame = minimal GPU overhead.
// ══════════════════════════════════════════════════════════════════════════════
class _ZombieGamePainter extends CustomPainter {
  final List<Zombie>    zombies;
  final List<ZBullet>   bullets;
  final List<ZParticle> particles;
  final Zombie?         locked;
  final String          typed;
  final double baseX, screenH, turretAngle;
  final int    baseHp, maxHp;
  final double pulse, fontScale, uiScale;

  _ZombieGamePainter({
    required this.zombies,
    required this.bullets,
    required this.particles,
    required this.locked,
    required this.typed,
    required this.baseX,
    required this.screenH,
    required this.turretAngle,
    required this.baseHp,
    required this.maxHp,
    required this.pulse,
    required this.fontScale,
    required this.uiScale,
  });

  // Reuse paint objects to avoid per-frame allocations
  static final _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    _drawBase(canvas, size);
    _drawParticles(canvas);
    _drawBullets(canvas);
    _drawZombies(canvas, size);
  }

  // ── Base ──────────────────────────────────────────────────────────────────
  void _drawBase(Canvas canvas, Size size) {
    final H = size.height;
    final bx = baseX;

    // Base platform
    _p
      ..color = const Color(0xFF1A2E1A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, H * 0.22, bx + 30, H * 0.6),
        const Radius.circular(6),
      ),
      _p,
    );

    // Wall detail
    _p.color = const Color(0xFF2A4A2A);
    for (double y = H * 0.25; y < H * 0.82; y += 24) {
      canvas.drawRect(Rect.fromLTWH(2, y, bx + 20, 2), _p);
    }

    // HP bar background
    const barW = 70.0;
    const barH = 8.0;
    final barX = bx * 0.5 - barW * 0.5;
    final barY = H * 0.18;
    _p.color = Colors.red.withValues(alpha: 0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(4)),
      _p,
    );
    final hpFrac = (baseHp / maxHp).clamp(0.0, 1.0);
    _p.color = hpFrac > 0.5 ? const Color(0xFF88FF44) : const Color(0xFFFF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW * hpFrac, barH), const Radius.circular(4)),
      _p,
    );

    // Turret barrel
    canvas.save();
    canvas.translate(bx + 38, H * 0.5);
    canvas.rotate(turretAngle);
    _p
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, const Offset(28, 0), _p);
    _p.style = PaintingStyle.fill;
    _p.color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset.zero, 14, _p);
    _p.color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset.zero, 10, _p);
    canvas.restore();
  }

  // ── Particles ─────────────────────────────────────────────────────────────
  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      _p
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))
        ..maskFilter = p.size > 4 ? const MaskFilter.blur(BlurStyle.normal, 3) : null
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, _p);
    }
    _p.maskFilter = null;
  }

  // ── Bullets ───────────────────────────────────────────────────────────────
  void _drawBullets(Canvas canvas) {
    for (final b in bullets) {
      // Glow
      _p
        ..color = b.color.withValues(alpha: b.opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(b.x, b.y), b.isFinal ? 9 : 5, _p);
      _p.maskFilter = null;
      // Core
      _p.color = b.color.withValues(alpha: b.opacity);
      canvas.drawCircle(Offset(b.x, b.y), b.isFinal ? 4 : 2.5, _p);
      // White centre
      _p.color = Colors.white.withValues(alpha: b.opacity * 0.9);
      canvas.drawCircle(Offset(b.x, b.y), b.isFinal ? 2 : 1.2, _p);
    }
  }

  // ── Zombies ───────────────────────────────────────────────────────────────
  void _drawZombies(Canvas canvas, Size size) {
    for (final z in zombies) {
      canvas.save();
      canvas.translate(z.x, z.y);
      if (z.dying) {
        canvas.scale(1.0 + z.deathAnim * 0.3, 1.0 - z.deathAnim * 0.3);
      }
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, z.opacity.clamp(0.0, 1.0)));
      _drawZombie(canvas, z, size);
      canvas.restore(); // saveLayer
      canvas.restore(); // translate
    }
  }

  void _drawZombie(Canvas canvas, Zombie z, Size size) {
    final walk = sin(z.walkCycle);
    final col  = z.skinColor;
    final isTargeted = z.targeted && !z.dying;
    final sz   = z.type == ZombieType.tank ? 1.35 : 1.0;

    // Glow for targeted / special types
    if (isTargeted || z.type == ZombieType.freeze || z.type == ZombieType.bomb) {
      _p
        ..color = z.wordColor.withValues(alpha: isTargeted ? 0.35 : 0.2 + pulse * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(0, -20 * sz), 20 * sz, _p);
      _p.maskFilter = null;
    }

    // Shadow
    _p
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 10 * sz), width: 30 * sz, height: 8), _p);
    _p.maskFilter = null;

    // Legs
    _p
      ..color = const Color(0xFF212121)
      ..strokeWidth = (5 * sz)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-5 * sz, 8 * sz), Offset(-9 * sz + walk * 6,  22 * sz), _p);
    canvas.drawLine(Offset( 5 * sz, 8 * sz), Offset( 9 * sz - walk * 6,  22 * sz), _p);

    // Body
    _p
      ..color = col.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final bodyPath = Path()
      ..moveTo(-12 * sz, -8 * sz)
      ..lineTo(-11 * sz,  8 * sz)
      ..lineTo( 11 * sz,  8 * sz)
      ..lineTo( 12 * sz, -8 * sz)
      ..close();
    canvas.drawPath(bodyPath, _p);

    // Arms
    _p
      ..color = col
      ..strokeWidth = (4 * sz)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Outstretched zombie arms (classic zombie pose)
    canvas.drawLine(Offset(-12 * sz, -2 * sz), Offset(-24 * sz - walk * 4, -8 * sz + walk * 3), _p);
    canvas.drawLine(Offset( 12 * sz, -2 * sz), Offset( 24 * sz + walk * 4, -8 * sz - walk * 3), _p);

    // Head
    _p
      ..color = col.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -20 * sz), 12 * sz, _p);

    // Eyes
    _p.color = z.type == ZombieType.freeze
        ? const Color(0xFF66FFEE)
        : z.type == ZombieType.bomb
        ? const Color(0xFFFFCC44)
        : const Color(0xFFFF4444);
    canvas.drawCircle(Offset(-4 * sz, -22 * sz), 3 * sz, _p);
    canvas.drawCircle(Offset( 4 * sz, -22 * sz), 3 * sz, _p);

    // Word bubble
    _drawWordBubble(canvas, z, sz);
  }

  void _drawWordBubble(Canvas canvas, Zombie z, double sz) {
    final word       = z.word;
    final typedSoFar = (z == locked) ? typed : '';
    final isTargeted = z.targeted && !z.dying;
    final bubbleY    = -42.0 * sz;
    final wordW      = word.length * 9.0 + 16;

    // Background
    _p
      ..color = Colors.black.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, bubbleY), width: wordW, height: 18),
        const Radius.circular(5),
      ),
      _p,
    );
    if (isTargeted) {
      _p
        ..color = z.wordColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, bubbleY), width: wordW, height: 18),
          const Radius.circular(5),
        ),
        _p,
      );
      _p.style = PaintingStyle.fill;
    }

    // Power-up prefix icon
    String prefix = '';
    if (z.type == ZombieType.freeze) prefix = '❄ ';
    if (z.type == ZombieType.bomb)   prefix = '💣 ';

    double xOff = -wordW / 2 + 8;

    if (prefix.isNotEmpty) {
      final tp = _makeTP(prefix, 11, Colors.white.withValues(alpha: 0.85));
      tp.paint(canvas, Offset(xOff, bubbleY - tp.height / 2));
      xOff += tp.width;
    }

    for (int i = 0; i < word.length; i++) {
      final done = i < typedSoFar.length;
      final cur  = i == typedSoFar.length && typedSoFar.isNotEmpty;
      final color = done
          ? z.wordColor.withValues(alpha: 0.35)
          : cur
          ? z.wordColor
          : Colors.white.withValues(alpha: 0.9);

      if (cur) {
        _p.color = z.wordColor.withValues(alpha: 0.18);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(xOff - 1, bubbleY - 7, 10, 14),
            const Radius.circular(2),
          ),
          _p,
        );
      }

      final tp = _makeTP(word[i], 12, color, bold: true, strikethrough: done);
      tp.paint(canvas, Offset(xOff, bubbleY - tp.height / 2));
      xOff += tp.width;
    }
  }

  TextPainter _makeTP(String text, double size, Color color, {
    bool bold = false, bool strikethrough = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          decoration: strikethrough ? TextDecoration.lineThrough : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  @override
  bool shouldRepaint(_ZombieGamePainter o) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
// BACKGROUND PAINTER  (static – never repaints)
// ══════════════════════════════════════════════════════════════════════════════
class _ZombieBackgroundPainter extends CustomPainter {
  final double screenW, screenH;
  _ZombieBackgroundPainter(this.screenW, this.screenH);

  // Cached gradient shader – rebuilt only when size changes
  static Shader? _cachedBgShader;
  static Size    _cachedSize = Size.zero;

  @override
  void paint(Canvas canvas, Size size) {
    // Rebuild gradient only when the canvas size changes
    if (size != _cachedSize) {
      _cachedBgShader = const LinearGradient(
        begin: Alignment.topCenter,
        end:   Alignment.bottomCenter,
        colors: [Color(0xFF0D1A0A), Color(0xFF1A2E10), Color(0xFF0A1208)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      _cachedSize = size;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = _cachedBgShader,
    );

    final groundY = size.height * 0.85;
    final p = Paint();

    // Ground
    p.color = const Color(0xFF0A1A06);
    canvas.drawRect(Rect.fromLTRB(0, groundY, size.width, size.height), p);

    // Ground line
    p
      ..color = const Color(0xFF2A4A1A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), p);

    // Distant trees silhouette
    p
      ..color = const Color(0xFF0A1208)
      ..style = PaintingStyle.fill;
    final rng = Random(42);
    for (double x = 40; x < size.width; x += 55 + rng.nextDouble() * 30) {
      final h = 60 + rng.nextDouble() * 80;
      final w = 18 + rng.nextDouble() * 22;
      final path = Path()
        ..moveTo(x, groundY)
        ..lineTo(x - w * 0.5, groundY - h * 0.45)
        ..lineTo(x - w * 0.3, groundY - h * 0.45)
        ..lineTo(x - w * 0.4, groundY - h * 0.7)
        ..lineTo(x - w * 0.2, groundY - h * 0.7)
        ..lineTo(x,            groundY - h)
        ..lineTo(x + w * 0.2, groundY - h * 0.7)
        ..lineTo(x + w * 0.4, groundY - h * 0.7)
        ..lineTo(x + w * 0.3, groundY - h * 0.45)
        ..lineTo(x + w * 0.5, groundY - h * 0.45)
        ..close();
      canvas.drawPath(path, p);
    }

    // Lane dividers (subtle)
    p
      ..color = const Color(0xFF1A2E14).withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final ly in [size.height * 0.28, size.height * 0.52, size.height * 0.76]) {
      canvas.drawLine(Offset(0, ly + 18), Offset(size.width, ly + 18), p);
    }
  }

  @override
  bool shouldRepaint(_ZombieBackgroundPainter o) =>
      o.screenW != screenW || o.screenH != screenH;
}

// ══════════════════════════════════════════════════════════════════════════════
// SPLAT PAINTER
// ══════════════════════════════════════════════════════════════════════════════
class _SplatPainter extends CustomPainter {
  final List<BloodSplat> splats;
  _SplatPainter(this.splats);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in splats) {
      p.color = const Color(0xFF4A0000).withValues(alpha: s.opacity);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(s.x, s.y), width: s.radius * 2, height: s.radius),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_SplatPainter o) => o.splats != splats || o.splats.length != splats.length;
}

// ══════════════════════════════════════════════════════════════════════════════
// SMALL UI WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class _ZHudChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ZHudChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, letterSpacing: 1.5)),
        Text(value, style: TextStyle(
          color: color, fontSize: 14, fontWeight: FontWeight.bold,
          shadows: [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
        )),
      ],
    ),
  );
}

class _ZStatRow extends StatelessWidget {
  final String label, value;
  const _ZStatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 120, child: Text(label,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2))),
        const SizedBox(width: 16),
        SizedBox(width: 80, child: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
      ],
    ),
  );
}

class _ZHowTo extends StatelessWidget {
  final String icon, text;
  const _ZHowTo(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12))),
    ]),
  );
}

class _ZBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ZBtn(this.label, this.color, this.onTap);

  @override
  State<_ZBtn> createState() => _ZBtnState();
}

class _ZBtnState extends State<_ZBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered ? widget.color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.color, width: 1.5),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 16)]
              : null,
        ),
        child: Text(widget.label, style: TextStyle(
          color: widget.color, fontSize: 14,
          fontWeight: FontWeight.bold, letterSpacing: 2,
          shadows: _hovered ? [Shadow(color: widget.color, blurRadius: 8)] : null,
        )),
      ),
    ),
  );
}
