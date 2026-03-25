// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/sound_service.dart';
import '../../services/profile_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  WORD BANKS
// ═══════════════════════════════════════════════════════════════════════════
const _kShort = [
  'axe', 'bow', 'foe', 'hit', 'jab', 'rip', 'run', 'war', 'zap', 'arm',
  'bash', 'bite', 'bolt', 'burn', 'cast', 'claw', 'dash', 'doom', 'duel',
  'fall', 'fate', 'fear', 'fire', 'flay', 'flee', 'guard', 'lance', 'noble',
  'quest', 'siege', 'sword', 'valor', 'wrath',
];
const _kMed = [
  'archer', 'battle', 'charge', 'defend', 'dragon', 'fallen', 'fierce',
  'hammer', 'invade', 'knight', 'mantle', 'pierce', 'rally', 'shield',
  'sunder', 'thrust', 'brave', 'clash', 'crown', 'curse', 'dungeon',
  'forge', 'glory', 'honor', 'tower', 'vanquish', 'armored', 'bastion',
  'cavalry', 'crusade', 'embattle', 'rampart',
];
const _kLong = [
  'barricade', 'battleaxe', 'besiege', 'bloodshed', 'catapult', 'cavalier',
  'champion', 'conquest', 'crumbling', 'defender', 'desperate', 'devastate',
  'eliminate', 'onslaught', 'overwhelm', 'relentless', 'slaughter',
  'vengeance', 'warlord', 'crusader', 'blockade', 'armistice', 'fortified',
  'stronghold',
];
const _kBoss = [
  'the dragon descends',
  'defend the castle',
  'strike down the beast',
  'the kingdom must hold',
  'glory to the last knight',
  'charge with your sword',
];

// ═══════════════════════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════════════════════
enum KnightDifficulty { squire, knight, legend }
enum EnemyType        { soldier, archer, troll, armored }
enum GamePhase        { menu, playing, bossEntry, bossFight, gameOver }

class Enemy {
  final String id;
  final EnemyType type;
  final String word;
  double x, y;
  final double speed;
  int hp, maxHp;
  bool dying    = false;
  double dyingT = 0;
  double walkT  = 0;
  bool targeted = false;
  int typedSoFar = 0;
  double arrowCooldown = 0;

  Enemy({
    required this.id, required this.type, required this.word,
    required this.x,  required this.y,    required this.speed,
    required this.hp,
  }) : maxHp = hp;
}

class Fireball {
  final String id, letter;
  double x, y, vx, vy;
  bool dying   = false;
  double dyingT = 0;
  double rot    = 0;
  Fireball({
    required this.id, required this.letter,
    required this.x,  required this.y,
    required this.vx, required this.vy,
  });
}

class Arrow {
  double x, y, vx, vy;
  bool spent = false;
  Arrow({required this.x, required this.y, required this.vx, required this.vy});
}

class Particle {
  double x, y, vx, vy, life, size, rot;
  final Color color;
  Particle({
    required this.x,  required this.y,
    required this.vx, required this.vy,
    required this.color,
    this.life = 1, this.size = 4, this.rot = 0,
  });
}

class FloatingText {
  double x, y, life;
  final String text;
  final Color color;
  FloatingText({
    required this.x, required this.y,
    required this.text, required this.color,
    this.life = 1,
  });
}

class CastleCrack {
  final Offset a, b;
  CastleCrack(this.a, this.b);
}

// ═══════════════════════════════════════════════════════════════════════════
//  MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class TypingKnightGame extends StatefulWidget {
  const TypingKnightGame({super.key});
  @override
  State<TypingKnightGame> createState() => _TypingKnightGameState();
}

class _TypingKnightGameState extends State<TypingKnightGame>
    with TickerProviderStateMixin {

  // ── Phase & stats ──────────────────────────────────────────────────────
  GamePhase       _phase = GamePhase.menu;
  KnightDifficulty _diff = KnightDifficulty.squire;
  int _score = 0, _highScore = 0, _kills = 0, _combo = 0, _maxCombo = 0;
  int _castleHp = 20, _castleMaxHp = 20;
  int _wave = 1;
  bool _paused = false;

  // ── Game objects ───────────────────────────────────────────────────────
  final List<Enemy>       _enemies   = [];
  final List<Fireball>    _fireballs = [];
  final List<Arrow>       _arrows    = [];
  final List<Particle>    _particles = [];
  final List<FloatingText>_floats    = [];
  final List<CastleCrack> _cracks    = [];
  final _rng = Random();

  // ── Typing ─────────────────────────────────────────────────────────────
  Enemy?    _lockedEnemy;
  Fireball? _lockedFire;

  // ── Boss ───────────────────────────────────────────────────────────────
  String _bossWord   = '';
  int    _bossTyped  = 0;
  double _bossHp     = 100;
  double _bossFlyT   = 0;
  double _bossFireCD = 0;
  double _bossBreathT  = 0;
  bool   _bossBreathing = false;
  double _bossEntryT    = 0;

  // ── Knight ─────────────────────────────────────────────────────────────
  double _knightSlashT   = 0;
  double _knightSlashDir = 1;
  double _knightIdleT    = 0;
  double _screenShake    = 0;
  double _knightX = 0, _knightY = 0;
  // Ninja fly-to target (set on each keystroke)
  double _knightTargetX = -1, _knightTargetY = -1;

  // ── Dragon ─────────────────────────────────────────────────────────────
  double _dragonX = 0, _dragonY = 0;
  double _dragonWingT = 0;

  // ── Torch ──────────────────────────────────────────────────────────────
  double _torchFlicker = 0;

  // ── Loop ───────────────────────────────────────────────────────────────
  Timer?    _loop, _spawnTimer;
  DateTime? _lastFrame;

  // ── Animations ─────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _bossShakeCtrl;

  // ── Layout ─────────────────────────────────────────────────────────────
  double _w = 900, _h = 600;
  double get _uiScale    => min(_w, _h) / 900.0;
  double get _fontScale  => _uiScale.clamp(0.7, 1.35);
  double get _groundY    => _h * 0.72;
  double get _castleX    => _w * 0.095;
  double get _knightBaseX => _castleX + (55 * _uiScale);
  double get _knightBaseY => _groundY - (6 * _uiScale);

  final FocusNode _focus = FocusNode();

  // ── Cached config (rebuilt only on difficulty change) ──────────────────
  late Map<String, dynamic> _cfg;
  late List<String>         _wordBank;

  void _rebuildConfig() {
    _cfg = {
      KnightDifficulty.squire: {
        'hp': 20, 'spawnMs': 2800, 'speedMul': 1.0,
        'fireRate': 4.0, 'maxEn': 4, 'bossAt': 8,
      },
      KnightDifficulty.knight: {
        'hp': 15, 'spawnMs': 2000, 'speedMul': 1.4,
        'fireRate': 2.8, 'maxEn': 6, 'bossAt': 8,
      },
      KnightDifficulty.legend: {
        'hp': 10, 'spawnMs': 1300, 'speedMul': 1.9,
        'fireRate': 1.8, 'maxEn': 8, 'bossAt': 6,
      },
    }[_diff]!;

    _wordBank = _diff == KnightDifficulty.legend
        ? [..._kMed, ..._kLong]
        : _diff == KnightDifficulty.knight
        ? [..._kShort, ..._kMed]
        : _kShort;
  }

  // ═══════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _rebuildConfig();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bossShakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadHs();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bossShakeCtrl.dispose();
    _loop?.cancel();
    _spawnTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadHs() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt('${ProfileService().keyPrefix}knight_hs_${_diff.name}') ?? 0;
    if (mounted) setState(() => _highScore = v);
  }

  Future<void> _saveHs() async {
    if (_score <= _highScore) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt('${ProfileService().keyPrefix}knight_hs_${_diff.name}', _score);
    if (mounted) setState(() => _highScore = _score);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  GAME LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════
  void _startGame() {
    _loop?.cancel();
    _spawnTimer?.cancel();
    setState(() {
      _phase        = GamePhase.playing;
      _score        = 0;
      _kills        = 0;
      _combo        = 0;
      _maxCombo     = 0;
      _wave         = 1;
      _castleMaxHp  = _cfg['hp'] as int;
      _castleHp     = _castleMaxHp;
      _paused       = false;
      _enemies.clear(); _fireballs.clear(); _arrows.clear();
      _particles.clear(); _floats.clear(); _cracks.clear();
      _lockedEnemy  = null;
      _lockedFire   = null;
      _bossHp       = 100;
      _bossTyped    = 0;
      _bossFlyT     = 0;
      _knightSlashT = 0;
      _knightIdleT  = 0;
      _screenShake  = 0;
      _dragonX      = _w * 0.7;
      _dragonY      = _h * 0.18;
    });
    _lastFrame = DateTime.now();
    _loop      = Timer.periodic(const Duration(milliseconds: 16), _tick);
    _scheduleSpawn();
  }

  void _endGame() {
    _loop?.cancel();
    _spawnTimer?.cancel();
    _saveHs();
    setState(() => _phase = GamePhase.gameOver);
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (!_paused) _lastFrame = DateTime.now();
  }

  // ── Spawn ───────────────────────────────────────────────────────────────
  void _scheduleSpawn() {
    if (_phase == GamePhase.gameOver ||
        _phase == GamePhase.bossEntry ||
        _phase == GamePhase.bossFight) return;
    final ms = (_cfg['spawnMs'] as int) + _rng.nextInt(600) - 300;
    _spawnTimer = Timer(Duration(milliseconds: ms.clamp(600, 5000)), () {
      if (_phase == GamePhase.playing && !_paused) {
        _spawnEnemy();
        _scheduleSpawn();
      }
    });
  }

  void _spawnEnemy() {
    if (_enemies.where((e) => !e.dying).length >= (_cfg['maxEn'] as int)) return;

    final used  = _enemies.map((e) => e.word).toSet();
    final avail = _wordBank.where((w) => !used.contains(w)).toList();
    if (avail.isEmpty) return;

    final word = avail[_rng.nextInt(avail.length)];
    final spd  = (_cfg['speedMul'] as double) * (30 + _rng.nextDouble() * 25 + _wave * 3);

    EnemyType type;
    final r = _rng.nextDouble();
    if (_wave <= 2) {
      type = r < 0.6 ? EnemyType.soldier : EnemyType.archer;
    } else if (_wave <= 4) {
      type = r < 0.4 ? EnemyType.soldier : r < 0.7 ? EnemyType.archer : EnemyType.troll;
    } else {
      type = r < 0.3 ? EnemyType.soldier
           : r < 0.55 ? EnemyType.archer
           : r < 0.75 ? EnemyType.troll
           : EnemyType.armored;
    }

    final hp = type == EnemyType.armored ? 2 : 1;
    final speedMul = type == EnemyType.troll ? 0.55
                   : type == EnemyType.armored ? 0.7 : 1.0;

    _enemies.add(Enemy(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      type: type, word: word,
      x: _w + 40, y: _groundY - 20,
      speed: spd * speedMul, hp: hp,
    ));
  }

  void _spawnFireball() {
    const letters = 'abcdefghijklmnopqrstuvwxyz';
    final usedLetters = _fireballs.map((f) => f.letter).toSet();
    final avail = letters.split('').where((l) => !usedLetters.contains(l)).toList();
    if (avail.isEmpty) return;

    final letter = avail[_rng.nextInt(avail.length)];
    final x = _w * 0.25 + _rng.nextDouble() * _w * 0.55;
    _fireballs.add(Fireball(
      id: '${DateTime.now().microsecondsSinceEpoch}_f',
      letter: letter,
      x: x, y: _h * 0.08,
      vx: (_rng.nextDouble() - 0.5) * 60,
      vy: 110 + _rng.nextDouble() * 60,
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TICK
  // ═══════════════════════════════════════════════════════════════════════
  void _tick(Timer timer) {
    if (_paused) return;
    final now = DateTime.now();
    final dt  = (now.difference(_lastFrame!).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastFrame = now;

    // ── Update all simulation state ───────────────────────────────────
    _knightIdleT  += dt * 1.8;
    _dragonWingT  += dt * 3.2;
    _torchFlicker += dt * 8;
    _screenShake   = (_screenShake - dt * 12).clamp(0.0, 12.0);

    if (_phase == GamePhase.playing)  _tickPlaying(dt);
    if (_phase == GamePhase.bossEntry) _tickBossEntry(dt);
    if (_phase == GamePhase.bossFight) _tickBossFight(dt);

    _tickKnight(dt);
    _tickParticles(dt);

    // Single setState per frame
    if (mounted) setState(() {});
  }

  void _tickPlaying(double dt) {
    _bossFlyT += dt * 0.6;
    _dragonX   = _w * 0.72 + sin(_bossFlyT * 0.8) * _w * 0.12;
    _dragonY   = _h * 0.14 + sin(_bossFlyT * 1.3) * _h * 0.06;

    _bossFireCD -= dt;
    if (_bossFireCD <= 0) {
      _bossFireCD = _cfg['fireRate'] as double;
      _spawnFireball();
    }

    _updateEnemies(dt);
    _updateFireballs(dt);
    _updateArrows(dt);

    if (_kills > 0 &&
        _kills % (_cfg['bossAt'] as int) == 0 &&
        _enemies.isEmpty &&
        _phase == GamePhase.playing) {
      _triggerBossEntry();
    }
  }

  void _updateEnemies(double dt) {
    for (final e in _enemies) {
      if (e.dying) { e.dyingT += dt * 2.5; continue; }
      e.x    -= e.speed * dt;
      e.walkT += dt * 4;

      if (e.type == EnemyType.archer) {
        e.arrowCooldown -= dt;
        if (e.arrowCooldown <= 0 && e.x < _w * 0.7) {
          e.arrowCooldown = 3.5 + _rng.nextDouble() * 2;
          _arrows.add(Arrow(x: e.x - 20, y: e.y - 30, vx: -260, vy: -30));
        }
      }

      if (e.x < _castleX + 30) {
        _damageCastle(
          e.type == EnemyType.troll   ? 3 :
          e.type == EnemyType.armored ? 2 : 1,
        );
        e.dying      = true;
        _lockedEnemy = null;
        _combo       = 0;
      }
    }
    _enemies.removeWhere((e) => e.dying && e.dyingT >= 1.0);
    if (_lockedEnemy != null && !_enemies.contains(_lockedEnemy)) {
      _lockedEnemy = null;
    }
  }

  void _updateFireballs(double dt) {
    for (final f in _fireballs) {
      if (f.dying) { f.dyingT += dt * 3; continue; }
      f.x   += f.vx * dt;
      f.y   += f.vy * dt;
      f.rot += dt * 4;
      if (f.y > _groundY + 10) {
        _damageCastle(1);
        _spawnParticles(f.x, _groundY, const Color(0xFFFF6D00), 10);
        f.dying = true;
        if (_lockedFire == f) _lockedFire = null;
      }
    }
    _fireballs.removeWhere((f) => f.dying && f.dyingT >= 1.0);
    if (_lockedFire != null && !_fireballs.contains(_lockedFire)) {
      _lockedFire = null;
    }
  }

  void _updateArrows(double dt) {
    for (final a in _arrows) {
      a.x  += a.vx * dt;
      a.y  += a.vy * dt;
      a.vy += 180 * dt;
      if (a.x < _castleX + 30 && !a.spent) {
        a.spent = true;
        _damageCastle(1);
      }
    }
    _arrows.removeWhere((a) => a.spent || a.x < 0 || a.y > _h);
  }

  void _tickBossEntry(double dt) {
    _bossEntryT  += dt * 0.7;
    _dragonX      = _w * 0.9 - _bossEntryT * _w * 0.45;
    _dragonY      = _h * 0.08 + sin(_bossEntryT * 3) * 20;
    _dragonWingT += dt * 5;
    if (_bossEntryT >= 1.4) {
      _dragonX   = _w * 0.55;
      _dragonY   = _h * 0.15;
      _bossWord  = _kBoss[_rng.nextInt(_kBoss.length)];
      _bossTyped = 0;
      _bossHp    = 100;
      _bossBreathT = 0;
      _phase = GamePhase.bossFight;
    }
  }

  void _tickBossFight(double dt) {
    _bossFlyT   += dt * 1.2;
    _dragonX     = _w * 0.52 + sin(_bossFlyT * 1.1) * 55;
    _dragonY     = _h * 0.12 + sin(_bossFlyT * 0.9) * 30;
    _dragonWingT += dt * 4;
    _bossBreathT += dt;
    _bossBreathing = sin(_bossBreathT * 2.5) > 0.3;
    if (_bossBreathing && _rng.nextDouble() < 0.08) {
      _spawnFireball();
    }
    _updateFireballs(dt);
    _updateArrows(dt);
  }

  void _tickKnight(double dt) {
    if (_knightSlashT > 0) {
      _knightSlashT = (_knightSlashT - dt * 2.6).clamp(0.0, 1.0);
    } else {
      // Clear target when slash is fully done
      _knightTargetX = -1;
    }

    final baseX = _knightBaseX;
    final baseY = _knightBaseY;

    // Initialise position on first frame
    if (_knightX == 0) { _knightX = baseX; _knightY = baseY; }

    // While slashing: fly toward target; otherwise drift back to base
    final goToTarget = _knightSlashT > 0.04 && _knightTargetX >= 0;
    final destX = goToTarget ? _knightTargetX : baseX;
    final destY = goToTarget ? _knightTargetY : baseY;

    // Fast lerp — feels like "dashing"
    final lf = (13.0 * dt).clamp(0.0, 1.0);
    _knightX += (destX - _knightX) * lf;
    _knightY += (destY - _knightY) * lf;

    // Parabolic arc: peaks halfway through the dash
    if (goToTarget) {
      final dx = (_knightTargetX - baseX).abs();
      final dy = (_knightTargetY - baseY).abs();
      final arcH = ((dx + dy) * 0.20).clamp(18.0, 70.0);
      _knightY -= sin(_knightSlashT * pi) * arcH;
    }
  }

  void _tickParticles(double dt) {
    for (final p in _particles) {
      p.x   += p.vx * dt;
      p.y   += p.vy * dt;
      p.vy  += 220 * dt;
      p.life -= dt * 1.6;
      p.rot  += dt * 5;
    }
    _particles.removeWhere((p) => p.life <= 0);
    for (final f in _floats) {
      f.y    -= dt * 55;
      f.life -= dt * 1.2;
    }
    _floats.removeWhere((f) => f.life <= 0);
    // Hard cap
    if (_floats.length > 20) _floats.removeRange(0, _floats.length - 20);
  }

  void _triggerBossEntry() {
    _spawnTimer?.cancel();
    _fireballs.clear();
    _bossEntryT  = 0;
    _lockedEnemy = null;
    _lockedFire  = null;
    setState(() => _phase = GamePhase.bossEntry);
    _bossShakeCtrl.forward(from: 0);
  }

  void _damageCastle(int dmg) {
    _castleHp    = (_castleHp - dmg).clamp(0, _castleMaxHp);
    _screenShake = 8;
    if (_cracks.length < 12) {
      final cx = _castleX + _rng.nextDouble() * 60;
      final cy = _groundY - 60 - _rng.nextDouble() * 80;
      _cracks.add(CastleCrack(
        Offset(cx, cy),
        Offset(cx + (_rng.nextDouble() - 0.5) * 30, cy + 10 + _rng.nextDouble() * 20),
      ));
    }
    if (_castleHp <= 0) _endGame();
  }

  void _spawnParticles(double x, double y, Color color, int count) {
    // Keep total particles bounded — critical for low-end performance
    if (_particles.length > 70) {
      _particles.removeRange(0, _particles.length - 50);
    }
    final burst = (count * 0.55).round().clamp(1, 14);
    for (int i = 0; i < burst; i++) {
      final a = _rng.nextDouble() * pi * 2;
      final s = 60 + _rng.nextDouble() * 200;
      _particles.add(Particle(
        x: x, y: y,
        vx: cos(a) * s, vy: sin(a) * s - 80,
        color: color,
        size: 2 + _rng.nextDouble() * 6,
        rot: _rng.nextDouble() * pi * 2,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  KEY HANDLER
  // ═══════════════════════════════════════════════════════════════════════
  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (_phase == GamePhase.menu || _phase == GamePhase.gameOver) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _togglePause();
      return;
    }
    if (_paused) return;

    String? ch;
    if (event.character != null && event.character!.isNotEmpty) {
      ch = event.character!.toLowerCase();
    } else {
      final lb = event.logicalKey.keyLabel;
      if (lb.length == 1) ch = lb.toLowerCase();
    }
    if (event.logicalKey == LogicalKeyboardKey.space) ch = ' ';
    if (ch == null) return;

    if (_phase == GamePhase.bossFight) { _typeBoss(ch); return; }
    if (_phase != GamePhase.playing)   return;

    // ── Try fireball first ─────────────────────────────────────────────
    if (_lockedFire != null) {
      if (ch == _lockedFire!.letter) { _killFireball(_lockedFire!); return; }
      SoundService().playError();
      return;
    }

    // ── Try enemy ──────────────────────────────────────────────────────
    if (_lockedEnemy != null) {
      final e        = _lockedEnemy!;
      final expected = e.word[e.typedSoFar];
      if (ch == expected) {
        SoundService().playKeyClick();
        e.typedSoFar++;
        // Fly ninja to this letter's position
        _knightTargetX  = e.x;
        _knightTargetY  = e.y - 22;
        _knightSlashT   = 0.88;
        _knightSlashDir = 1;
        if (mounted) setState(() {});
        if (e.typedSoFar >= e.word.length) {
          e.hp--;
          if (e.hp <= 0) {
            _killEnemy(e);
          } else {
            // Armored: reset and continue
            e.typedSoFar = 0;
            _spawnParticles(e.x, e.y - 20, const Color(0xFFCFD8DC), 6);
          }
        }
      } else {
        SoundService().playError();
        _combo = 0;
      }
      return;
    }

    // ── Auto-lock: fireballs first ─────────────────────────────────────
    final fbMatch = _fireballs.where((f) => !f.dying && f.letter == ch).toList();
    if (fbMatch.isNotEmpty) {
      _lockedFire = fbMatch.first;
      _killFireball(_lockedFire!);
      return;
    }

    // ── Auto-lock: closest enemy starting with ch ──────────────────────
    final matches = _enemies
        .where((e) => !e.dying && e.typedSoFar < e.word.length && e.word[0] == ch)
        .toList();
    if (matches.isEmpty) {
      SoundService().playError();
      _combo = 0;
      return;
    }

    _lockedEnemy = matches.reduce((a, b) => a.x < b.x ? a : b);
    _lockedEnemy!.targeted   = true;
    _lockedEnemy!.typedSoFar = 1;
    // Fly knight to this enemy for the first letter too
    _knightTargetX  = _lockedEnemy!.x;
    _knightTargetY  = _lockedEnemy!.y - 22;
    _knightSlashT   = 0.88;
    _knightSlashDir = 1;
    SoundService().playKeyClick();
    if (mounted) setState(() {});
  }

  void _killFireball(Fireball f) {
    SoundService().playKeyClick();
    _knightTargetX  = f.x;
    _knightTargetY  = f.y;
    _knightSlashT   = 1.0;
    _knightSlashDir = -1;
    _spawnParticles(f.x, f.y, const Color(0xFFFF6D00), 14);
    _floats.add(FloatingText(
      x: f.x, y: f.y - 20,
      text: '+5', color: const Color(0xFFFFAB40),
    ));
    _score += 5;
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    f.dying     = true;
    _lockedFire = null;
  }

  void _killEnemy(Enemy e) {
    e.dying      = true;
    _lockedEnemy = null;
    _kills++;
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _knightSlashT   = 1.0;
    _knightSlashDir = 1;

    final mult = _combo >= 8 ? 4 : _combo >= 5 ? 3 : _combo >= 3 ? 2 : 1;
    final pts  = (e.type == EnemyType.troll   ? 30
                : e.type == EnemyType.armored ? 40 : 10) * mult;
    _score += pts;

    final col = e.type == EnemyType.troll   ? const Color(0xFF8D6E63)
               : e.type == EnemyType.archer ? const Color(0xFF66BB6A)
               : e.type == EnemyType.armored ? const Color(0xFF90A4AE)
               : const Color(0xFFEF9A9A);
    _spawnParticles(e.x, e.y - 20, col, 16);

    String label = '+$pts';
    if      (_combo >= 8) label = '🔥 RAGE! +$pts';
    else if (_combo >= 5) label = '⚡ COMBO! +$pts';
    else if (_combo >= 3) label = '✨ x$_combo +$pts';
    _floats.add(FloatingText(
      x: e.x, y: e.y - 40,
      text: label,
      color: _combo >= 5 ? const Color(0xFFFFD700) : Colors.white,
    ));

    if (_kills > 0 &&
        _kills % (_cfg['bossAt'] as int) == 0 &&
        _enemies.where((e2) => !e2.dying).isEmpty) {
      _triggerBossEntry();
    } else if (_kills % 5 == 0) {
      _wave = 1 + _kills ~/ 5;
    }
  }

  void _typeBoss(String ch) {
    if (_bossTyped >= _bossWord.length) return;
    final expected = _bossWord[_bossTyped];

    if ((expected == ' ' && ch == ' ') || ch == expected) {
      _bossTyped++;
      SoundService().playKeyClick();
      _bossHp         = (100 - (_bossTyped / _bossWord.length * 100));
      _knightTargetX  = _dragonX - 70;
      _knightTargetY  = _dragonY + 10;
      _knightSlashT   = 0.65;
      _knightSlashDir = -1;
      _spawnParticles(_dragonX, _dragonY + 30, const Color(0xFFEF5350), 6);
    } else {
      SoundService().playError();
      _damageCastle(1);
    }

    if (_bossTyped >= _bossWord.length) {
      _score += 200 + _wave * 50;
      _floats.add(FloatingText(
        x: _dragonX, y: _dragonY,
        text: '🐉 DRAGON SLAIN! +${200 + _wave * 50}',
        color: const Color(0xFFFFD700),
      ));
      _spawnParticles(_dragonX, _dragonY, const Color(0xFFFF6D00), 40);
      _spawnParticles(_dragonX, _dragonY, const Color(0xFFFFD700), 20);
      _wave++;
      _kills++;
      _fireballs.clear();
      _lockedFire = null;
      setState(() => _phase = GamePhase.playing);
      _scheduleSpawn();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (ctx, box) {
            _w = box.maxWidth;
            _h = box.maxHeight;
            final shake = _screenShake > 0
                ? Offset(
                    sin(_knightIdleT * 30) * _screenShake * 0.5,
                    cos(_knightIdleT * 25) * _screenShake * 0.3,
                  )
                : Offset.zero;

            return Stack(
              children: [
                // Static background layer – repaints only on torch flicker
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(_w, _h),
                    painter: _BgPainter(_torchFlicker, _cracks, _castleHp, _castleMaxHp),
                  ),
                ),

                // All moving game objects in ONE painter
                Transform.translate(
                  offset: shake,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(_w, _h),
                      painter: _GamePainter(
                        enemies:    _enemies,
                        fireballs:  _fireballs,
                        arrows:     _arrows,
                        particles:  _particles,
                        floats:     _floats,
                        knight:     _buildKnightState(),
                        dragon: _DragonState(
                          x: _dragonX, y: _dragonY,
                          wingT: _dragonWingT,
                          breathing: _bossBreathing,
                          hp: _bossHp, phase: _phase,
                        ),
                        groundY:  _groundY,
                        pulse:    _pulseCtrl.value,
                        castleX:  _castleX,
                        screenW:  _w,
                        lockedEnemy: _lockedEnemy,
                        lockedFire:  _lockedFire,
                      ),
                    ),
                  ),
                ),

                // HUD (widget layer, lightweight)
                if (_phase == GamePhase.playing || _phase == GamePhase.bossFight)
                  _buildHud(),
                if (_phase == GamePhase.bossFight)  _buildBossBar(),
                if (_phase == GamePhase.bossEntry)  _buildBossEntry(),
                if (_paused)                         _buildPause(),
                if (_phase == GamePhase.menu)        _buildMenu(),
                if (_phase == GamePhase.gameOver)    _buildGameOver(),
              ],
            );
          },
        ),
      ),
    );
  }

  _KnightState _buildKnightState() => _KnightState(
    x:        _knightX == 0 ? _knightBaseX : _knightX,
    y:        _knightY == 0 ? _knightBaseY : _knightY,
    slashT:   _knightSlashT,
    slashDir: _knightSlashDir,
    idleT:    _knightIdleT,
    combo:    _combo,
  );

  // ── HUD ─────────────────────────────────────────────────────────────────
  Widget _buildHud() {
    final hpFrac  = _castleHp / _castleMaxHp;
    final hpColor = hpFrac > 0.6
        ? const Color(0xFF66BB6A)
        : hpFrac > 0.3
        ? const Color(0xFFFFAB40)
        : const Color(0xFFEF5350);

    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
          ),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🏰', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              const Text('CASTLE', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
            ]),
            const SizedBox(height: 3),
            Container(
              width: 120, height: 8,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: hpFrac,
                child: Container(
                  decoration: BoxDecoration(
                    color: hpColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: hpColor.withValues(alpha: 0.5), blurRadius: 4)],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text('$_castleHp / $_castleMaxHp', style: TextStyle(color: hpColor, fontSize: 10)),
          ]),
          const SizedBox(width: 20),
          _HudChip('SCORE', '$_score', const Color(0xFFFFD700)),
          const SizedBox(width: 12),
          _HudChip('BEST',  '$_highScore', const Color(0xFFFFAB40)),
          const SizedBox(width: 12),
          _HudChip('WAVE',  '$_wave', const Color(0xFF80CBC4)),
          const SizedBox(width: 12),
          if (_combo >= 2)
            _HudChip('COMBO', 'x$_combo', const Color(0xFFFF4081)),
          const Spacer(),
          GestureDetector(
            onTap: _togglePause,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pause_rounded, color: Colors.white54, size: 16),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Boss bar ──────────────────────────────────────────────────────────────
  Widget _buildBossBar() {
    final typed  = _bossWord.substring(0, _bossTyped);
    final remain = _bossWord.substring(_bossTyped);
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('🐉', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(5)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _bossHp / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF5350), Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [BoxShadow(color: Color(0xFFEF5350), blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${_bossHp.toStringAsFixed(0)}%',
                style: const TextStyle(color: Color(0xFFEF5350), fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.5)),
            ),
            child: RichText(text: TextSpan(children: [
              TextSpan(text: typed, style: const TextStyle(
                fontSize: 22, color: Color(0xFF80CBC4),
                fontFamily: 'monospace', fontWeight: FontWeight.bold,
              )),
              TextSpan(
                text: remain.isNotEmpty ? remain[0] : '',
                style: TextStyle(
                  fontSize: 22, color: Colors.white,
                  fontFamily: 'monospace', fontWeight: FontWeight.bold,
                  background: Paint()..color = const Color(0xFFEF5350).withValues(alpha: 0.35),
                ),
              ),
              TextSpan(
                text: remain.length > 1 ? remain.substring(1) : '',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontFamily: 'monospace', fontWeight: FontWeight.bold,
                ),
              ),
            ])),
          ),
          const SizedBox(height: 6),
          Text(
            '🔥 Type to wound the dragon — it breathes fire while you type!',
            style: TextStyle(color: Colors.orange.shade300, fontSize: 11),
          ),
        ]),
      ),
    );
  }

  // ── Boss entry banner ──────────────────────────────────────────────────────
  Widget _buildBossEntry() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🐉', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFF8F00), Color(0xFFEF5350)],
            ).createShader(b),
            child: const Text('DRAGON APPROACHES', style: TextStyle(
              fontSize: 34, fontWeight: FontWeight.bold,
              color: Colors.white, letterSpacing: 4,
            )),
          ),
          const SizedBox(height: 10),
          Text('Wave ${_wave + 1} — Prepare your sword!',
              style: const TextStyle(color: Colors.white54, fontSize: 16)),
        ]),
      ),
    );
  }

  // ── Pause ──────────────────────────────────────────────────────────────────
  Widget _buildPause() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('⏸', style: TextStyle(fontSize: (48 * _uiScale).clamp(28, 70))),
            SizedBox(height: (10 * _uiScale).clamp(6, 14)),
            Text('PAUSED', style: TextStyle(
              fontSize: (22 * _fontScale).clamp(16, 28),
              color: Colors.white, letterSpacing: 3 * _fontScale,
              fontWeight: FontWeight.bold,
            )),
            SizedBox(height: (20 * _uiScale).clamp(10, 28)),
            ElevatedButton(
              onPressed: _togglePause,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                padding: EdgeInsets.symmetric(
                  horizontal: (28 * _uiScale).clamp(16, 44),
                  vertical:   (10 * _uiScale).clamp(8, 16),
                ),
              ),
              child: const Text('RESUME', style: TextStyle(color: Colors.white, letterSpacing: 2)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Menu ───────────────────────────────────────────────────────────────────
  Widget _buildMenu() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: (_w * 0.85).clamp(320, 640)),
        margin:  EdgeInsets.all((16 * _uiScale).clamp(10, 24)),
        padding: EdgeInsets.all((20 * _uiScale).clamp(14, 30)),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFB71C1C).withValues(alpha: 0.6)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('⚔️', style: TextStyle(fontSize: (64 * _uiScale).clamp(34, 76))),
          SizedBox(height: (10 * _uiScale).clamp(6, 14)),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
            ).createShader(b),
            child: Text('TYPING KNIGHT', style: TextStyle(
              fontSize: (30 * _fontScale).clamp(18, 36),
              fontWeight: FontWeight.bold,
              color: Colors.white, letterSpacing: 3 * _fontScale,
            )),
          ),
          SizedBox(height: (4 * _uiScale).clamp(2, 8)),
          Text("Kingdom's Last Stand", style: TextStyle(
            color: Colors.white38, fontSize: (13 * _fontScale).clamp(10, 18), letterSpacing: 1,
          )),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _diffBtn('Squire', KnightDifficulty.squire, const Color(0xFF66BB6A)),
            const SizedBox(width: 8),
            _diffBtn('Knight', KnightDifficulty.knight, const Color(0xFFFFAB40)),
            const SizedBox(width: 8),
            _diffBtn('Legend', KnightDifficulty.legend, const Color(0xFFEF5350)),
          ]),
          const SizedBox(height: 20),
          if (_highScore > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text('🏆 Best: $_highScore',
                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              _infoRow('⚔️', 'Type the word on each enemy to slash them'),
              _infoRow('🔥', 'Type the letter on fireballs to deflect them'),
              _infoRow('🐉', 'Boss — type the full sentence to slay the dragon'),
              _infoRow('🏰', 'Protect the castle — it has limited HP'),
              _infoRow('⚡', 'Combo x3/x5/x8 = 2×/3×/4× bonus score'),
            ]),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('DEFEND THE KINGDOM', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2,
              )),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('← Back to Hub', style: TextStyle(color: Colors.white30, fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  // ── Game over ──────────────────────────────────────────────────────────────
  Widget _buildGameOver() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin:  const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFB71C1C).withValues(alpha: 0.5)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏰', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 6),
          const Text('CASTLE FALLEN', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold,
            color: Color(0xFFEF5350), letterSpacing: 3,
          )),
          const SizedBox(height: 4),
          const Text('The kingdom remembers your sacrifice...',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(children: [
            _StatBox('SCORE', '$_score', const Color(0xFFFFD700)),
            _StatBox('BEST',  '$_highScore', const Color(0xFFFFAB40)),
            _StatBox('KILLS', '$_kills', const Color(0xFF66BB6A)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _StatBox('WAVE',      '$_wave', const Color(0xFF80CBC4)),
            _StatBox('MAX COMBO', 'x$_maxCombo', const Color(0xFFFF4081)),
            _StatBox('CASTLE',    '$_castleHp HP', const Color(0xFFEF5350)),
          ]),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('AGAIN'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: _startGame,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.castle, size: 16),
                label: const Text('HUB'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _diffBtn(String label, KnightDifficulty d, Color color) {
    final sel = _diff == d;
    return GestureDetector(
      onTap: () {
        if (_diff == d) return;
        setState(() { _diff = d; });
        _rebuildConfig();
        _loadHs();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? color : Colors.white24),
        ),
        child: Text(label, style: TextStyle(
          color: sel ? color : Colors.white38,
          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DATA CLASSES FOR PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _KnightState {
  final double x, y, slashT, slashDir, idleT;
  final int combo;
  const _KnightState({
    required this.x, required this.y, required this.slashT,
    required this.slashDir, required this.idleT, required this.combo,
  });
}

class _DragonState {
  final double x, y, wingT, hp;
  final bool breathing;
  final GamePhase phase;
  const _DragonState({
    required this.x, required this.y, required this.wingT,
    required this.hp, required this.breathing, required this.phase,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  BACKGROUND PAINTER  (repaints only on torch / crack / hp changes)
// ═══════════════════════════════════════════════════════════════════════════
class _BgPainter extends CustomPainter {
  final double torchT;
  final List<CastleCrack> cracks;
  final int castleHp, castleMaxHp;
  _BgPainter(this.torchT, this.cracks, this.castleHp, this.castleMaxHp);

  static final _rng = Random(7);
  static final List<_Star> _stars = List.generate(
    45,
    (i) => _Star(_rng.nextDouble(), _rng.nextDouble() * 0.5,
                 0.5 + _rng.nextDouble() * 1.8, _rng.nextDouble()),
  );

  // Cache background gradient shader – only rebuild on size change
  static Shader? _bgShader;
  static Size    _bgShaderSize = Size.zero;

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    final groundY = H * 0.72;

    if (size != _bgShaderSize) {
      _bgShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF04060F), Color(0xFF0D0A24), Color(0xFF1A0A14), Color(0xFF2E0A0A)],
        stops: const [0, 0.4, 0.7, 1],
      ).createShader(Rect.fromLTWH(0, 0, W, H));
      _bgShaderSize = size;
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H), Paint()..shader = _bgShader);

    // Stars
    final starP = Paint();
    for (final s in _stars) {
      final tw = 0.3 + 0.7 * sin(torchT * 0.3 + s.twinkle * pi * 2);
      starP.color = Colors.white.withValues(alpha: tw * 0.7);
      canvas.drawCircle(Offset(s.x * W, s.y * H), s.r, starP);
    }

    _drawMoon(canvas, W * 0.78, H * 0.1);

    // Distant fire glow
    final glowP = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    for (int i = 0; i < 4; i++) {
      final sx = W * (0.3 + i * 0.12);
      glowP.color = const Color(0xFFFF3D00)
          .withValues(alpha: 0.06 + sin(torchT + i) * 0.03);
      canvas.drawCircle(Offset(sx, groundY * 0.85), 50, glowP);
    }
    glowP.maskFilter = null;

    _drawMountains(canvas, size, groundY);
    _drawGround(canvas, size, groundY);
    _drawCastle(canvas, size, groundY);

    // Cracks
    final crackP = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final c in cracks) {
      canvas.drawLine(c.a, c.b, crackP);
    }

    _drawTorch(canvas, 78, groundY - 88,  torchT);
    _drawTorch(canvas, 78, groundY - 140, torchT + 1.2);
  }

  void _drawMoon(Canvas canvas, double x, double y) {
    final glow = Paint()
      ..color = Colors.amber.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(x, y), 70, glow);
    canvas.drawCircle(Offset(x, y), 32, Paint()..color = const Color(0xFFF5E6B0));
    canvas.drawCircle(Offset(x + 10, y - 5), 28, Paint()..color = const Color(0xFF100820));
    final craterP = Paint()..color = const Color(0xFFE8D898).withValues(alpha: 0.5);
    for (final c in [Offset(x - 8, y + 6), Offset(x + 2, y - 10)]) {
      canvas.drawCircle(c, 4, craterP);
    }
  }

  void _drawMountains(Canvas canvas, Size size, double groundY) {
    final p = Paint()..color = const Color(0xFF080616);
    final path = Path()..moveTo(0, groundY);
    const peaks = [0.05, 0.18, 0.28, 0.4, 0.52, 0.62, 0.74, 0.85, 0.95, 1.05];
    const hs    = [0.68, 0.56, 0.63, 0.52, 0.6, 0.66, 0.58, 0.64, 0.7, 0.72];
    for (int i = 0; i < peaks.length - 1; i++) {
      final mx = (peaks[i] + peaks[i + 1]) / 2 * size.width;
      final my = (hs[i] + hs[i + 1]) / 2 * size.height;
      path.quadraticBezierTo(peaks[i] * size.width, hs[i] * size.height, mx, my);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawGround(Canvas canvas, Size size, double groundY) {
    canvas.drawRect(Rect.fromLTRB(0, groundY, size.width, size.height),
        Paint()..color = const Color(0xFF120C08));
    final stonePaint = Paint()..color = const Color(0xFF2A1F16);
    final stoneLine  = Paint()
      ..color = const Color(0xFF0A0806) ..strokeWidth = 1 ..style = PaintingStyle.stroke;
    const rows = 3;
    const cols = 14;
    final sw = size.width / cols;
    final sh = (size.height - groundY) / rows;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final offset = (r % 2 == 0) ? 0.0 : sw * 0.5;
        final rect = Rect.fromLTWH(c * sw + offset - sw * 0.5, groundY + r * sh, sw - 2, sh - 2);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(2));
        canvas.drawRRect(rr, stonePaint);
        canvas.drawRRect(rr, stoneLine);
      }
    }
    // Ground glow
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, 40),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFFFF3D00).withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, groundY, size.width, 40)),
    );
  }

  void _drawCastle(Canvas canvas, Size size, double groundY) {
    final dmgFrac  = castleHp / castleMaxHp;
    final stoneCol = Color.lerp(const Color(0xFF3E2C1A), const Color(0xFF554033), dmgFrac)!;
    final darkCol  = Color.lerp(const Color(0xFF1A0E08), const Color(0xFF2E2018), dmgFrac)!;

    final sp = Paint()..color = stoneCol;
    final dp = Paint()..color = darkCol;
    const cx = 0.0;
    final baseY = groundY;

    // Tower
    canvas.drawRect(Rect.fromLTWH(cx, baseY - 200, 80, 200), sp);
    // Battlements
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(cx + i * 20, baseY - 220, 14, 24), sp);
    }
    // Gate
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 22, baseY - 70, 36, 55), const Radius.circular(18)),
      Paint()..color = const Color(0xFF0A0604),
    );
    // Window
    canvas.drawRect(Rect.fromLTWH(cx + 28, baseY - 140, 24, 32), dp);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 30, baseY - 138, 20, 28), const Radius.circular(10)),
      Paint()..color = const Color(0xFFFF6D00).withValues(alpha: 0.35),
    );
    // Side wall
    canvas.drawRect(Rect.fromLTWH(cx + 80, baseY - 100, size.width * 0.18, 100), sp);
    // Wall battlements
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(Rect.fromLTWH(cx + 82 + i * 22, baseY - 116, 14, 18), sp);
    }
    // Stone lines
    final linePaint = Paint()..color = darkCol.withValues(alpha: 0.6) ..strokeWidth = 1;
    for (int r = 1; r < 10; r++) {
      canvas.drawLine(Offset(cx, baseY - r * 20), Offset(cx + 80, baseY - r * 20), linePaint);
    }
    // Damage glow
    if (dmgFrac < 0.5) {
      canvas.drawRect(
        Rect.fromLTWH(cx, baseY - 200, 80, 200),
        Paint()
          ..color = const Color(0xFFFF3D00).withValues(alpha: (0.5 - dmgFrac) * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }
  }

  void _drawTorch(Canvas canvas, double x, double y, double t) {
    final bPaint = Paint()..color = const Color(0xFF4A3520);
    canvas.drawRect(Rect.fromLTWH(x - 3, y, 6, 14), bPaint);
    canvas.drawRect(Rect.fromLTWH(x - 5, y + 10, 10, 4), bPaint);
    final intensity = 0.55 + 0.45 * sin(t);
    canvas.drawCircle(
      Offset(x, y - 4), 22,
      Paint()
        ..color = const Color(0xFFFF6D00).withValues(alpha: intensity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    for (final c in [
      [const Color(0xFFFFD600), 5.0],
      [const Color(0xFFFF6D00), 7.0],
      [const Color(0xFFFF1744), 4.0],
    ]) {
      final fl = sin(t * 1.4 + (c[1] as double)) * 3;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + fl, y - 8), width: c[1] as double, height: 14),
        Paint()..color = (c[0] as Color).withValues(alpha: intensity),
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter o) {
    // Quantise torchT to ~8 fps flicker so bg doesn't repaint every frame
    final qt  = (torchT * 8).floor();
    final oqt = (o.torchT * 8).floor();
    return qt != oqt || o.castleHp != castleHp || o.cracks.length != cracks.length;
  }
}

class _Star {
  final double x, y, r, twinkle;
  _Star(this.x, this.y, this.r, this.twinkle);
}

// ═══════════════════════════════════════════════════════════════════════════
//  MAIN GAME PAINTER  (single unified painter – replaces per-enemy widgets)
// ═══════════════════════════════════════════════════════════════════════════
class _GamePainter extends CustomPainter {
  final List<Enemy>        enemies;
  final List<Fireball>     fireballs;
  final List<Arrow>        arrows;
  final List<Particle>     particles;
  final List<FloatingText> floats;
  final _KnightState       knight;
  final _DragonState       dragon;
  final double groundY, pulse, castleX, screenW;
  final Enemy?    lockedEnemy;
  final Fireball? lockedFire;

  _GamePainter({
    required this.enemies, required this.fireballs, required this.arrows,
    required this.particles, required this.floats, required this.knight,
    required this.dragon, required this.groundY, required this.pulse,
    required this.castleX, required this.screenW,
    required this.lockedEnemy, required this.lockedFire,
  });

  static final _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    _drawParticles(canvas);
    _drawArrows(canvas);
    _drawEnemies(canvas);
    _drawFireballs(canvas);
    _drawDragon(canvas, size);
    _drawKnight(canvas);
    _drawFloats(canvas);
  }

  // ── Particles ──────────────────────────────────────────────────────────────
  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      _p
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))
        ..style  = PaintingStyle.fill;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        _p,
      );
      canvas.restore();
    }
  }

  // ── Arrows ─────────────────────────────────────────────────────────────────
  void _drawArrows(Canvas canvas) {
    _p
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final a in arrows) {
      final angle = atan2(a.vy, a.vx);
      canvas.save();
      canvas.translate(a.x, a.y);
      canvas.rotate(angle);
      canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), _p);
      canvas.drawLine(const Offset(8,  0), const Offset(4, -4), _p);
      canvas.drawLine(const Offset(8,  0), const Offset(4,  4), _p);
      canvas.restore();
    }
  }

  // ── Enemies ────────────────────────────────────────────────────────────────
  void _drawEnemies(Canvas canvas) {
    for (final e in enemies) {
      final opacity = e.dying ? (1 - e.dyingT).clamp(0.0, 1.0) : 1.0;
      canvas.save();
      canvas.translate(e.x, e.y);
      if (e.dying) {
        canvas.translate(e.dyingT * 20, 0);
        canvas.rotate(e.dyingT * 0.8);
      }
      _drawEnemy(canvas, e, opacity);
      canvas.restore();
    }
  }

  void _drawEnemy(Canvas canvas, Enemy e, double opacity) {
    final isTargeted = e.targeted && !e.dying;

    if (isTargeted) {
      _p
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.25 + pulse * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(0, -20), 28, _p);
      _p.maskFilter = null;
    }

// placeholder – computed below
    final bc = {
      EnemyType.soldier: const Color(0xFF5D4037),
      EnemyType.archer:  const Color(0xFF2E7D32),
      EnemyType.troll:   const Color(0xFF4A148C),
      EnemyType.armored: const Color(0xFF37474F),
    }[e.type]!;

    final walkSin = sin(e.walkT) * 8;

    // Shadow
    _p
      ..color = Colors.black.withValues(alpha: 0.4 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 4), width: 28, height: 8), _p);
    _p.maskFilter = null;

    // Legs
    _p
      ..color = const Color(0xFF212121).withValues(alpha: opacity)
      ..strokeWidth = e.type == EnemyType.troll ? 8 : 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-6, 4), Offset(-8 + walkSin, 20), _p);
    canvas.drawLine(Offset( 6, 4), Offset( 8 - walkSin, 20), _p);

    // Body
    final sz = e.type == EnemyType.troll ? 1.4 : e.type == EnemyType.armored ? 1.15 : 1.0;
    final bodyPath = Path()
      ..moveTo(-11 * sz, -8)
      ..lineTo(-10 * sz,  6)
      ..lineTo( 10 * sz,  6)
      ..lineTo( 11 * sz, -8)
      ..close();
    _p
      ..color = bc.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, _p);

    if (e.type == EnemyType.armored) {
      _p
        ..color = const Color(0xFF546E7A).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke ..strokeWidth = 1.5;
      canvas.drawRect(Rect.fromLTWH(-10, -6, 20, 12), _p);
      _p.style = PaintingStyle.fill;
    }

    // Arms
    _p
      ..color = bc.withValues(alpha: opacity)
      ..strokeWidth = e.type == EnemyType.troll ? 7 : 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (e.type == EnemyType.archer) {
      canvas.drawLine(const Offset(-10, -4), const Offset(-22, 4), _p);
      final bowP = Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: opacity)
        ..strokeWidth = 2 ..style = PaintingStyle.stroke;
      canvas.drawPath(Path()..moveTo(-22, -8)..quadraticBezierTo(-30, 2, -22, 12), bowP);
      canvas.drawLine(const Offset(-22, 2), Offset(-22 + walkSin * 0.3, 2),
          Paint()..color = const Color(0xFF8D6E63).withValues(alpha: opacity)
            ..strokeWidth = 1.5 ..style = PaintingStyle.stroke);
    } else {
      canvas.drawLine(const Offset(-10, -4), const Offset(-22, 4), _p);
      canvas.drawLine(const Offset( 10, -4), const Offset( 22, 4), _p);
      final wpnP = Paint()
        ..color = const Color(0xFFBDBDBD).withValues(alpha: opacity)
        ..strokeWidth = 3 ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
      if (e.type == EnemyType.troll) {
        canvas.drawLine(const Offset(22, 4), const Offset(36, -14), wpnP..strokeWidth = 5);
        canvas.drawCircle(const Offset(36, -14), 7,
            Paint()..color = const Color(0xFF5D4037).withValues(alpha: opacity));
      } else {
        canvas.drawLine(const Offset(22, 4), const Offset(34, -12), wpnP);
      }
    }

    // Head
    _p.style = PaintingStyle.fill;
    _p.color = (e.type == EnemyType.troll ? const Color(0xFF7B1FA2) : const Color(0xFFA1887F))
        .withValues(alpha: opacity);
    canvas.drawCircle(Offset(0, -18), e.type == EnemyType.troll ? 14 : 10, _p);

    if (e.type == EnemyType.soldier || e.type == EnemyType.armored) {
      _p.color = const Color(0xFF616161).withValues(alpha: opacity);
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, -22), width: 22, height: 14), _p);
      _p.color = const Color(0xFF424242).withValues(alpha: opacity);
      canvas.drawRect(Rect.fromLTWH(-3, -19, 6, 8), _p);
    }
    if (e.type == EnemyType.troll) {
      _p.color = const Color(0xFF4A148C).withValues(alpha: opacity);
      canvas.drawOval(Rect.fromCenter(center: const Offset(-8, -30), width: 6, height: 14), _p);
      canvas.drawOval(Rect.fromCenter(center: const Offset( 8, -30), width: 6, height: 14), _p);
    }

    // Word label
    _drawEnemyWord(canvas, e, opacity, isTargeted);
  }

  void _drawEnemyWord(Canvas canvas, Enemy e, double opacity, bool isTargeted) {
    final typed   = e.word.substring(0, e.typedSoFar);
    final current = e.typedSoFar < e.word.length ? e.word[e.typedSoFar] : '';
    final remain  = e.typedSoFar < e.word.length ? e.word.substring(e.typedSoFar + 1) : '';

    final wordW  = e.word.length * 10.0 + 16;
    final bubbleY = -44.0 - (e.type == EnemyType.troll ? 8 : 0);

    _p
      ..color = (isTargeted ? const Color(0xFF1A1200) : Colors.black).withValues(alpha: 0.8 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, bubbleY), width: wordW, height: 20),
        const Radius.circular(5),
      ),
      _p,
    );
    if (isTargeted) {
      _p
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.4 * opacity)
        ..style = PaintingStyle.stroke ..strokeWidth = 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, bubbleY), width: wordW, height: 20),
          const Radius.circular(5),
        ),
        _p,
      );
    }

    if (e.maxHp > 1) {
      _p..color = Colors.black.withValues(alpha: 0.6) ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, bubbleY + 14), width: wordW, height: 4),
          const Radius.circular(2),
        ),
        _p,
      );
      _p.color = const Color(0xFFEF5350).withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-wordW / 2, bubbleY + 12, wordW * e.hp / e.maxHp, 4),
          const Radius.circular(2),
        ),
        _p,
      );
    }

    double xOff = -e.word.length * 5.0;
    if (typed.isNotEmpty) {
      final tp = _tp(typed, 11, const Color(0xFF80CBC4).withValues(alpha: 1.0), bold: true);
      tp.paint(canvas, Offset(xOff, bubbleY - tp.height / 2));
      xOff += tp.width;
    }
    if (current.isNotEmpty) {
      final tp = _tp(current, 13, Colors.white, bold: true, highlight: true);
      tp.paint(canvas, Offset(xOff, bubbleY - tp.height / 2));
      xOff += tp.width;
    }
    if (remain.isNotEmpty) {
      final tp = _tp(remain, 11, Colors.white.withValues(alpha: 0.55));
      tp.paint(canvas, Offset(xOff, bubbleY - tp.height / 2));
    }
  }

  TextPainter _tp(String text, double size, Color color,
      {bool bold = false, bool highlight = false}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size, color: color, fontFamily: 'monospace',
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          background: highlight
              ? (Paint()..color = const Color(0xFFB71C1C).withValues(alpha: 0.5))
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  // ── Fireballs ──────────────────────────────────────────────────────────────
  void _drawFireballs(Canvas canvas) {
    for (final f in fireballs) {
      final opacity = f.dying ? (1 - f.dyingT).clamp(0.0, 1.0) : 1.0;
      canvas.save();
      canvas.translate(f.x, f.y);
      canvas.rotate(f.rot);

      _p
        ..color = const Color(0xFFFF6D00).withValues(alpha: 0.25 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, 22, _p);
      _p.maskFilter = null;

      for (final layer in [
        [22.0, const Color(0xFFFF3D00)],
        [17.0, const Color(0xFFFF6D00)],
        [12.0, const Color(0xFFFFAB40)],
        [ 7.0, const Color(0xFFFFFF8D)],
      ]) {
        _p.color = (layer[1] as Color).withValues(alpha: opacity);
        canvas.drawCircle(Offset.zero, layer[0] as double, _p);
      }

      // Counter-rotate canvas so the letter always reads upright
      canvas.rotate(-f.rot);

      // High-contrast dark pill behind the letter
      _p
        ..color = Colors.black.withValues(alpha: 0.82 * opacity)
        ..maskFilter = null
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, 15, _p);
      // Thin orange ring for flavour
      _p
        ..color = const Color(0xFFFF6D00).withValues(alpha: 0.55 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset.zero, 15, _p);
      _p.style = PaintingStyle.fill;

      final ltp = TextPainter(
        text: TextSpan(
          text: f.letter.toUpperCase(),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: opacity),
            shadows: const [
              Shadow(blurRadius: 1, color: Colors.black),
              Shadow(blurRadius: 6, color: Color(0xFFFFAB40)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ltp.paint(canvas, Offset(-ltp.width / 2, -ltp.height / 2));
      canvas.restore();
    }
  }

  // ── Dragon ─────────────────────────────────────────────────────────────────
  void _drawDragon(Canvas canvas, Size size) {
    final isBoss = dragon.phase == GamePhase.bossFight ||
                   dragon.phase == GamePhase.bossEntry;
    final scale  = isBoss ? 1.6 : 0.85;

    canvas.save();
    canvas.translate(dragon.x, dragon.y);
    canvas.scale(scale);

    _p
      ..color = const Color(0xFFD32F2F).withValues(alpha: isBoss ? 0.25 : 0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isBoss ? 18.0 : 10.0)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 90, height: 50), _p);
    _p.maskFilter = null;

    _drawDragonWing(canvas, dragon.wingT, left: true);
    _drawDragonWing(canvas, dragon.wingT, left: false);

    // Tail
    final tailP = Paint()
      ..color = const Color(0xFF7B1FA2)
      ..style = PaintingStyle.stroke ..strokeWidth = 8 ..strokeCap = StrokeCap.round;
    final tail = Path()..moveTo(30, 10)..quadraticBezierTo(60, 30, 80, 10)
                       ..quadraticBezierTo(100, -5, 90, 20);
    canvas.drawPath(tail, tailP);
    _p.color = const Color(0xFF4A148C);
    for (double t = 0.3; t <= 0.8; t += 0.25) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(30 + t * 60, 10 + sin(t * pi) * 20), width: 6, height: 10),
        _p,
      );
    }

    // Body
    _p.color = const Color(0xFF7B1FA2);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 70, height: 40), _p);
    _p.color = const Color(0xFF9C4DCC);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 6), width: 44, height: 26), _p);
    _p.color = const Color(0xFF4A148C);
    for (int i = -2; i <= 2; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(i * 14.0, -20.0 - (i == 0 ? 6 : 0)), width: 7, height: 14),
        _p,
      );
    }

    // Neck + head
    _p.color = const Color(0xFF7B1FA2);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-30, -15), width: 22, height: 30), _p);
    _p.color = const Color(0xFF6A1B9A);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-50, -22), width: 38, height: 26), _p);
    _p.color = const Color(0xFF7B1FA2);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-66, -20), width: 22, height: 16), _p);

    // Nostril glow
    _p..color = const Color(0xFFFF1744).withValues(alpha: 0.7)
       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(-72, -18), 4, _p);
    _p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(const Offset(-64, -16), 3, _p);
    _p.maskFilter = null;

    // Eye
    _p.color = const Color(0xFFFFD600);
    canvas.drawCircle(const Offset(-44, -26), 6, _p);
    _p.color = Colors.black;
    canvas.drawCircle(const Offset(-42, -26), 3, _p);
    _p.color = Colors.white;
    canvas.drawCircle(const Offset(-41, -27), 1.5, _p);

    // Horns
    _p.color = const Color(0xFF4A148C);
    for (final hx in [-44.0, -36.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(hx, -34), width: 7, height: 14), _p);
    }

    // Fire breath
    if (dragon.breathing && isBoss) {
      for (int i = 0; i < 4; i++) {
        final len    = 40.0 + i * 20;
        final spread = i * 8.0;
        _p.color = [
          const Color(0xFFFF1744),
          const Color(0xFFFF6D00),
          const Color(0xFFFFAB40),
          const Color(0xFFFFFF8D),
        ][i].withValues(alpha: 0.7 - i * 0.15);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(-78 - len * 0.5, -18 + spread * 0.2),
            width: len, height: 12 + spread,
          ),
          _p,
        );
      }
    }

    // Boss HP bar
    if (isBoss) {
      const barW = 90.0;
      _p.color = Colors.black.withValues(alpha: 0.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 40), width: barW, height: 8),
          const Radius.circular(4),
        ),
        _p,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-barW / 2, 36, barW * dragon.hp / 100, 8),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFEF5350)
               ..shader = const LinearGradient(
                  colors: [Color(0xFFEF5350), Color(0xFFFF8F00)],
               ).createShader(Rect.fromLTWH(-barW / 2, 36, barW, 8)),
      );
    }

    canvas.restore();
  }

  void _drawDragonWing(Canvas canvas, double wt, {required bool left}) {
    final sign  = left ? -1.0 : 1.0;
    final angle = sign * (0.3 + sin(wt) * 0.5);
    canvas.save();
    canvas.rotate(angle);
    final wingP = Paint()..color = const Color(0xFF4A148C).withValues(alpha: 0.85);
    final memP  = Paint()
      ..color = const Color(0xFF6A1B9A).withValues(alpha: 0.55)
      ..style  = PaintingStyle.stroke ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(0, -10)
      ..lineTo(sign * 70, -60 + sin(wt) * 20)
      ..lineTo(sign * 90, -30 + sin(wt) * 15)
      ..lineTo(sign * 60,  10)
      ..lineTo(sign * 30,  20)
      ..close();
    canvas.drawPath(path, wingP);
    for (double t = 0.2; t < 0.9; t += 0.25) {
      canvas.drawLine(
        Offset(sign * t * 30, 0),
        Offset(sign * t * 90, -60 + sin(wt) * 20 + t * 30),
        memP,
      );
    }
    canvas.restore();
  }

  // ── Knight ──────────────────────────────────────────────────────────────────
  void _drawKnight(Canvas canvas) {
    final x = knight.x;
    final y = knight.y;
    final st = knight.slashT;
    final it = knight.idleT;
    final isSlashing = st > 0;
    final dir = knight.slashDir;
    final idle = sin(it) * 2.5;

    canvas.save();
    canvas.translate(x, y + idle);

    // Shadow
    _p
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 6), width: 40, height: 12), _p);
    _p.maskFilter = null;

    // Cape
    final capeP = Paint()
      ..color = const Color(0xFFB71C1C)
      ..strokeWidth = 10 ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()..moveTo(-10, -30)..quadraticBezierTo(-22, 0, -18 + sin(it * 0.8) * 6, 22),
      capeP,
    );

    // Legs
    final legP = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 7 ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-6, 8), const Offset(-10, 28), legP);
    canvas.drawLine(const Offset( 6, 8), const Offset( 10, 28), legP);
    final bootP = Paint()..color = const Color(0xFF37474F);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-13, 24, 12, 7), const Radius.circular(3)), bootP);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(  5, 24, 12, 7), const Radius.circular(3)), bootP);

    // Body armor
    final armorP = Paint()..color = const Color(0xFF546E7A);
    canvas.drawPath(
      Path()..moveTo(-13, -12)..lineTo(-12, 10)..lineTo(12, 10)..lineTo(13, -12)..close(),
      armorP,
    );
    final lineP = Paint()..strokeWidth = 1.5 ..style = PaintingStyle.stroke;
    lineP.color = const Color(0xFF37474F);
    canvas.drawLine(const Offset(-12, -4), const Offset(12, -4), lineP);
    lineP.strokeWidth = 1;
    canvas.drawLine(const Offset(0, -12), const Offset(0, 10), lineP);
    _p.color = const Color(0xFFFFD700).withValues(alpha: 0.5);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -2), width: 12, height: 10), _p);

    // Shield
    final shieldPath = Path()
      ..moveTo(-18, -16) ..lineTo(-28, -10) ..lineTo(-28, 6)
      ..quadraticBezierTo(-28, 14, -22, 18) ..lineTo(-18, 14) ..close();
    canvas.drawPath(shieldPath, Paint()..color = const Color(0xFF1565C0));
    canvas.drawPath(shieldPath, Paint()
      ..color = const Color(0xFF0D47A1)
      ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
    final crossP = Paint()..color = const Color(0xFFFFD700) ..strokeWidth = 2 ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-23, -4), const Offset(-23,  8), crossP);
    canvas.drawLine(const Offset(-27,  2), const Offset(-19,  2), crossP);

    // Arms & sword
    if (isSlashing) {
      double swingA;
      if (dir > 0) swingA = -pi * 0.6 + st * pi * 1.1;
      else         swingA = -pi * 0.9 + st * pi * 0.8;

      final armEnd = Offset(12 + cos(swingA) * 22, -4 + sin(swingA) * 22);
      canvas.drawLine(const Offset(10, -4), armEnd,
          Paint()..color = const Color(0xFF546E7A) ..strokeWidth = 7
            ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke);

      final swordEnd = Offset(armEnd.dx + cos(swingA) * 44, armEnd.dy + sin(swingA) * 44);
      canvas.drawLine(armEnd, swordEnd,
          Paint()..color = Colors.white.withValues(alpha: 0.4) ..strokeWidth = 9
            ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawLine(armEnd, swordEnd,
          Paint()..color = const Color(0xFFECEFF1) ..strokeWidth = 3
            ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke);
      canvas.drawLine(const Offset(10, -4), armEnd,
          Paint()..color = const Color(0xFF8D6E63) ..strokeWidth = 5
            ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke);

      final cgAngle = swingA + pi / 2;
      canvas.drawLine(
        Offset(armEnd.dx + cos(cgAngle) * 8, armEnd.dy + sin(cgAngle) * 8),
        Offset(armEnd.dx - cos(cgAngle) * 8, armEnd.dy - sin(cgAngle) * 8),
        Paint()..color = const Color(0xFFFFD700) ..strokeWidth = 3 ..style = PaintingStyle.stroke,
      );
      if (st > 0.3) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(12 + cos(swingA) * 11, -4 + sin(swingA) * 11),
            width: 60, height: 60,
          ),
          swingA - 0.4, 0.8 * (1 - st), false,
          Paint()..color = Colors.white.withValues(alpha: 0.35 * st) ..strokeWidth = 2
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      if (knight.combo >= 5) {
        canvas.drawCircle(swordEnd, 24,
            Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.3 * st)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
      }
    } else {
      canvas.drawLine(const Offset(10, -4), const Offset(24, 10),
          Paint()..color = const Color(0xFF546E7A) ..strokeWidth = 7
            ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke);
      canvas.drawLine(const Offset(22, 8), const Offset(30, -8),
          Paint()..color = const Color(0xFFECEFF1) ..strokeWidth = 3
            ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke);
    }

    // Helmet
    canvas.drawRect(Rect.fromLTWH(-5, -22, 10, 10), Paint()..color = const Color(0xFF78909C));
    final helmPath = Path()
      ..moveTo(-12, -22) ..lineTo(-14, -36)
      ..quadraticBezierTo(-10, -46, 0, -48)
      ..quadraticBezierTo(10, -46, 14, -36)
      ..lineTo(12, -22) ..close();
    canvas.drawPath(helmPath, Paint()..color = const Color(0xFF455A64));
    canvas.drawPath(helmPath, Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
    canvas.drawRect(Rect.fromLTWH(-8, -34, 16, 5), Paint()..color = const Color(0xFF263238));
    canvas.drawRect(Rect.fromLTWH(-6, -33, 12, 3),
        Paint()..color = const Color(0xFF64FFDA).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawRect(Rect.fromLTWH(-2, -52, 4, 14), Paint()..color = const Color(0xFFB71C1C));
    canvas.drawOval(Rect.fromLTWH(-4, -56, 8, 8),  Paint()..color = const Color(0xFFB71C1C));

    canvas.restore();
  }

  // ── Floating texts ──────────────────────────────────────────────────────────
  void _drawFloats(Canvas canvas) {
    for (final f in floats) {
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold,
            color: f.color.withValues(alpha: f.life.clamp(0.0, 1.0)),
            shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(f.x - tp.width / 2, f.y));
    }
  }

  @override
  bool shouldRepaint(_GamePainter o) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
//  SMALL HELPERS
// ═══════════════════════════════════════════════════════════════════════════
class _HudChip extends StatelessWidget {
  final String l, v;
  final Color c;
  const _HudChip(this.l, this.v, this.c);

  @override
  Widget build(BuildContext ctx) => Row(children: [
    Text(l, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
    const SizedBox(width: 4),
    Text(v, style: TextStyle(
      color: c, fontSize: 16, fontWeight: FontWeight.bold,
      shadows: [Shadow(blurRadius: 4, color: c.withValues(alpha: 0.5))],
    )),
  ]);
}

class _StatBox extends StatelessWidget {
  final String l, v;
  final Color c;
  const _StatBox(this.l, this.v, this.c);

  @override
  Widget build(BuildContext ctx) => Expanded(
    child: Column(children: [
      Text(v, style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(l, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
    ]),
  );
}

Widget _infoRow(String icon, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(children: [
    Text(icon, style: const TextStyle(fontSize: 14)),
    const SizedBox(width: 10),
    Expanded(child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12))),
  ]),
);