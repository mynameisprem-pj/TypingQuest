import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/sound_service.dart';
import '../../services/profile_service.dart';

// ── Word banks ─────────────────────────────────────────────────────────────
const _kCadetWords = [
  'cat', 'dog', 'run', 'sun', 'hat', 'top', 'car', 'big', 'fly', 'hot',
  'cup', 'pen', 'box', 'red', 'sky', 'ant', 'egg', 'ice', 'owl', 'rat',
  'sea', 'arm', 'bay', 'cow', 'dew', 'elm', 'fan', 'fog', 'gem', 'hen',
  'ivy', 'jaw', 'keg', 'lip', 'mob', 'nap', 'ore', 'pay', 'quo',
];
const _kPilotWords = [
  'apple', 'table', 'chair', 'house', 'water', 'light', 'plant', 'river',
  'stone', 'cloud', 'music', 'dance', 'sleep', 'dream', 'smile', 'happy',
  'smart', 'great', 'world', 'earth', 'class', 'school', 'study', 'learn',
  'write', 'climb', 'think', 'focus', 'start', 'brave', 'Nepal', 'tiger',
  'eagle', 'lotus', 'peace', 'faith', 'grace', 'pilot', 'speed', 'laser',
  'comet', 'orbit', 'lunar', 'solar', 'probe', 'radar', 'craft', 'boost',
  'cargo', 'flare',
];
const _kCommanderWords = [
  'elephant', 'keyboard', 'mountain', 'beautiful', 'computer', 'adventure',
  'champion', 'umbrella', 'discover', 'knowledge', 'together', 'celebrate',
  'butterfly', 'wonderful', 'practice', 'question', 'remember', 'solution',
  'challenge', 'fantastic', 'astronaut', 'telescope', 'spaceship', 'navigator',
  'commander', 'atmosphere', 'constellation', 'acceleration', 'determination',
  'extraordinary', 'accomplishment', 'masterpiece',
];

// Boss sentences
const _kBossSentences = [
  'defend the galaxy from alien invaders',
  'type fast to save the earth from destruction',
  'the commander fires the final laser blast',
  'speed and accuracy win the space battle',
  'brave pilots never give up in a fight',
];

enum ShooterDifficulty { cadet, pilot, commander }

// ── Enemy data model ────────────────────────────────────────────────────────
class SpaceEnemy {
  final String id;
  final String word;
  double x, y, speed;
  final Color color, glowColor;
  bool targeted, dying;
  double opacity, scale;
  final bool isBoss;
  int hp;

  SpaceEnemy({
    required this.id,
    required this.word,
    required this.x,
    required this.y,
    required this.speed,
    required this.color,
    required this.glowColor,
    this.targeted = false,
    this.dying = false,
    this.opacity = 1.0,
    this.scale = 1.0,
    this.isBoss = false,
    this.hp = 1,
  });
}

// ── Traveling bullet ────────────────────────────────────────────────────────
class Bullet {
  double x, y;
  final double vx, vy, destX, destY;
  final Color color;
  double opacity;
  final bool isFinal;
  final String enemyId;

  Bullet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.destX,
    required this.destY,
    required this.color,
    required this.enemyId,
    this.isFinal = false,
    this.opacity = 1.0,
  });

  bool get arrived {
    final dx = destX - x;
    final dy = destY - y;
    return (dx * vx + dy * vy) <= 0;
  }
}

// ── Explosion particle ──────────────────────────────────────────────────────
class Particle {
  double x, y, vx, vy, life;
  final Color color;
  final double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    this.life = 1.0,
  });
}

// ── Star (background) ───────────────────────────────────────────────────────
class Star {
  final double x, y, size, brightness;
  Star({required this.x, required this.y, required this.size, required this.brightness});
}

// ══════════════════════════════════════════════════════════════════════════════
class SpaceShooterGame extends StatefulWidget {
  const SpaceShooterGame({super.key});

  @override
  State<SpaceShooterGame> createState() => _SpaceShooterGameState();
}

class _SpaceShooterGameState extends State<SpaceShooterGame>
    with TickerProviderStateMixin {
  // ── Game state ─────────────────────────────────────────────────────────
  ShooterDifficulty _difficulty = ShooterDifficulty.cadet;
  bool _started = false, _gameOver = false, _paused = false, _isBossWave = false;

  int _score = 0, _highScore = 0, _lives = 3, _kills = 0;
  int _combo = 0, _maxCombo = 0, _wave = 1;

  // ── Enemies & effects ──────────────────────────────────────────────────
  final List<SpaceEnemy> _enemies = [];
  final List<Bullet> _bullets = [];
  final List<Particle> _particles = [];
  final List<Star> _stars = [];
  final _rng = Random();

  // ── Typing ─────────────────────────────────────────────────────────────
  String _typed = '';
  SpaceEnemy? _lockedTarget;

  // ── Ship ───────────────────────────────────────────────────────────────
  double _shipX = 0.5;
  double _shipAngle = 0.0;
  double _shipTargetAngle = 0.0;
  bool _shipShaking = false;
  late AnimationController _shakeCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _engineCtrl;

  // ── Game loop ─────────────────────────────────────────────────────────
  Timer? _gameLoop, _spawnTimer;
  DateTime? _lastFrame;

  // ── Screen size ────────────────────────────────────────────────────────
  double _screenW = 800, _screenH = 600;
  double get _uiScale => min(_screenW, _screenH) / 600.0;
  double get _fontScale => _uiScale.clamp(0.7, 1.35);

  // ── Cached config (rebuilt only on difficulty change) ─────────────────
  late Map<String, dynamic> _cfgCache;
  late List<String> _wordBankCache;

  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _engineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat(reverse: true);
    _rebuildConfig();
    _generateStars();
    _loadHighScore();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    _engineCtrl.dispose();
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  bool get _canPersistScore {
    final profile = ProfileService();
    return profile.hasProfile && !profile.isGuest;
  }

  // ── Config — cached, rebuilt only when difficulty changes ───────────────
  void _rebuildConfig() {
    _cfgCache = {
      ShooterDifficulty.cadet: {
        'spawnMs': 3200,
        'speedMin': 30.0,
        'speedMax': 55.0,
        'max': 4,
      },
      ShooterDifficulty.pilot: {
        'spawnMs': 2200,
        'speedMin': 55.0,
        'speedMax': 90.0,
        'max': 6,
      },
      ShooterDifficulty.commander: {
        'spawnMs': 1400,
        'speedMin': 85.0,
        'speedMax': 140.0,
        'max': 9,
      },
    }[_difficulty]!;

    _wordBankCache = {
      ShooterDifficulty.cadet: _kCadetWords,
      ShooterDifficulty.pilot: _kPilotWords,
      ShooterDifficulty.commander: _kCommanderWords,
    }[_difficulty]!;
  }

  // ── Init ────────────────────────────────────────────────────────────────
  void _generateStars() {
    _stars.clear();
    for (int i = 0; i < 120; i++) {
      _stars.add(Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 2 + 0.5,
        brightness: _rng.nextDouble() * 0.6 + 0.3,
      ));
    }
  }

  Future<void> _loadHighScore() async {
    if (!_canPersistScore) {
      if (mounted) setState(() => _highScore = 0);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = '${ProfileService().keyPrefix}space_shooter_hs_${_difficulty.name}';
    setState(() => _highScore = prefs.getInt(key) ?? 0);
  }

  Future<void> _saveHighScore() async {
    if (!_canPersistScore) return;
    if (_score <= _highScore) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '${ProfileService().keyPrefix}space_shooter_hs_${_difficulty.name}';
    await prefs.setInt(key, _score);
    setState(() => _highScore = _score);
  }

  // ── Start / Stop ────────────────────────────────────────────────────────
  void _startGame() {
    setState(() {
      _started = true;
      _gameOver = false;
      _paused = false;
      _score = 0;
      _lives = 3;
      _kills = 0;
      _combo = 0;
      _maxCombo = 0;
      _wave = 1;
      _typed = '';
      _lockedTarget = null;
      _isBossWave = false;
      _enemies.clear();
      _bullets.clear();
      _particles.clear();
      _shipX = 0.5;
      _shipAngle = 0.0;
      _shipTargetAngle = 0.0;
    });

    _lastFrame = DateTime.now();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _tick);
    _scheduleSpawn();
  }

  void _endGame() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _saveHighScore();
    setState(() => _gameOver = true);
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (!_paused) _lastFrame = DateTime.now();
  }

  // ── Game loop ────────────────────────────────────────────────────────────
  void _tick(Timer t) {
    if (_paused || _gameOver || !_started) return;

    final now = DateTime.now();
    final dt = (_lastFrame == null)
        ? 0.016
        : now.difference(_lastFrame!).inMilliseconds / 1000.0;
    _lastFrame = now;
    final safeDt = dt.clamp(0.0, 0.05);

    // Mutate state objects directly — no copies needed when only calling
    // removeWhere after the loop (not during), which is safe
    for (final e in _enemies) {
      if (!e.dying) {
        e.y += e.speed * safeDt;
      } else {
        e.opacity = (e.opacity - safeDt * 3).clamp(0, 1);
        e.scale = (e.scale + safeDt * 2).clamp(1, 3);
      }
    }

    final bulletsToRemove = <Bullet>[];
    for (final b in _bullets) {
      b.x += b.vx * safeDt;
      b.y += b.vy * safeDt;
      if (b.arrived) {
        _onBulletHit(b);
        bulletsToRemove.add(b);
      }
    }
    _bullets.removeWhere(bulletsToRemove.contains);

    for (final p in _particles) {
      p.life -= safeDt * 1.8;
      p.x += p.vx * safeDt;
      p.y += p.vy * safeDt;
      p.vy += 80 * safeDt;
    }

    final angleDiff = _shipTargetAngle - _shipAngle;
    _shipAngle += angleDiff * (safeDt * 8).clamp(0, 1);

    _enemies.removeWhere((e) => e.dying && e.opacity <= 0);
    _particles.removeWhere((p) => p.life <= 0);

    final groundY = _screenH - (90 * _uiScale).clamp(60, 140);
    final reachedGround = _enemies.where((e) => !e.dying && e.y > groundY).toList();
    for (final e in reachedGround) {
      _onEnemyReachedGround(e);
    }

    setState(() {}); // single setState per tick — minimal rebuild cost
  }

  void _onEnemyReachedGround(SpaceEnemy e) {
    _enemies.remove(e);
    if (_lockedTarget == e) {
      _lockedTarget = null;
      _typed = '';
    }
    _lives--;
    _combo = 0;
    _shipShaking = true;
    _shakeCtrl
        .forward(from: 0)
        .then((_) => setState(() => _shipShaking = false));
    SoundService().playError();

    _spawnExplosionAt(_shipX * _screenW, _screenH - 80,
        const Color(0xFFFF4444), count: 8);

    if (_lives <= 0) _endGame();
  }

  // ── Spawn enemies ────────────────────────────────────────────────────────
  void _scheduleSpawn() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer(Duration(milliseconds: _cfgCache['spawnMs'] as int), () {
      if (!_gameOver && !_paused && _started) {
        _spawnEnemy();
        _scheduleSpawn();
      }
    });
  }

  void _spawnEnemy() {
    if (_isBossWave) return;
    final maxOnScreen = _cfgCache['max'] as int;
    if (_enemies.where((e) => !e.dying).length >= maxOnScreen) return;

    if (_kills > 0 && _kills % 10 == 0 && !_isBossWave) {
      _spawnBoss();
      return;
    }

    final word = _wordBankCache[_rng.nextInt(_wordBankCache.length)];
    final usedFirstLetters = _enemies
        .where((e) => !e.dying && !e.targeted)
        .map((e) => e.word[0].toLowerCase())
        .toSet();

    String finalWord = word;
    if (usedFirstLetters.contains(word[0].toLowerCase())) {
      final alts = _wordBankCache
          .where((w) => !usedFirstLetters.contains(w[0].toLowerCase()))
          .toList();
      if (alts.isNotEmpty) finalWord = alts[_rng.nextInt(alts.length)];
    }

    final len = finalWord.length;
    Color col, glow;
    if (len <= 4) {
      col = glow = const Color(0xFF50FA7B);
    } else if (len <= 7) {
      col = glow = const Color(0xFFFFD93D);
    } else {
      col = glow = const Color(0xFFFF6E6E);
    }

    final minSpeed = _cfgCache['speedMin'] as double;
    final maxSpeed = _cfgCache['speedMax'] as double;

    _enemies.add(SpaceEnemy(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      word: finalWord,
      x: 0.08 + _rng.nextDouble() * 0.84,
      y: -60,
      speed: minSpeed + _rng.nextDouble() * (maxSpeed - minSpeed),
      color: col,
      glowColor: glow,
    ));
  }

  void _spawnBoss() {
    _isBossWave = true;
    _wave++;
    final sentence = _kBossSentences[_rng.nextInt(_kBossSentences.length)];
    _enemies.add(SpaceEnemy(
      id: 'boss_${DateTime.now().millisecondsSinceEpoch}',
      word: sentence,
      x: 0.5,
      y: -90,
      speed: 20,
      color: const Color(0xFFFF5555),
      glowColor: const Color(0xFFFF0000),
      isBoss: true,
      hp: sentence.length,
    ));
  }

  // ── Explosions ────────────────────────────────────────────────────────────
  void _spawnExplosionAt(double x, double y, Color col, {int count = 18}) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60 + _rng.nextDouble() * 200;
      _particles.add(Particle(
        x: x, y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 80,
        color: i % 3 == 0 ? Colors.white : (i % 3 == 1 ? col : col.withValues(alpha: 0.6)),
        size: 2 + _rng.nextDouble() * 5,
      ));
    }
  }

  // ── Fire one bullet per letter typed ─────────────────────────────────────
  void _fireBullet(SpaceEnemy target, {bool isFinal = false}) {
    final tx = target.x * _screenW;
    final ty = target.y + 10;
    final sx = _shipX * _screenW;
    final sy = _screenH - 80;

    final dx = tx - sx;
    final dy = ty - sy;
    final dist = sqrt(dx * dx + dy * dy);
    const speed = 900.0;

    final col = target.isBoss
        ? const Color(0xFFFF3388)
        : isFinal
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF00FFFF);

    _bullets.add(Bullet(
      x: sx, y: sy,
      vx: (dx / dist) * speed,
      vy: (dy / dist) * speed,
      destX: tx, destY: ty,
      color: col,
      enemyId: target.id,
      isFinal: isFinal,
    ));

    _shipTargetAngle = atan2(dx, -dy).clamp(-0.7, 0.7);
  }

  void _onBulletHit(Bullet b) {
    final enemy = _enemies.where((e) => e.id == b.enemyId && !e.dying).firstOrNull;
    if (enemy == null) return;

    if (b.isFinal) {
      enemy.dying = true;
      _spawnExplosionAt(b.destX, b.destY, enemy.color,
          count: enemy.isBoss ? 40 : 20);
      _shipX = (_shipX * 0.65 + enemy.x * 0.35).clamp(0.05, 0.95);
    } else {
      _spawnHitSpark(b.destX, b.destY, b.color);
    }
  }

  void _spawnHitSpark(double x, double y, Color col) {
    for (int i = 0; i < 5; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 30 + _rng.nextDouble() * 80;
      _particles.add(Particle(
        x: x, y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 40,
        color: i == 0 ? Colors.white : col,
        size: 1.5 + _rng.nextDouble() * 2.5,
        life: 0.5,
      ));
    }
  }

  // ── Key handler ──────────────────────────────────────────────────────────
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
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      char = ' ';
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_typed.isNotEmpty) {
        setState(() {
          _typed = _typed.substring(0, _typed.length - 1);
          if (_typed.isEmpty) _lockedTarget = null;
        });
      }
      return;
    }
    if (char == null) return;

    setState(() {
      if (_lockedTarget == null || !_enemies.contains(_lockedTarget)) {
        _lockedTarget = null;
        _typed = '';
        for (final e in _enemies) {
          if (!e.dying &&
              e.word.toLowerCase().startsWith(char!.toLowerCase())) {
            _lockedTarget = e;
            e.targeted = true;
            final tx = _lockedTarget!.x * _screenW;
            final ty = _lockedTarget!.y;
            final sx = _shipX * _screenW;
            final sy = _screenH - 80;
            _shipTargetAngle = atan2(tx - sx, -(ty - sy)).clamp(-0.7, 0.7);
            break;
          }
        }
        if (_lockedTarget == null) return;
      }

      final target = _lockedTarget!;
      final expected = target.word[_typed.length];

      if (char!.toLowerCase() == expected.toLowerCase()) {
        _typed += char;
        SoundService().playKeyClick();

        final isLast = _typed.length >= target.word.length;
        _fireBullet(target, isFinal: isLast);

        if (isLast) _destroyEnemy(target);
      } else {
        SoundService().playError();
        _combo = 0;
      }
    });
  }

  void _destroyEnemy(SpaceEnemy target) {
    target.dying = true;
    _kills++;
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;

    final comboMult = _combo >= 10 ? 3 : _combo >= 5 ? 2 : 1;
    final diffMult = _difficulty == ShooterDifficulty.commander
        ? 3
        : _difficulty == ShooterDifficulty.pilot
            ? 2
            : 1;
    _score +=
        target.word.replaceAll(' ', '').length * 10 * comboMult * diffMult +
            (target.isBoss ? 500 : 0);

    _typed = '';
    _lockedTarget = null;
    for (final e in _enemies) {
      e.targeted = false;
    }

    if (target.isBoss) {
      _isBossWave = false;
      SoundService().playLevelComplete();
    } else {
      SoundService().playStreak();
    }

    if (_kills % 10 == 0 && !_isBossWave) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_gameOver) _spawnBoss();
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            _screenW = constraints.maxWidth;
            _screenH = constraints.maxHeight;
            return Stack(
              children: [
                _buildBackground(),
                if (_started && !_gameOver) ...[
                  _buildEnemies(),
                  _buildBullets(),
                  _buildParticles(),
                  _buildShip(),
                  _buildHUD(),
                  _buildTypingInput(),
                ],
                if (!_started || _gameOver) _buildMenuOrGameOver(),
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
      painter: _StarfieldPainter(_stars, _pulseCtrl.value),
    );
  }

  // ── Enemies ────────────────────────────────────────────────────────────────
  Widget _buildEnemies() {
    return Stack(
      children: _enemies.map((e) {
        final ex = e.x * _screenW;
        final ey = e.y;
        final typedSoFar = (e == _lockedTarget) ? _typed : '';

        return Positioned(
          left: ex - (e.isBoss ? 160 * _uiScale : 55 * _uiScale),
          top: ey - (e.isBoss ? 50 * _uiScale : 30 * _uiScale),
          child: Opacity(
            opacity: e.opacity,
            child: Transform.scale(
              scale: e.dying ? e.scale : 1.0,
              child: e.isBoss
                  ? _buildBossEnemy(e, typedSoFar)
                  : _buildNormalEnemy(e, typedSoFar),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNormalEnemy(SpaceEnemy e, String typed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(50 * _uiScale, 32 * _uiScale),
          painter: _AlienPainter(e.color, e.targeted, e.dying),
        ),
        SizedBox(height: 4 * _uiScale),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: e.targeted ? e.color : e.color.withValues(alpha: 0.4),
              width: e.targeted ? 1.5 : 1,
            ),
            boxShadow: e.targeted
                ? [BoxShadow(color: e.color.withValues(alpha: 0.4), blurRadius: 8)]
                : null,
          ),
          child: _buildWordDisplay(e.word, typed, e.color),
        ),
      ],
    );
  }

  Widget _buildBossEnemy(SpaceEnemy e, String typed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Boss uses AnimatedBuilder only for pulse — not every enemy
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) => CustomPaint(
            size: Size(160 * _uiScale, 70 * _uiScale),
            painter: _BossPainter(e.color, _pulseCtrl.value, e.dying),
          ),
        ),
        SizedBox(height: 6 * _uiScale),
        Container(
          constraints: BoxConstraints(maxWidth: (340 * _uiScale).clamp(220, 420)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF5555), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x66FF0000), blurRadius: 16)],
          ),
          child: _buildWordDisplay(e.word, typed, const Color(0xFFFF8888)),
        ),
        const SizedBox(height: 4),
        Container(
          width: (200 * _uiScale).clamp(120, 260),
          height: (6 * _uiScale).clamp(4, 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ((e.word.length - typed.length) / e.word.length).clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF5555),
                borderRadius: BorderRadius.circular(3),
                boxShadow: const [BoxShadow(color: Color(0xAAFF0000), blurRadius: 4)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordDisplay(String word, String typed, Color activeColor) {
    return RichText(
      text: TextSpan(
        children: List.generate(word.length, (i) {
          final Color c = i < typed.length
              ? activeColor.withValues(alpha: 0.4)
              : i == typed.length
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.85);
          final bg = i == typed.length && typed.isNotEmpty
              ? activeColor.withValues(alpha: 0.15)
              : null;
          return WidgetSpan(
            child: Container(
              decoration: bg != null
                  ? BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2))
                  : null,
              child: Text(
                word[i],
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: (word.length > 20 ? 13 : 16) * _fontScale,
                  fontWeight: FontWeight.bold,
                  color: c,
                  decoration: i < typed.length ? TextDecoration.lineThrough : null,
                  decorationColor: activeColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Bullets ───────────────────────────────────────────────────────────────
  Widget _buildBullets() {
    return CustomPaint(
      size: Size(_screenW, _screenH),
      painter: _BulletPainter(_bullets),
    );
  }

  // ── Particles ─────────────────────────────────────────────────────────────
  Widget _buildParticles() {
    return CustomPaint(
      size: Size(_screenW, _screenH),
      painter: _ParticlePainter(_particles),
    );
  }

  // ── Ship ──────────────────────────────────────────────────────────────────
  Widget _buildShip() {
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeCtrl, _engineCtrl]),
      builder: (_, _) {
        final shake = _shipShaking
            ? sin(_shakeCtrl.value * pi * 8) * 6 * (1 - _shakeCtrl.value)
            : 0.0;
        final shipW = (60 * _uiScale).clamp(36, 84).toDouble();
        final shipH = (70 * _uiScale).clamp(42, 96).toDouble();
        return Positioned(
          left: _shipX * _screenW - shipW / 2 + shake,
          bottom: (40 * _uiScale).clamp(16, 60).toDouble(),
          child: CustomPaint(
            size: Size(shipW, shipH),
            painter: _ShipPainter(
              _engineCtrl.value,
              _shipShaking && _shakeCtrl.value > 0.1,
              _shipAngle,
            ),
          ),
        );
      },
    );
  }

  // ── HUD ───────────────────────────────────────────────────────────────────
  Widget _buildHUD() {
    final comboMult = _combo >= 10 ? 3 : _combo >= 5 ? 2 : 1;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white70, size: 16),
              ),
            ),
            const SizedBox(width: 16),
            _HudChip(label: 'SCORE', value: '$_score', color: const Color(0xFF00FFFF)),
            const SizedBox(width: 12),
            _HudChip(label: 'BEST', value: '$_highScore', color: const Color(0xFFFFD700)),
            const SizedBox(width: 12),
            _HudChip(label: 'WAVE', value: '$_wave', color: const Color(0xFFFF79C6)),
            const Spacer(),
            if (_combo >= 3)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange
                        .withValues(alpha: 0.1 + _pulseCtrl.value * 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange
                          .withValues(alpha: 0.6 + _pulseCtrl.value * 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 12),
                    ],
                  ),
                  child: Text(
                    '${_combo}x COMBO${comboMult > 1 ? " (${comboMult}x)" : ""}',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                            color: Colors.orange.withValues(alpha: 0.8),
                            blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.favorite,
                    color: i < _lives
                        ? const Color(0xFFFF5555)
                        : Colors.white12,
                    size: 22,
                    shadows: i < _lives
                        ? const [Shadow(color: Color(0xAAFF0000), blurRadius: 8)]
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _togglePause,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pause, color: Colors.white70, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Typing input display ──────────────────────────────────────────────────
  Widget _buildTypingInput() {
    if (_typed.isEmpty && _lockedTarget == null) return const SizedBox();
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF00FFFF)
                    .withValues(alpha: 0.4 + _pulseCtrl.value * 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                    blurRadius: 12),
              ],
            ),
            child: Text(
              _typed.isEmpty ? '...' : _typed,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16 * _fontScale,
                color: const Color(0xFF00FFFF),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5 * _fontScale,
                shadows: const [Shadow(color: Color(0xFF00FFFF), blurRadius: 8)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Menu / Game Over ──────────────────────────────────────────────────────
  Widget _buildMenuOrGameOver() {
    final isOver = _gameOver;
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isOver) ...[
                const Text('🚀', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text(
                  'SPACE SHOOTER',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FFFF),
                    letterSpacing: 4,
                    shadows: [Shadow(color: Color(0xFF00FFFF), blurRadius: 16)],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TYPE THE WORDS TO DESTROY ALIEN INVADERS',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 13, letterSpacing: 2),
                ),
              ] else ...[
                const Text('💥', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF5555),
                    letterSpacing: 4,
                    shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 16)],
                  ),
                ),
                const SizedBox(height: 20),
                _StatRow(label: 'SCORE', value: '$_score'),
                _StatRow(label: 'BEST', value: '$_highScore'),
                _StatRow(label: 'KILLS', value: '$_kills'),
                _StatRow(label: 'MAX COMBO', value: '${_maxCombo}x'),
                _StatRow(label: 'WAVES', value: '$_wave'),
              ],
              const SizedBox(height: 32),

              if (!isOver) ...[
                const Text(
                  'SELECT DIFFICULTY',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 11, letterSpacing: 3),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DiffBtn(
                      label: 'CADET',
                      sub: 'Short words\nSlow speed',
                      selected: _difficulty == ShooterDifficulty.cadet,
                      color: const Color(0xFF50FA7B),
                      onTap: () => setState(() {
                        _difficulty = ShooterDifficulty.cadet;
                        _rebuildConfig();
                        _loadHighScore();
                      }),
                    ),
                    const SizedBox(width: 12),
                    _DiffBtn(
                      label: 'PILOT',
                      sub: 'Medium words\nMed speed',
                      selected: _difficulty == ShooterDifficulty.pilot,
                      color: const Color(0xFFFFD93D),
                      onTap: () => setState(() {
                        _difficulty = ShooterDifficulty.pilot;
                        _rebuildConfig();
                        _loadHighScore();
                      }),
                    ),
                    const SizedBox(width: 12),
                    _DiffBtn(
                      label: 'COMMANDER',
                      sub: 'Long words\nFast speed',
                      selected: _difficulty == ShooterDifficulty.commander,
                      color: const Color(0xFFFF6E6E),
                      onTap: () => setState(() {
                        _difficulty = ShooterDifficulty.commander;
                        _rebuildConfig();
                        _loadHighScore();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text('HOW TO PLAY',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              letterSpacing: 3)),
                      SizedBox(height: 10),
                      _HowToRow(
                          icon: '⌨',
                          text: 'Type the word on an alien to target and shoot it'),
                      _HowToRow(
                          icon: '💥',
                          text: 'Complete the word to fire a laser and destroy it'),
                      _HowToRow(
                          icon: '⭐',
                          text: 'Chain kills for combo multiplier (5x = 2x, 10x = 3x)'),
                      _HowToRow(
                          icon: '👾',
                          text: 'Boss appears every 10 kills — type a sentence to defeat it'),
                      _HowToRow(
                          icon: '❤',
                          text: 'You have 3 lives — don\'t let aliens reach Earth!'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isOver) ...[
                    _SpaceBtn(
                      label: '← MENU',
                      color: Colors.white38,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                  ],
                  _SpaceBtn(
                    label: isOver ? '▶ PLAY AGAIN' : '▶ LAUNCH MISSION',
                    color: const Color(0xFF00FFFF),
                    onTap: _startGame,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pause screen ──────────────────────────────────────────────────────────
  Widget _buildPauseScreen() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⏸', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('PAUSED',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6)),
            const SizedBox(height: 32),
            _SpaceBtn(
                label: '▶ RESUME',
                color: const Color(0xFF00FFFF),
                onTap: _togglePause),
            const SizedBox(height: 12),
            _SpaceBtn(
                label: '← QUIT',
                color: Colors.white38,
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Custom painters
// ══════════════════════════════════════════════════════════════════════════════

class _StarfieldPainter extends CustomPainter {
  final List<Star> stars;
  final double pulse;
  _StarfieldPainter(this.stars, this.pulse);

  // Cache background shader rect so it isn't reallocated every frame
  static Rect? _cachedRect;
  static Shader? _cachedShader;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Only recreate gradient shader if size changed
    if (_cachedRect != rect) {
      _cachedRect = rect;
      _cachedShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF000814), Color(0xFF001233), Color(0xFF000814)],
      ).createShader(rect);
    }

    final bg = Paint()..shader = _cachedShader;
    canvas.drawRect(rect, bg);

    // Nebula glow — infrequent blur, drawn once
    final nebula = Paint()
      ..color = const Color(0xFF1A0033).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 200, nebula);
    nebula.color = const Color(0xFF002244).withValues(alpha: 0.3);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.6), 160, nebula);

    final starPaint = Paint();
    for (final s in stars) {
      final twinkle = s.brightness * (0.7 + pulse * 0.3);
      starPaint.color = Colors.white.withValues(alpha: twinkle);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.size, starPaint);
    }

    // Ground
    canvas.drawRect(
      Rect.fromLTRB(0, size.height - 40, size.width, size.height),
      Paint()..color = const Color(0xFF0A3060).withValues(alpha: 0.6),
    );
    canvas.drawLine(
      Offset(0, size.height - 40),
      Offset(size.width, size.height - 40),
      Paint()
        ..color = const Color(0xFF00AAFF).withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.pulse != pulse;
}

class _AlienPainter extends CustomPainter {
  final Color color;
  final bool targeted, dying;
  _AlienPainter(this.color, this.targeted, this.dying);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = dying ? color.withValues(alpha: 0.3) : color;
    final glow = Paint()
      ..color = color.withValues(alpha: targeted ? 0.5 : 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy), width: size.width * 0.9, height: size.height * 0.7),
      glow,
    );

    final body = Paint()
      ..color = color.withValues(alpha: dying ? 0.2 : 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + 4),
          width: size.width * 0.85,
          height: size.height * 0.55),
      body,
    );

    final dome = Paint()
      ..color = color.withValues(alpha: dying ? 0.1 : 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy - 2),
          width: size.width * 0.42,
          height: size.height * 0.55),
      dome,
    );

    if (!dying) {
      final light = Paint()..color = Colors.white.withValues(alpha: 0.9);
      for (int i = 0; i < 5; i++) {
        canvas.drawCircle(Offset(cx - 16 + i * 8.0, cy + 6), 2, light);
      }
    }

    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + 4),
          width: size.width * 0.85,
          height: size.height * 0.55),
      p,
    );
  }

  @override
  bool shouldRepaint(_AlienPainter old) =>
      old.targeted != targeted || old.dying != dying;
}

class _BossPainter extends CustomPainter {
  final Color color;
  final double pulse;
  final bool dying;
  _BossPainter(this.color, this.pulse, this.dying);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.15 + pulse * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: size.width, height: size.height),
      glow,
    );

    final body = Paint()..color = color.withValues(alpha: dying ? 0.2 : 0.8);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + 6),
          width: size.width * 0.9,
          height: size.height * 0.65),
      body,
    );

    final wing = Paint()..color = color.withValues(alpha: dying ? 0.15 : 0.5);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - size.width * 0.35, cy + 4),
          width: size.width * 0.3,
          height: size.height * 0.35),
      wing,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + size.width * 0.35, cy + 4),
          width: size.width * 0.3,
          height: size.height * 0.35),
      wing,
    );

    final dome = Paint()..color = color.withValues(alpha: dying ? 0.1 : 0.4);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy - 4),
          width: size.width * 0.38,
          height: size.height * 0.6),
      dome,
    );

    if (!dying) {
      final light = Paint()
        ..color = Colors.white.withValues(alpha: 0.7 + pulse * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      for (int i = 0; i < 7; i++) {
        canvas.drawCircle(Offset(cx - 24 + i * 8.0, cy + 8), 3, light);
      }
    }

    final outline = Paint()
      ..color = color.withValues(alpha: 0.8 + pulse * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + 6),
          width: size.width * 0.9,
          height: size.height * 0.65),
      outline,
    );
  }

  @override
  bool shouldRepaint(_BossPainter old) =>
      old.pulse != pulse || old.dying != dying;
}

class _ShipPainter extends CustomPainter {
  final double engineFlicker;
  final bool hit;
  final double tiltAngle;
  _ShipPainter(this.engineFlicker, this.hit, this.tiltAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tiltAngle);
    canvas.translate(-cx, -cy);

    final flame = Paint()
      ..color = Color.lerp(const Color(0xFFFF8800), const Color(0xFFFFFF00),
              engineFlicker)!
          .withValues(alpha: 0.8 + engineFlicker * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, size.height - 8),
          width: 16,
          height: 20 + engineFlicker * 10),
      flame,
    );

    final bodyColor = hit ? const Color(0xFFFF4444) : const Color(0xFF4FC3F7);
    final body = Paint()..color = bodyColor;
    final bodyPath = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + 18, size.height - 20)
      ..lineTo(cx + 10, size.height - 10)
      ..lineTo(cx - 10, size.height - 10)
      ..lineTo(cx - 18, size.height - 20)
      ..close();
    canvas.drawPath(bodyPath, body);

    final wing = Paint()..color = const Color(0xFF0288D1);
    final lWing = Path()
      ..moveTo(cx - 14, size.height - 28)
      ..lineTo(cx - 28, size.height - 14)
      ..lineTo(cx - 12, size.height - 14)
      ..close();
    final rWing = Path()
      ..moveTo(cx + 14, size.height - 28)
      ..lineTo(cx + 28, size.height - 14)
      ..lineTo(cx + 12, size.height - 14)
      ..close();
    canvas.drawPath(lWing, wing);
    canvas.drawPath(rWing, wing);

    final cockpit = Paint()
      ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.9);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.38), width: 14, height: 18),
      cockpit,
    );

    final glow = Paint()
      ..color = bodyColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(bodyPath, glow);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShipPainter old) =>
      old.engineFlicker != engineFlicker ||
      old.hit != hit ||
      old.tiltAngle != tiltAngle;
}

class _BulletPainter extends CustomPainter {
  final List<Bullet> bullets;
  _BulletPainter(this.bullets);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bullets) {
      final glow = Paint()
        ..color = b.color.withValues(alpha: b.opacity * 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.isFinal ? 10 : 6);
      canvas.drawCircle(Offset(b.x, b.y), b.isFinal ? 9 : 5, glow);

      final core = Paint()..color = b.color.withValues(alpha: b.opacity);
      canvas.drawCircle(Offset(b.x, b.y), b.isFinal ? 4 : 2.5, core);

      final center = Paint()
        ..color = Colors.white.withValues(alpha: b.opacity * 0.9);
      canvas.drawCircle(Offset(b.x, b.y), b.isFinal ? 2 : 1.2, center);

      if (b.vx != 0 || b.vy != 0) {
        final speed = sqrt(b.vx * b.vx + b.vy * b.vy);
        final trailLen = b.isFinal ? 20.0 : 12.0;
        final tx = b.x - (b.vx / speed) * trailLen;
        final ty = b.y - (b.vy / speed) * trailLen;
        final trail = Paint()
          ..color = b.color.withValues(alpha: b.opacity * 0.35)
          ..strokeWidth = b.isFinal ? 3 : 1.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(b.x, b.y), Offset(tx, ty), trail);
      }
    }
  }

  @override
  bool shouldRepaint(_BulletPainter old) => true;
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0, 1))
        ..maskFilter =
            p.size > 4 ? const MaskFilter.blur(BlurStyle.normal, 3) : null;
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ── Small UI widgets ──────────────────────────────────────────────────────────
class _HudChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HudChip({required this.label, required this.value, required this.color});
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
            Text(label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 9,
                    letterSpacing: 1.5)),
            Text(value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
                )),
          ],
        ),
      );
}

class _DiffBtn extends StatelessWidget {
  final String label, sub;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _DiffBtn({
    required this.label,
    required this.sub,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : Colors.white24,
                width: selected ? 2 : 1),
            boxShadow: selected
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)]
                : null,
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      color: selected ? color : Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: selected
                          ? color.withValues(alpha: 0.8)
                          : Colors.white30,
                      fontSize: 10,
                      height: 1.4)),
              if (selected) ...[
                const SizedBox(height: 6),
                Icon(Icons.check_circle, color: color, size: 14),
              ],
            ],
          ),
        ),
      );
}

class _SpaceBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SpaceBtn({required this.label, required this.color, required this.onTap});
  @override
  State<_SpaceBtn> createState() => _SpaceBtnState();
}

class _SpaceBtnState extends State<_SpaceBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.color, width: 1.5),
              boxShadow: _hovered
                  ? [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 16)]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: _hovered
                    ? [Shadow(color: widget.color, blurRadius: 8)]
                    : null,
              ),
            ),
          ),
        ),
      );
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12, letterSpacing: 2)),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace')),
            ),
          ],
        ),
      );
}

class _HowToRow extends StatelessWidget {
  final String icon, text;
  const _HowToRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ],
        ),
      );
}
