import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/sound_service.dart';
import '../../services/profile_service.dart';

// ── Word banks ────────────────────────────────────────────────────────────────
const _kEasyWords = [
  'cat',
  'dog',
  'run',
  'sun',
  'hat',
  'cup',
  'pen',
  'box',
  'red',
  'sky',
  'ant',
  'egg',
  'ice',
  'owl',
  'rat',
  'arm',
  'fan',
  'fog',
  'gem',
  'hen',
  'jaw',
  'lip',
  'nap',
  'pay',
  'dig',
  'log',
  'mud',
  'rot',
  'sap',
  'web',
  'zap',
  'claw',
  'dead',
  'doom',
  'gore',
  'howl',
  'lurch',
  'moan',
];
const _kMedWords = [
  'brain',
  'flesh',
  'groan',
  'horde',
  'swarm',
  'curse',
  'crypt',
  'blood',
  'crawl',
  'decay',
  'grave',
  'haunt',
  'lurk',
  'night',
  'panic',
  'scream',
  'stalk',
  'undead',
  'vault',
  'waste',
  'apple',
  'table',
  'chair',
  'house',
  'water',
  'light',
  'plant',
  'river',
  'stone',
  'cloud',
  'music',
  'dance',
  'sleep',
  'dream',
  'smile',
  'happy',
  'smart',
  'great',
  'world',
  'focus',
];
const _kHardWords = [
  'nightmare',
  'infection',
  'outbreak',
  'shambling',
  'graveyard',
  'relentless',
  'survivor',
  'barricade',
  'apocalypse',
  'desperate',
  'eliminate',
  'devastate',
  'overwhelm',
  'catastrophe',
  'unstoppable',
  'dangerous',
  'terrifying',
  'bloodthirsty',
  'merciless',
  'destruction',
];
const _kPowerFreeze = 'freeze';
const _kPowerBomb = 'bomb';

enum ZombieDifficulty { easy, medium, hard }

// ── Zombie model ──────────────────────────────────────────────────────────────
class Zombie {
  final String id;
  final String word;
  double x; // pixels from left
  double y; // center-y (lane)
  double speed; // px/sec (positive = moving left)
  final Color skinColor;
  final Color wordColor;
  bool targeted;
  bool dying;
  double opacity;
  double deathAnim; // 0→1
  final ZombieType type;
  final int lane; // 0,1,2 — top/mid/bottom

  // Walk animation
  double walkCycle; // 0→2π, drives limb positions

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
    this.targeted = false,
    this.dying = false,
    this.opacity = 1.0,
    this.deathAnim = 0.0,
    this.walkCycle = 0.0,
  });
}

enum ZombieType { normal, fast, tank, freeze, bomb }

// ── Bullet ────────────────────────────────────────────────────────────────────
class ZBullet {
  double x, y;
  final double vx, vy;
  final double destX, destY;
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
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    this.life = 1.0,
  });
}

// ── Blood splat (persistent ground stain) ────────────────────────────────────
class BloodSplat {
  final double x, y, radius;
  final double opacity;
  BloodSplat({
    required this.x,
    required this.y,
    required this.radius,
    this.opacity = 0.4,
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
  // ── State ─────────────────────────────────────────────────────────────────
  ZombieDifficulty _difficulty = ZombieDifficulty.easy;
  bool _started = false, _gameOver = false, _paused = false;
  bool _waveAnnouncing = false;

  int _score = 0, _highScore = 0, _wave = 1, _kills = 0;
  int _baseHp = 10, _combo = 0, _maxCombo = 0;

  // ── Freeze power-up ───────────────────────────────────────────────────────
  bool _frozen = false;
  Timer? _freezeTimer;

  // ── Objects ───────────────────────────────────────────────────────────────
  final List<Zombie> _zombies = [];
  final List<ZBullet> _bullets = [];
  final List<ZParticle> _particles = [];
  final List<BloodSplat> _splats = [];
  final _rng = Random();

  // ── Typing ────────────────────────────────────────────────────────────────
  String _typed = '';
  Zombie? _locked;

  // ── Turret ────────────────────────────────────────────────────────────────
  double _turretAngle = 0.0; // radians, 0=right
  double _turretTargetAngle = 0.0;

  // ── Timers ────────────────────────────────────────────────────────────────
  Timer? _gameLoop, _spawnTimer;
  DateTime? _lastFrame;

  // ── Animations ───────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  // ── Layout ────────────────────────────────────────────────────────────────
  double _screenW = 900, _screenH = 600;
  static const double _baseX = 90.0;

  final FocusNode _focus = FocusNode();

  // ── Lane Y positions (set in build from screen height) ───────────────────
  List<double> get _laneY => [
    _screenH * 0.28,
    _screenH * 0.52,
    _screenH * 0.76,
  ];

  // ── Config per difficulty ─────────────────────────────────────────────────
  Map<String, dynamic> get _cfg => {
    ZombieDifficulty.easy: {
      'spawnMs': 3500,
      'speedMin': 28.0,
      'speedMax': 50.0,
      'max': 4,
      'hpMax': 10,
    },
    ZombieDifficulty.medium: {
      'spawnMs': 2400,
      'speedMin': 48.0,
      'speedMax': 85.0,
      'max': 7,
      'hpMax': 8,
    },
    ZombieDifficulty.hard: {
      'spawnMs': 1500,
      'speedMin': 75.0,
      'speedMax': 130.0,
      'max': 10,
      'hpMax': 6,
    },
  }[_difficulty]!;

  List<String> get _wordBank => {
    ZombieDifficulty.easy: _kEasyWords,
    ZombieDifficulty.medium: _kMedWords,
    ZombieDifficulty.hard: _kHardWords,
  }[_difficulty]!;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
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

  Future<void> _loadHs() async {
    final p = await SharedPreferences.getInstance();
    final k = '${ProfileService().keyPrefix}zombie_hs_${_difficulty.name}';
    setState(() => _highScore = p.getInt(k) ?? 0);
  }

  Future<void> _saveHs() async {
    if (_score <= _highScore) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(
      '${ProfileService().keyPrefix}zombie_hs_${_difficulty.name}',
      _score,
    );
    setState(() => _highScore = _score);
  }

  // ── Start ─────────────────────────────────────────────────────────────────
  void _startGame() {
    setState(() {
      _started = true;
      _gameOver = false;
      _paused = false;
      _score = 0;
      _wave = 1;
      _kills = 0;
      _combo = 0;
      _maxCombo = 0;
      _baseHp = _cfg['hpMax'] as int;
      _typed = '';
      _locked = null;
      _frozen = false;
      _zombies.clear();
      _bullets.clear();
      _particles.clear();
      _splats.clear();
      _turretAngle = 0;
      _turretTargetAngle = 0;
    });
    _lastFrame = DateTime.now();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _tick);
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

  // ── Wave system ───────────────────────────────────────────────────────────
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
    // Wave multiplier: speed/density increases with wave number
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
    // Advance wave every 8 kills
    if (_kills > 0 && _kills % 8 == 0) {
      final expectedWave = (_kills ~/ 8) + 1;
      if (expectedWave > _wave) {
        _wave = expectedWave;
        _announceWave();
      }
    }
  }

  // ── Spawn zombie ──────────────────────────────────────────────────────────
  void _spawnZombie() {
    final maxOnScreen = _cfg['max'] as int;
    if (_zombies.where((z) => !z.dying).length >= maxOnScreen) return;

    // Pick lane — prefer lane with fewest zombies
    final laneCounts = [0, 1, 2]
        .map((l) => _zombies.where((z) => z.lane == l && !z.dying).length)
        .toList();
    final lane = laneCounts.indexOf(laneCounts.reduce(min));

    // Pick word — avoid same first letter as existing untargeted zombies
    final usedFirst = _zombies
        .where((z) => !z.dying && !z.targeted)
        .map((z) => z.word[0].toLowerCase())
        .toSet();

    // Power-up spawn chance
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

    // Wave speed bonus
    speed *= (1.0 + _wave * 0.05);

    final skinColor = _zombieColor(type);
    final wordColor = _wordColor(type);
    final y = _laneY[lane] + _rng.nextDouble() * 20 - 10;

    _zombies.add(
      Zombie(
        id: '${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(9999)}',
        word: word,
        x: _screenW + 60,
        y: y,
        speed: speed,
        skinColor: skinColor,
        wordColor: wordColor,
        lane: lane,
        type: type,
        walkCycle: _rng.nextDouble() * 2 * pi,
      ),
    );
  }

  String _pickWord(Set<String> usedFirst, {List<String>? fromBank}) {
    final bank = fromBank ?? _wordBank;
    final avail = bank
        .where((w) => !usedFirst.contains(w[0].toLowerCase()))
        .toList();
    final pool = avail.isNotEmpty ? avail : bank;
    return pool[_rng.nextInt(pool.length)];
  }

  Color _zombieColor(ZombieType t) => {
    ZombieType.normal: const Color(0xFF6B8C3E),
    ZombieType.fast: const Color(0xFF3E7A8C),
    ZombieType.tank: const Color(0xFF8C3E3E),
    ZombieType.freeze: const Color(0xFF3E8C7A),
    ZombieType.bomb: const Color(0xFF8C6B3E),
  }[t]!;

  Color _wordColor(ZombieType t) => {
    ZombieType.normal: const Color(0xFFAAFF66),
    ZombieType.fast: const Color(0xFF66DDFF),
    ZombieType.tank: const Color(0xFFFF6666),
    ZombieType.freeze: const Color(0xFF66FFEE),
    ZombieType.bomb: const Color(0xFFFFCC44),
  }[t]!;

  // ── Game tick ─────────────────────────────────────────────────────────────
  void _tick(Timer t) {
    if (_paused || _gameOver || !_started) return;

    final now = DateTime.now();
    final dt = _lastFrame == null
        ? 0.016
        : now.difference(_lastFrame!).inMilliseconds / 1000.0;
    _lastFrame = now;
    final safeDt = dt.clamp(0.0, 0.05);

    setState(() {
      // Move zombies
      for (final z in _zombies) {
        if (z.dying) {
          z.deathAnim += safeDt * 2.5;
          z.opacity = (1.0 - z.deathAnim).clamp(0, 1);
        } else {
          z.walkCycle += safeDt * (z.speed / 30) * pi;
          if (!_frozen) z.x -= z.speed * safeDt;
        }
      }

      // Move bullets
      for (final b in List.from(_bullets)) {
        b.x += b.vx * safeDt;
        b.y += b.vy * safeDt;
        if (b.arrived) {
          _onBulletHit(b);
          _bullets.remove(b);
        }
      }

      // Update particles
      for (final p in _particles) {
        p.life -= safeDt * 2.0;
        p.x += p.vx * safeDt;
        p.y += p.vy * safeDt;
        p.vy += 120 * safeDt;
      }

      // Smooth turret rotation
      final diff = _turretTargetAngle - _turretAngle;
      _turretAngle += diff * (safeDt * 10).clamp(0, 1);

      // Remove dead
      _zombies.removeWhere((z) => z.dying && z.opacity <= 0);
      _particles.removeWhere((p) => p.life <= 0);
      if (_splats.length > 30) _splats.removeRange(0, _splats.length - 30);

      // Check base reach
      for (final z in List.from(_zombies)) {
        if (!z.dying && z.x <= _baseX + 20) {
          _zombieReachedBase(z);
        }
      }
    });
  }

  void _zombieReachedBase(Zombie z) {
    _zombies.remove(z);
    if (_locked == z) {
      _locked = null;
      _typed = '';
    }
    _baseHp--;
    _combo = 0;
    SoundService().playError();

    // Base damage particles
    _spawnParticles(
      _baseX + 20,
      _screenH * 0.5,
      const Color(0xFFFF4444),
      count: 12,
      spread: 100,
    );

    if (_baseHp <= 0) _endGame();
  }

  // ── Bullet system ─────────────────────────────────────────────────────────
  void _fireBullet(Zombie target, {bool isFinal = false}) {
    final tx = target.x;
    final ty = target.y - 10;
    final sx = _baseX + 40.0;
    final sy = _screenH * 0.5;

    final dx = tx - sx;
    final dy = ty - sy;
    final dist = sqrt(dx * dx + dy * dy);
    const speed = 800.0;
    final vx = (dx / dist) * speed;
    final vy = (dy / dist) * speed;

    Color col;
    if (target.type == ZombieType.freeze) {
      col = const Color(0xFF66FFEE);
    } else if (target.type == ZombieType.bomb) {
      col = const Color(0xFFFFCC44);
    } else if (isFinal) {
      col = Colors.white;
    } else {
      col = const Color(0xFF88FF44);
    }

    _bullets.add(
      ZBullet(
        x: sx,
        y: sy,
        vx: vx,
        vy: vy,
        destX: tx,
        destY: ty,
        color: col,
        zombieId: target.id,
        isFinal: isFinal,
      ),
    );

    // Aim turret
    _turretTargetAngle = atan2(dy, dx);
  }

  void _onBulletHit(ZBullet b) {
    final z = _zombies.where((z) => z.id == b.zombieId && !z.dying).firstOrNull;
    if (z == null) return;

    if (b.isFinal) {
      // Kill zombie
      z.dying = true;
      _spawnParticles(b.destX, b.destY, z.skinColor, count: 18);
      _splats.add(
        BloodSplat(
          x: z.x,
          y: z.y + 20,
          radius: 15 + _rng.nextDouble() * 12,
          opacity: 0.35 + _rng.nextDouble() * 0.2,
        ),
      );

      // Power-up effects
      if (z.type == ZombieType.freeze) _activateFreeze();
      if (z.type == ZombieType.bomb) _activateBomb();

      _kills++;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      final comboMult = _combo >= 10
          ? 3
          : _combo >= 5
          ? 2
          : 1;
      final diffMult = _difficulty == ZombieDifficulty.hard
          ? 3
          : _difficulty == ZombieDifficulty.medium
          ? 2
          : 1;
      _score += z.word.length * 10 * comboMult * diffMult;

      for (final zz in _zombies) {
        zz.targeted = false;
      }
      _locked = null;
      _typed = '';

      SoundService().playStreak();
      _checkWaveAdvance();
    } else {
      // Hit spark
      _spawnParticles(
        b.destX,
        b.destY,
        b.color,
        count: 4,
        spread: 50,
        life: 0.4,
      );
    }
  }

  void _activateFreeze() {
    _frozen = true;
    _freezeTimer?.cancel();
    _freezeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _frozen = false);
    });
    // Freeze flash particles on all zombies
    for (final z in _zombies) {
      if (!z.dying) {
        _spawnParticles(z.x, z.y, const Color(0xFF66FFEE), count: 6);
      }
    }
  }

  void _activateBomb() {
    // Kill all non-special zombies on screen
    for (final z in List.from(_zombies)) {
      if (!z.dying && z.type == ZombieType.normal ||
          z.type == ZombieType.fast) {
        z.dying = true;
        _kills++;
        _score += 5;
        _spawnParticles(z.x, z.y, z.skinColor, count: 12);
        _splats.add(BloodSplat(x: z.x, y: z.y + 20, radius: 18));
      }
    }
    SoundService().playLevelComplete();
  }

  void _spawnParticles(
    double x,
    double y,
    Color col, {
    int count = 12,
    double spread = 160,
    double life = 1.0,
  }) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final s = 20 + _rng.nextDouble() * spread;
      _particles.add(
        ZParticle(
          x: x,
          y: y,
          vx: cos(a) * s,
          vy: sin(a) * s - 60,
          color: i % 3 == 0 ? Colors.white70 : col,
          size: 2 + _rng.nextDouble() * 4,
          life: life * (0.6 + _rng.nextDouble() * 0.4),
        ),
      );
    }
  }

  // ── Key handler ───────────────────────────────────────────────────────────
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
        _typed = '';
        for (final z in _zombies) {
          if (!z.dying &&
              z.word.toLowerCase().startsWith(char!.toLowerCase())) {
            _locked = z;
            z.targeted = true;
            // Point turret
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

      final z = _locked!;
      final expected = z.word[_typed.length];

      if (char!.toLowerCase() == expected.toLowerCase()) {
        _typed += char;
        SoundService().playKeyClick();
        final isLast = _typed.length >= z.word.length;
        _fireBullet(z, isFinal: isLast);
        if (isLast) {
          // Final word handled by _onBulletHit
        }
      } else {
        SoundService().playError();
        _combo = 0;
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
                // Background
                _buildBackground(),
                if (_started && !_gameOver) ...[
                  _buildSplats(),
                  _buildZombies(),
                  _buildBullets(),
                  _buildParticles(),
                  _buildBase(),
                  _buildHUD(),
                  _buildTypingBar(),
                  if (_frozen) _buildFreezeOverlay(),
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

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return CustomPaint(
      size: Size(_screenW, _screenH),
      painter: _ZombieBackgroundPainter(_screenW, _screenH),
    );
  }

  // ── Blood splats ──────────────────────────────────────────────────────────
  Widget _buildSplats() {
    return CustomPaint(
      size: Size(_screenW, _screenH),
      painter: _SplatPainter(_splats),
    );
  }

  // ── Zombies ───────────────────────────────────────────────────────────────
  Widget _buildZombies() {
    return Stack(
      children: _zombies.map((z) {
        final typed = z == _locked ? _typed : '';
        return Positioned(
          left: z.x - 45,
          top: z.y - 70,
          child: Opacity(
            opacity: z.opacity.clamp(0, 1),
            child: SizedBox(
              width: 90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zombie body
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, _) => CustomPaint(
                      size: const Size(90, 100),
                      painter: _ZombiePainter(z, _pulseCtrl.value),
                    ),
                  ),
                  // Word label
                  const SizedBox(height: 4),
                  _buildWordLabel(z, typed),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWordLabel(Zombie z, String typed) {
    final isFreezeOrBomb =
        z.type == ZombieType.freeze || z.type == ZombieType.bomb;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: z.targeted
                ? z.wordColor
                : isFreezeOrBomb
                ? z.wordColor.withValues(alpha: 0.6 + _pulseCtrl.value * 0.4)
                : z.wordColor.withValues(alpha: 0.4),
            width: z.targeted ? 2 : (isFreezeOrBomb ? 1.5 : 1),
          ),
          boxShadow: z.targeted || isFreezeOrBomb
              ? [
                  BoxShadow(
                    color: z.wordColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: _buildWordRich(z.word, typed, z.wordColor, z.type),
      ),
    );
  }

  Widget _buildWordRich(String word, String typed, Color col, ZombieType type) {
    final prefix = type == ZombieType.freeze
        ? '❄ '
        : type == ZombieType.bomb
        ? '💣 '
        : '';
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          if (prefix.isNotEmpty)
            TextSpan(text: prefix, style: const TextStyle(fontSize: 12)),
          ...List.generate(word.length, (i) {
            final done = i < typed.length;
            final cur = i == typed.length;
            Color c = done
                ? col.withValues(alpha: 0.35)
                : cur
                ? col
                : Colors.white.withValues(alpha: 0.85);
            Color? bg = cur && typed.isNotEmpty
                ? col.withValues(alpha: 0.15)
                : null;
            return WidgetSpan(
              child: Container(
                decoration: bg != null
                    ? BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(2),
                      )
                    : null,
                child: Text(
                  word[i],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: col,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Bullets ───────────────────────────────────────────────────────────────
  Widget _buildBullets() {
    return CustomPaint(
      size: Size(_screenW, _screenH),
      painter: _ZBulletPainter(_bullets),
    );
  }

  // ── Particles ─────────────────────────────────────────────────────────────
  Widget _buildParticles() {
    return CustomPaint(
      size: Size(_screenW, _screenH),
      painter: _ZParticlePainter(_particles),
    );
  }

  // ── Base (left side fortification + turret) ───────────────────────────────
  Widget _buildBase() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) => CustomPaint(
        size: Size(_screenW, _screenH),
        painter: _BasePainter(
          baseX: _baseX,
          screenH: _screenH,
          hp: _baseHp,
          maxHp: _cfg['hpMax'] as int,
          turretAngle: _turretAngle,
          pulse: _pulseCtrl.value,
        ),
      ),
    );
  }

  // ── HUD ───────────────────────────────────────────────────────────────────
  Widget _buildHUD() {
    final comboMult = _combo >= 10
        ? 3
        : _combo >= 5
        ? 2
        : 1;
    final maxHp = _cfg['hpMax'] as int;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Back
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white60,
                  size: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),

            _ZHudChip('SCORE', '$_score', const Color(0xFFAAFF66)),
            const SizedBox(width: 10),
            _ZHudChip('BEST', '$_highScore', const Color(0xFFFFD700)),
            const SizedBox(width: 10),
            _ZHudChip('WAVE', '$_wave', const Color(0xFFFF6666)),
            const SizedBox(width: 10),
            _ZHudChip('KILLS', '$_kills', const Color(0xFFAA88FF)),

            const Spacer(),

            // Base HP bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Text(
                      '🏚 BASE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 100,
                      height: 10,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (_baseHp / maxHp).clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _baseHp > maxHp * 0.5
                                        ? const Color(0xFF88FF44)
                                        : const Color(0xFFFF8844),
                                    _baseHp > maxHp * 0.5
                                        ? const Color(0xFF44CC22)
                                        : const Color(0xFFFF4444),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (_baseHp > maxHp * 0.5
                                                ? Colors.green
                                                : Colors.red)
                                            .withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_baseHp/$maxHp',
                      style: TextStyle(
                        color: _baseHp <= 2 ? Colors.red : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Combo
            if (_combo >= 3)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(
                      alpha: 0.08 + _pulseCtrl.value * 0.08,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withValues(
                        alpha: 0.5 + _pulseCtrl.value * 0.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    '${_combo}x COMBO${comboMult > 1 ? " (${comboMult}x pts)" : ""}',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.orange.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(width: 14),

            // Freeze indicator
            if (_frozen)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF66FFEE).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF66FFEE).withValues(alpha: 0.6),
                  ),
                ),
                child: const Text(
                  '❄ FROZEN',
                  style: TextStyle(
                    color: Color(0xFF66FFEE),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(width: 10),
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
          ],
        ),
      ),
    );
  }

  // ── Typing bar ────────────────────────────────────────────────────────────
  Widget _buildTypingBar() {
    if (_typed.isEmpty && _locked == null) return const SizedBox();
    return Positioned(
      bottom: 14,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(
                  0xFFAAFF66,
                ).withValues(alpha: 0.35 + _pulseCtrl.value * 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAAFF66).withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              _typed.isEmpty ? '...' : _typed,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                color: Color(0xFFAAFF66),
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                shadows: [Shadow(color: Color(0xFFAAFF66), blurRadius: 8)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Freeze overlay ────────────────────────────────────────────────────────
  Widget _buildFreezeOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) => Container(
            color: const Color(
              0xFF66FFEE,
            ).withValues(alpha: 0.04 + _pulseCtrl.value * 0.03),
          ),
        ),
      ),
    );
  }

  // ── Wave announce ─────────────────────────────────────────────────────────
  Widget _buildWaveAnnounce() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, _) {
            final t = _waveCtrl.value;
            final alpha = t < 0.2
                ? t / 0.2
                : t > 0.8
                ? (1 - t) / 0.2
                : 1.0;
            return Center(
              child: Opacity(
                opacity: alpha.clamp(0, 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'WAVE $_wave',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF4444),
                        letterSpacing: 6,
                        shadows: [
                          Shadow(color: Color(0xFFFF0000), blurRadius: 20),
                          Shadow(color: Color(0xFFFF0000), blurRadius: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'INCOMING',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Menu / Game Over ──────────────────────────────────────────────────────
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
                const Text(
                  'ZOMBIE SURVIVAL',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAAFF66),
                    letterSpacing: 4,
                    shadows: [Shadow(color: Color(0xFF44FF00), blurRadius: 16)],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TYPE WORDS TO SHOOT ZOMBIES BEFORE THEY REACH YOUR BASE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ] else ...[
                const Text('💀', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 12),
                const Text(
                  'BASE DESTROYED',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF4444),
                    letterSpacing: 3,
                    shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 14)],
                  ),
                ),
                const SizedBox(height: 20),
                _ZStatRow('SCORE', '$_score'),
                _ZStatRow('BEST', '$_highScore'),
                _ZStatRow('KILLS', '$_kills'),
                _ZStatRow('MAX COMBO', '${_maxCombo}x'),
                _ZStatRow('WAVES', '$_wave'),
              ],
              const SizedBox(height: 28),

              // Difficulty
              if (!isOver) ...[
                const Text(
                  'SELECT DIFFICULTY',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _zdiffBtn(
                      'EASY',
                      'Slow zombies\nShort words',
                      ZombieDifficulty.easy,
                      const Color(0xFFAAFF66),
                    ),
                    const SizedBox(width: 12),
                    _zdiffBtn(
                      'MEDIUM',
                      'Med zombies\nMed words',
                      ZombieDifficulty.medium,
                      const Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 12),
                    _zdiffBtn(
                      'HARD',
                      'Fast zombies\nLong words',
                      ZombieDifficulty.hard,
                      const Color(0xFFFF6666),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // How to play
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: const [
                      Text(
                        'HOW TO PLAY',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          letterSpacing: 3,
                        ),
                      ),
                      SizedBox(height: 10),
                      _ZHowTo(
                        '🧟',
                        'Zombies walk left toward your base — type their word to shoot them',
                      ),
                      _ZHowTo(
                        '⌨',
                        'Each letter fires a bullet — finish the word to kill the zombie',
                      ),
                      _ZHowTo(
                        '❄',
                        'Type "freeze" on an ice zombie to freeze ALL zombies for 4 seconds',
                      ),
                      _ZHowTo(
                        '💣',
                        'Type "bomb" on a bomb zombie to clear all zombies on screen',
                      ),
                      _ZHowTo(
                        '❤',
                        'Base HP is reduced each time a zombie reaches it — don\'t let them through!',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isOver) ...[
                    _ZBtn(
                      '← MENU',
                      Colors.white38,
                      () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                  ],
                  _ZBtn(
                    isOver ? '▶ TRY AGAIN' : '▶ SURVIVE',
                    const Color(0xFFAAFF66),
                    _startGame,
                  ),
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
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 30),
            _ZBtn('▶ RESUME', const Color(0xFFAAFF66), _togglePause),
            const SizedBox(height: 12),
            _ZBtn('← QUIT', Colors.white38, () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  // ── Difficulty selector helpers ───────────────────────────────────────────
  Widget _zdiffBtn(String label, String sub, ZombieDifficulty d, Color col) {
    final sel = _difficulty == d;
    return GestureDetector(
      onTap: () => setState(() {
        _difficulty = d;
        _loadHs();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: sel ? col.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? col : Colors.white24,
            width: sel ? 2 : 1,
          ),
          boxShadow: sel
              ? [BoxShadow(color: col.withValues(alpha: 0.3), blurRadius: 12)]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: sel ? col : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: sel ? col.withValues(alpha: 0.8) : Colors.white30,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            if (sel) ...[
              const SizedBox(height: 5),
              Icon(Icons.check_circle, color: col, size: 13),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Custom painters
// ═════════════════════════════════════════════════════════════════════════════

class _ZombieBackgroundPainter extends CustomPainter {
  final double w, h;
  _ZombieBackgroundPainter(this.w, this.h);

  @override
  void paint(Canvas canvas, Size size) {
    // Dark sky gradient
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF0D1A0A), Color(0xFF1A2A12), Color(0xFF0A1208)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // Moon
    final moon = Paint()
      ..color = const Color(0xFFEEE8AA).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(w * 0.85, h * 0.12), 28, moon);
    final moonCore = Paint()
      ..color = const Color(0xFFFFF8DC).withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.85, h * 0.12), 22, moonCore);

    // Ground (3 lanes of foggy grass)
    final lanes = [h * 0.28, h * 0.52, h * 0.76];
    for (final ly in lanes) {
      // Fog strip
      final fog = Paint()
        ..color = const Color(0xFF1A3A15).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawRect(Rect.fromLTWH(0, ly - 12, w, 28), fog);
      // Ground line
      final ground = Paint()
        ..color = const Color(0xFF2A5A1A).withValues(alpha: 0.6)
        ..strokeWidth = 2;
      canvas.drawLine(Offset(0, ly + 8), Offset(w, ly + 8), ground);
    }

    // Base wall area (left side shading)
    final baseShade = Paint()
      ..color = const Color(0xFF0A1A08).withValues(alpha: 0.5);
    canvas.drawRect(Rect.fromLTWH(0, 0, 120, h), baseShade);

    // Subtle grid lines on ground
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3A15).withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (double x = 120; x < w; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ZombiePainter extends CustomPainter {
  final Zombie z;
  final double pulse;
  _ZombiePainter(this.z, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    if (z.dying && z.opacity < 0.05) return;

    final cx = size.width / 2;
    // Wobble when targeted
    final wobble = z.targeted ? sin(pulse * pi * 4) * 2 : 0.0;

    // Walk animation
    final walk = sin(z.walkCycle);
    final walkArm = sin(z.walkCycle + pi / 2);

    final skinAlpha = (z.dying ? 0.3 : 0.9) * z.opacity;
    final skin = Paint()..color = z.skinColor.withValues(alpha: skinAlpha);
    final dark = Paint()
      ..color = z.skinColor.withValues(alpha: skinAlpha * 0.6);
    final eye = Paint()
      ..color = const Color(0xFFFF4444).withValues(alpha: z.opacity);
    final cloth = Paint()
      ..color = const Color(0xFF3A3A2A).withValues(alpha: skinAlpha * 0.8);

    // Shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2 * z.opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + wobble, size.height - 4),
        width: 50,
        height: 10,
      ),
      shadow,
    );

    // Legs
    final legSwing = walk * 8;
    _drawLeg(canvas, cx - 8 + wobble, size.height - 30, -legSwing, dark);
    _drawLeg(canvas, cx + 8 + wobble, size.height - 30, legSwing, dark);

    // Body
    final bodyPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + wobble, size.height * 0.52),
            width: 28,
            height: 36,
          ),
          const Radius.circular(4),
        ),
      );
    canvas.drawPath(bodyPath, cloth);

    // Torn shirt detail
    final tear = Paint()
      ..color = z.skinColor.withValues(alpha: skinAlpha * 0.4);
    canvas.drawRect(
      Rect.fromLTWH(cx - 6 + wobble, size.height * 0.44, 12, 8),
      tear,
    );

    // Arms (flailing)
    final armSwing = walkArm * 15;
    _drawArm(canvas, cx - 15 + wobble, size.height * 0.42, armSwing + 20, dark);
    _drawArm(
      canvas,
      cx + 15 + wobble,
      size.height * 0.42,
      -armSwing - 20,
      dark,
    ); // reaching forward

    // Head
    final headY = size.height * 0.22;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + wobble, headY),
        width: 28,
        height: 30,
      ),
      skin,
    );

    // Eyes (glowing red)
    if (!z.dying) {
      final eyeGlow = Paint()
        ..color = const Color(
          0xFFFF4444,
        ).withValues(alpha: z.opacity * (0.5 + pulse * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(cx - 6 + wobble, headY - 2), 5, eyeGlow);
      canvas.drawCircle(Offset(cx + 6 + wobble, headY - 2), 5, eyeGlow);
      canvas.drawCircle(Offset(cx - 6 + wobble, headY - 2), 3, eye);
      canvas.drawCircle(Offset(cx + 6 + wobble, headY - 2), 3, eye);

      // Pupils
      final pupil = Paint()
        ..color = Colors.black.withValues(alpha: z.opacity * 0.8);
      canvas.drawCircle(Offset(cx - 6 + wobble, headY - 2), 1.5, pupil);
      canvas.drawCircle(Offset(cx + 6 + wobble, headY - 2), 1.5, pupil);
    }

    // Power-up glow
    if (z.type == ZombieType.freeze || z.type == ZombieType.bomb) {
      final glowCol = z.type == ZombieType.freeze
          ? const Color(0xFF66FFEE)
          : const Color(0xFFFFCC44);
      final aura = Paint()
        ..color = glowCol.withValues(alpha: 0.15 + pulse * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(Offset(cx + wobble, size.height * 0.45), 32, aura);
    }

    // Tank indicator (bigger / darker outline)
    if (z.type == ZombieType.tank) {
      final outline = Paint()
        ..color = const Color(0xFF8C3E3E).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + wobble, size.height * 0.45),
          width: 34,
          height: 50,
        ),
        outline,
      );
    }

    // Death effect (collapse)
    if (z.dying) {
      final crack = Paint()
        ..color = z.skinColor.withValues(alpha: z.opacity * 0.6)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(cx + wobble, size.height * 0.3),
        Offset(cx + wobble + 10, size.height * 0.6),
        crack,
      );
    }
  }

  void _drawLeg(Canvas c, double x, double y, double angle, Paint p) {
    c.save();
    c.translate(x, y);
    c.rotate(angle * pi / 180);
    c.drawRect(Rect.fromLTWH(-4, 0, 8, 28), p);
    // Foot
    final foot = Paint()..color = p.color.withValues(alpha: 0.8);
    c.drawRect(Rect.fromLTWH(-5, 25, 12, 6), foot);
    c.restore();
  }

  void _drawArm(Canvas c, double x, double y, double angle, Paint p) {
    c.save();
    c.translate(x, y);
    c.rotate(angle * pi / 180);
    c.drawRect(Rect.fromLTWH(-3, 0, 6, 24), p);
    c.restore();
  }

  @override
  bool shouldRepaint(_ZombiePainter old) =>
      old.z.walkCycle != z.walkCycle ||
      old.z.targeted != z.targeted ||
      old.z.dying != z.dying ||
      old.pulse != pulse;
}

class _BasePainter extends CustomPainter {
  final double baseX, screenH, turretAngle, pulse;
  final int hp, maxHp;
  _BasePainter({
    required this.baseX,
    required this.screenH,
    required this.hp,
    required this.maxHp,
    required this.turretAngle,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = baseX;
    final cy = screenH * 0.5;

    // Wall
    final wall = Paint()
      ..color = const Color(0xFF3A4A2A).withValues(alpha: 0.9);
    final wallBorder = Paint()
      ..color = const Color(0xFF5A7A3A).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final wallRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 30, screenH * 0.15, 28, screenH * 0.7),
      const Radius.circular(4),
    );
    canvas.drawRRect(wallRect, wall);
    canvas.drawRRect(wallRect, wallBorder);

    // Battlements (top of wall)
    final merlonPaint = Paint()..color = const Color(0xFF4A5A3A);
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(cx - 28, screenH * 0.15 - 10 + i * 22, 14, 14),
        merlonPaint,
      );
    }

    // Turret barrel
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(turretAngle);

    // Barrel
    final barrel = Paint()..color = const Color(0xFF7A9A5A);
    canvas.drawRect(Rect.fromLTWH(0, -5, 46, 10), barrel);

    // Barrel tip glow (when targeting)
    final tipGlow = Paint()
      ..color = const Color(0xFFAAFF66).withValues(alpha: 0.2 + pulse * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(46, 0), 8, tipGlow);
    final tipCore = Paint()
      ..color = const Color(0xFFAAFF66).withValues(alpha: 0.7);
    canvas.drawCircle(const Offset(46, 0), 3, tipCore);

    canvas.restore();

    // Turret base circle
    final turretBase = Paint()..color = const Color(0xFF5A7A3A);
    canvas.drawCircle(Offset(cx, cy), 18, turretBase);
    final turretBorder = Paint()
      ..color = const Color(0xFF8AAA5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), 18, turretBorder);

    // HP glow (warning when low)
    if (hp <= maxHp ~/ 3) {
      final warn = Paint()
        ..color = Colors.red.withValues(alpha: 0.15 + pulse * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawRect(Rect.fromLTWH(0, 0, cx + 40, screenH), warn);
    }
  }

  @override
  bool shouldRepaint(_BasePainter old) =>
      old.turretAngle != turretAngle || old.hp != hp || old.pulse != pulse;
}

class _SplatPainter extends CustomPainter {
  final List<BloodSplat> splats;
  _SplatPainter(this.splats);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in splats) {
      final p = Paint()
        ..color = const Color(0xFF1A4A0A).withValues(alpha: s.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(s.x, s.y), s.radius, p);

      // Splatter dots
      final rng = Random(s.x.toInt() * 31 + s.y.toInt());
      final core = Paint()
        ..color = const Color(0xFF2A6A10).withValues(alpha: s.opacity * 0.7);
      for (int i = 0; i < 5; i++) {
        final dx = (rng.nextDouble() - 0.5) * s.radius * 2.5;
        final dy = (rng.nextDouble() - 0.5) * s.radius * 2.5;
        canvas.drawCircle(Offset(s.x + dx, s.y + dy), s.radius * 0.2, core);
      }
    }
  }

  @override
  bool shouldRepaint(_SplatPainter old) => old.splats.length != splats.length;
}

class _ZBulletPainter extends CustomPainter {
  final List<ZBullet> bullets;
  _ZBulletPainter(this.bullets);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bullets) {
      // Glow
      final glow = Paint()
        ..color = b.color.withValues(alpha: b.opacity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.isFinal ? 10 : 5);
      canvas.drawCircle(Offset(b.x, b.y), b.isFinal ? 8 : 4.5, glow);

      // Core
      final core = Paint()..color = b.color.withValues(alpha: b.opacity);
      canvas.drawCircle(Offset(b.x, b.y), b.isFinal ? 4 : 2.5, core);

      // White center
      final center = Paint()
        ..color = Colors.white.withValues(alpha: b.opacity * 0.9);
      canvas.drawCircle(Offset(b.x, b.y), b.isFinal ? 2 : 1.2, center);

      // Trail
      if (b.vx != 0 || b.vy != 0) {
        final spd = sqrt(b.vx * b.vx + b.vy * b.vy);
        final tLen = b.isFinal ? 18.0 : 10.0;
        final trail = Paint()
          ..color = b.color.withValues(alpha: b.opacity * 0.3)
          ..strokeWidth = b.isFinal ? 3 : 1.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(b.x, b.y),
          Offset(b.x - (b.vx / spd) * tLen, b.y - (b.vy / spd) * tLen),
          trail,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

class _ZParticlePainter extends CustomPainter {
  final List<ZParticle> particles;
  _ZParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0, 1))
        ..maskFilter = p.size > 3
            ? const MaskFilter.blur(BlurStyle.normal, 3)
            : null;
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life.clamp(0, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

// ── Small UI widgets ──────────────────────────────────────────────────────────
class _ZHudChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ZHudChip(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 8,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.6), blurRadius: 5),
            ],
          ),
        ),
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
        SizedBox(
          width: 120,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 80,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
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
    child: Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      ],
    ),
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
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
        decoration: BoxDecoration(
          color: _h ? widget.color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.color, width: 1.5),
          boxShadow: _h
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.35),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: _h ? [Shadow(color: widget.color, blurRadius: 7)] : null,
          ),
        ),
      ),
    ),
  );
}
