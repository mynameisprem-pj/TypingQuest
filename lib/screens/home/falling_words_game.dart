import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/theme/app_theme.dart';
import '/services/sound_service.dart';
import '/services/profile_service.dart';

// ── Word bank for the game ─────────────────────────────────────────────────
const List<String> _kEasyWords = [
  'cat','dog','sun','run','hat','top','car','big','fly','hot','cup','pen',
  'box','red','blue','fish','hand','milk','door','tree','bird','frog','cake',
  'book','ball','fire','rain','star','wind','leaf','rock','snow','path','love',
];
const List<String> _kMedWords = [
  'apple','table','chair','house','water','light','plant','river','stone','cloud',
  'music','dance','sleep','dream','smile','happy','smart','great','world','earth',
  'class','school','study','learn','teach','write','climb','think','focus','start',
  'Nepal','mount','tiger','eagle','lotus','brave','proud','peace','faith','grace',
];
const List<String> _kHardWords = [
  'elephant','keyboard','mountain','beautiful','computer','adventure','champion',
  'umbrella','discover','knowledge','together','celebrate','treasure','butterfly',
  'practice','question','remember','solution','challenge','fantastic','wonderful',
];

// ── Falling word data ──────────────────────────────────────────────────────
class FallingWord {
  final String text;
  double x;        // 0.0–1.0 (normalized width)
  double y;        // pixels from top
  double speed;    // pixels per second
  final Color color;
  bool matched;    // currently being typed
  bool dying;      // playing destroy animation
  double opacity;

  FallingWord({
    required this.text,
    required this.x,
    required this.y,
    required this.speed,
    required this.color,
    this.matched = false,
    this.dying = false,
    this.opacity = 1.0,
  });
}

// ── Difficulty levels ──────────────────────────────────────────────────────
enum WordRainDifficulty { easy, medium, hard }

const _kDiffConfig = {
  WordRainDifficulty.easy:   {'spawnMs': 3000, 'speedMin': 40.0,  'speedMax': 70.0,  'maxWords': 5},
  WordRainDifficulty.medium: {'spawnMs': 2000, 'speedMin': 65.0,  'speedMax': 110.0, 'maxWords': 7},
  WordRainDifficulty.hard:   {'spawnMs': 1200, 'speedMin': 100.0, 'speedMax': 160.0, 'maxWords': 10},
};

// ── On-screen keyboard layout (mobile only) ───────────────────────────────
const List<List<String>> _kKeyRows = [
  ['q','w','e','r','t','y','u','i','o','p'],
  ['a','s','d','f','g','h','j','k','l'],
  ['⌫','z','x','c','v','b','n','m','SPACE'],
];

// ══════════════════════════════════════════════════════════════════════════
class FallingWordsGame extends StatefulWidget {
  const FallingWordsGame({super.key});

  @override
  State<FallingWordsGame> createState() => _FallingWordsGameState();
}

class _FallingWordsGameState extends State<FallingWordsGame> with TickerProviderStateMixin {
  // Game state
  final List<FallingWord> _words = [];
  bool _paused = false;
  bool _gameOver = false;
  bool _started = false;

  int _score = 0;
  int _highScore = 0;
  int _lives = 3;
  int _wordsDestroyed = 0;
  WordRainDifficulty _difficulty = WordRainDifficulty.easy;

  // WPM tracking
  final Stopwatch _stopwatch = Stopwatch();
  int _wpm = 0;

  // Input — raw keyboard listener, no TextField needed
  final FocusNode _focusNode = FocusNode();
  String _currentInput = '';
  FallingWord? _lockedTarget; // word currently being typed

  // Game loop
  Timer? _gameLoop;
  Timer? _spawnTimer;
  DateTime? _lastFrame;

  // Spawn
  final Random _rng = Random();
  final List<String> _wordPool = [];

  // Shake animation for lives lost
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Score pop
  final List<_ScorePop> _scorePops = [];

  // ── Mobile detection ──────────────────────────────────────────────────
  /// True on iOS/Android — show on-screen keyboard instead of physical one.
  bool get _isMobile =>
      Theme.of(context).platform == TargetPlatform.iOS ||
      Theme.of(context).platform == TargetPlatform.android;

  /// Extra height added to the bottom bar when OSK is shown.
  static const double _oskExtraHeight = 44.0 * 3 + 6.0 * 3 + 12.0 * 2; // ≈ 180

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _buildWordPool();

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _shakeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── High score ─────────────────────────────────────────────────────────
  String get _highScoreKey =>
      '${ProfileService().keyPrefix}word_rain_highscore_${_difficulty.name}';

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _highScore = prefs.getInt(_highScoreKey) ?? 0);
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, _score);
      setState(() => _highScore = _score);
    }
  }

  // ── Word pool ───────────────────────────────────────────────────────────
  void _buildWordPool() {
    _wordPool.clear();
    switch (_difficulty) {
      case WordRainDifficulty.easy:
        _wordPool.addAll(_kEasyWords);
        break;
      case WordRainDifficulty.medium:
        _wordPool.addAll(_kEasyWords);
        _wordPool.addAll(_kMedWords);
        break;
      case WordRainDifficulty.hard:
        _wordPool.addAll(_kMedWords);
        _wordPool.addAll(_kHardWords);
        break;
    }
    _wordPool.shuffle(_rng);
  }

  // ── Colors for falling words ────────────────────────────────────────────
  static const List<Color> _wordColors = [
    Color(0xFF5C7CFA), // indigo
    Color(0xFF20C997), // mint
    Color(0xFFFF6B6B), // coral
    Color(0xFFFFBE3D), // amber
    Color(0xFFB197FC), // lavender
    Color(0xFF4DABF7), // sky
    Color(0xFF63E6BE), // teal
    Color(0xFFFF8CC8), // pink
  ];

  Color _randomWordColor() => _wordColors[_rng.nextInt(_wordColors.length)];

  // ── Game control ────────────────────────────────────────────────────────
  void _startGame() {
    setState(() {
      _words.clear();
      _score = 0;
      _lives = 3;
      _wordsDestroyed = 0;
      _wpm = 0;
      _gameOver = false;
      _started = true;
      _paused = false;
      _scorePops.clear();
      _currentInput = '';
      _lockedTarget = null;
    });
    _stopwatch.reset();
    _stopwatch.start();
    _lastFrame = DateTime.now();
    _startGameLoop();
    _startSpawnTimer();
    _focusNode.requestFocus();
  }

  void _startGameLoop() {
    _gameLoop?.cancel();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _startSpawnTimer() {
    _spawnTimer?.cancel();
    final ms = _kDiffConfig[_difficulty]!['spawnMs'] as int;
    _spawnTimer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!_paused && !_gameOver) _spawnWord();
    });
    // Spawn first word immediately
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_gameOver) _spawnWord();
    });
  }

  void _spawnWord() {
    if (_paused || _gameOver) return;
    final maxWords = _kDiffConfig[_difficulty]!['maxWords'] as int;
    if (_words.length >= maxWords) return;

    // Pick a word not already on screen
    final existing = _words.map((w) => w.text).toSet();
    final available = _wordPool.where((w) => !existing.contains(w)).toList();
    if (available.isEmpty) return;

    final word = available[_rng.nextInt(available.length)];
    final speedMin = (_kDiffConfig[_difficulty]!['speedMin'] as double);
    final speedMax = (_kDiffConfig[_difficulty]!['speedMax'] as double);
    final speed = speedMin + _rng.nextDouble() * (speedMax - speedMin);

    // Random x but keep word within bounds (estimate ~12px per char)

    setState(() {
      _words.add(FallingWord(
        text: word,
        x: 0.05 + _rng.nextDouble() * 0.85,
        y: -40,
        speed: speed,
        color: _randomWordColor(),
      ));
    });
  }

  void _tick() {
    if (_paused || _gameOver || !mounted) return;

    final now = DateTime.now();
    final dt = _lastFrame != null ? now.difference(_lastFrame!).inMilliseconds / 1000.0 : 0.016;
    _lastFrame = now;

    if (!mounted) return;
    final screenH = MediaQuery.of(context).size.height;
    final groundY = screenH - 130 - (_isMobile ? _oskExtraHeight : 0); // bottom typing bar area

    setState(() {
      // Update WPM
      final secs = _stopwatch.elapsed.inSeconds;
      if (secs > 0) _wpm = (_wordsDestroyed / (secs / 60)).round();

      // Move words down
      final toRemove = <FallingWord>[];
      for (final w in _words) {
        if (w.dying) {
          w.opacity -= dt * 4;
          if (w.opacity <= 0) toRemove.add(w);
          continue;
        }
        w.y += w.speed * dt;

        // Hit the ground
        if (w.y >= groundY) {
          toRemove.add(w);
          _lives--;
          SoundService().playError();
          _shakeCtrl.forward(from: 0);
          if (_lives <= 0) {
            _endGame();
            return;
          }
        }
      }
      _words.removeWhere((w) => toRemove.contains(w));

      // Update score pops
      _scorePops.removeWhere((p) => p.opacity <= 0);
      for (final p in _scorePops) {
        p.y -= 40 * dt;
        p.opacity -= dt * 1.5;
      }
    });
  }

  void _endGame() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _stopwatch.stop();
    setState(() => _gameOver = true);
    _saveHighScore();
    SoundService().playLevelComplete();
  }

  void _pauseResume() {
    setState(() => _paused = !_paused);
    if (!_paused) {
      _lastFrame = DateTime.now();
    }
    _focusNode.requestFocus();
  }

  // void _clearScreen() {
  //   SoundService().playStreak();
  //   setState(() {
  //     _words.clear();
  //     _currentInput = '';
  //     _lockedTarget = null;
  //   });
  //   _focusNode.requestFocus();
  // }

  // ── Input handling — raw keyboard, no TextField ────────────────────────
  void _handleKeyEvent(KeyEvent event) {
    if (_paused || _gameOver || !_started) return;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;

    // Backspace — delete last character
    if (key == LogicalKeyboardKey.backspace) {
      if (_currentInput.isEmpty) return;
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        // Re-evaluate target with shorter input
        _updateTarget();
      });
      return;
    }

    // Space — clear current input (abandon current word attempt)
    if (key == LogicalKeyboardKey.space) {
      setState(() {
        _currentInput = '';
        _lockedTarget = null;
        for (final w in _words) {
          w.matched = false;
        }
      });
      return;
    }

    // Only accept printable single characters
    final char = event.character;
    if (char == null || char.isEmpty || char.length > 1) return;
    // Ignore non-letter/number keys
    final code = char.codeUnitAt(0);
    if (code < 32 || code > 126) return;

    setState(() {
      _currentInput += char.toLowerCase();

      // If we have a locked target, check if we're still matching it
      if (_lockedTarget != null && !_lockedTarget!.dying) {
        final target = _lockedTarget!;
        if (target.text.toLowerCase().startsWith(_currentInput)) {
          // Still matching — check completion
          if (target.text.toLowerCase() == _currentInput) {
            _destroyWord(target);
            _clearInput();
          }
          // else keep typing
        } else {
          // Wrong key for locked word — clear and try fresh
          _currentInput = char.toLowerCase();
          _lockedTarget = null;
          _updateTarget();
        }
      } else {
        // No locked target yet — find best match
        _lockedTarget = null;
        _updateTarget();

        // Check immediate completion (single-letter word)
        if (_lockedTarget != null && _lockedTarget!.text.toLowerCase() == _currentInput) {
          _destroyWord(_lockedTarget!);
          _clearInput();
        }
      }
    });
  }

  // ── On-screen keyboard input (mobile only) ────────────────────────────
  void _handleOskKey(String key) {
    if (_paused || _gameOver || !_started) return;

    if (key == '⌫') {
      if (_currentInput.isEmpty) return;
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        _updateTarget();
      });
      return;
    }

    if (key == 'SPACE') {
      setState(() {
        _currentInput = '';
        _lockedTarget = null;
        for (final w in _words) { w.matched = false; }
      });
      return;
    }

    // Normal letter — reuse the same logic as the physical keyboard handler
    final char = key.toLowerCase();
    setState(() {
      _currentInput += char;

      if (_lockedTarget != null && !_lockedTarget!.dying) {
        final target = _lockedTarget!;
        if (target.text.toLowerCase().startsWith(_currentInput)) {
          if (target.text.toLowerCase() == _currentInput) {
            _destroyWord(target);
            _clearInput();
          }
        } else {
          _currentInput = char;
          _lockedTarget = null;
          _updateTarget();
        }
      } else {
        _lockedTarget = null;
        _updateTarget();
        if (_lockedTarget != null && _lockedTarget!.text.toLowerCase() == _currentInput) {
          _destroyWord(_lockedTarget!);
          _clearInput();
        }
      }
    });
  }

  /// Finds the best word to target from current input.
  /// Priority: exact match first, then longest prefix match,
  /// then among ties — the word closest to the ground (highest y).
  void _updateTarget() {
    // Clear all highlights first
    for (final w in _words) {
      w.matched = false;
    }
    if (_currentInput.isEmpty) { _lockedTarget = null; return; }

    final candidates = _words.where((w) =>
      !w.dying && w.text.toLowerCase().startsWith(_currentInput)
    ).toList();

    if (candidates.isEmpty) { _lockedTarget = null; return; }

    // Sort by: most characters already matched (longest match first),
    // then by y position descending (closest to ground = most dangerous)
    candidates.sort((a, b) {
      // Prefer exact match
      final aExact = a.text.toLowerCase() == _currentInput ? 1 : 0;
      final bExact = b.text.toLowerCase() == _currentInput ? 1 : 0;
      if (aExact != bExact) return bExact - aExact;
      // Prefer more dangerous (higher y = closer to ground)
      return b.y.compareTo(a.y);
    });

    _lockedTarget = candidates.first;
    _lockedTarget!.matched = true;
  }

  void _clearInput() {
    _currentInput = '';
    _lockedTarget = null;
    for (final w in _words) {
      w.matched = false;
    }
  }

  void _destroyWord(FallingWord word) {
    word.dying = true;
    word.matched = false;
    _wordsDestroyed++;

    final pts = _calcPoints(word);
    _score += pts;

    // Score pop animation
    _scorePops.add(_ScorePop(text: '+$pts', x: word.x, y: word.y, opacity: 1.0));

    SoundService().playKeyClick();
    if (_wordsDestroyed % 5 == 0) SoundService().playStreak();
  }

  int _calcPoints(FallingWord w) {
    int base = w.text.length * 10;
    // Bonus for speed (word close to bottom = higher risk = more points)
    final screenH = MediaQuery.of(context).size.height;
    final groundY = screenH - 130.0 - (_isMobile ? _oskExtraHeight : 0);
    final danger = (w.y / groundY).clamp(0.0, 1.0);
    return base + (base * danger * 0.5).round();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_started) return _buildStartScreen();
    if (_gameOver) return _buildGameOver();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: child,
        ),
        child: _buildGame(),
      ),
    );
  }

  Widget _buildGame() {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Background ──────────────────────────────────────────────────
        _GameBackground(paused: _paused),

        // ── Falling words ──────────────────────────────────────────────
        ..._words.where((w) => !w.dying || w.opacity > 0).map((w) => _buildFallingWord(w, size)),

        // ── Score pops ──────────────────────────────────────────────────
        ..._scorePops.map((p) => Positioned(
          left: p.x * size.width,
          top: p.y,
          child: Opacity(
            opacity: p.opacity.clamp(0.0, 1.0),
            child: Text('+${p.text.replaceAll('+', '')}', style: AppTheme.heading(15, color: AppTheme.success)),
          ),
        )),

        // ── Ground line ─────────────────────────────────────────────────
        Positioned(
          bottom: 128 + (_isMobile ? _oskExtraHeight : 0),
          left: 0, right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppTheme.error.withValues(alpha: 0.4), Colors.transparent],
              ),
            ),
          ),
        ),

        // ── Pause overlay ───────────────────────────────────────────────
        if (_paused)
          Container(
            color: Colors.white.withValues(alpha: 0.85),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('⏸', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text('Game Paused', style: AppTheme.heading(24, color: AppTheme.textPrimary)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12)),
                  onPressed: _pauseResume,
                ),
              ]),
            ),
          ),

        // ── Bottom bar ──────────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildBottomBar(),
        ),

        // ── Top stats ───────────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: _buildTopStats(),
        ),
      ],
    );
  }

  Widget _buildFallingWord(FallingWord w, Size size) {
    final isMatched = w.matched && _currentInput.isNotEmpty;
    return Positioned(
      left: (w.x * size.width).clamp(4, size.width - (w.text.length * 14.0 + 28)),
      top: w.y,
      child: Opacity(
        opacity: w.opacity.clamp(0.0, 1.0),
        child: AnimatedScale(
          scale: w.dying ? 1.3 : (isMatched ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isMatched ? w.color.withValues(alpha: 0.15) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isMatched ? w.color : w.color.withValues(alpha: 0.3),
                width: isMatched ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: w.color.withValues(alpha: isMatched ? 0.3 : 0.1),
                  blurRadius: isMatched ? 12 : 6,
                ),
              ],
            ),
            child: isMatched
                ? _buildPartialMatch(w.text)
                : Text(w.text, style: AppTheme.mono(15, color: AppTheme.textPrimary)),
          ),
        ),
      ),
    );
  }

  Widget _buildPartialMatch(String word) {
    final typed = _currentInput.toLowerCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: word.split('').asMap().entries.map((e) {
        final typedSoFar = e.key < typed.length;
        return Text(
          e.value,
          style: AppTheme.mono(15, color: typedSoFar ? AppTheme.primary : AppTheme.textPrimary).copyWith(
            fontWeight: typedSoFar ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopStats() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          _StatPill(icon: '⚡', label: 'WPM', value: '$_wpm', color: AppTheme.primary),
          const SizedBox(width: 12),
          _StatPill(icon: '🏆', label: 'Score', value: '$_score', color: AppTheme.gold),
          const SizedBox(width: 12),
          _StatPill(icon: '📈', label: 'Best', value: '$_highScore', color: AppTheme.success),
          const Spacer(),
          // Lives
          Row(children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
          ))),
          const SizedBox(width: 16),
          // Controls
          _ControlBtn(icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: AppTheme.primary, onTap: _pauseResume),
          const SizedBox(width: 6),
          // _ControlBtn(icon: Icons.clear_all_rounded, color: AppTheme.textSecondary, onTap: _clearScreen),
          const SizedBox(width: 6),
          _ControlBtn(icon: Icons.clear_all_rounded, color: AppTheme.textSecondary, onTap: _startGame),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Original input row (unchanged) ────────────────────────────
          Row(
        children: [
          // Visual input display — looks like a text field but IS NOT one
          Expanded(
            child: GestureDetector(
              // Tapping this just ensures the KeyboardListener parent keeps focus
              onTap: () => _focusNode.requestFocus(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _currentInput.isNotEmpty ? AppTheme.primary : AppTheme.cardBorder,
                    width: _currentInput.isNotEmpty ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  const Icon(Icons.keyboard_outlined, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _currentInput.isEmpty
                        ? Text(
                            _isMobile
                                ? 'Tap keys below to type...'
                                : 'Just start typing — no clicking needed...',
                            style: AppTheme.body(14, color: AppTheme.textMuted),
                          )
                        : Row(children: [
                            Text(
                              _currentInput,
                              style: AppTheme.mono(17, color: AppTheme.primary).copyWith(fontWeight: FontWeight.bold),
                            ),
                            // Blinking cursor
                            _BlinkingCursor(),
                          ]),
                  ),
                  if (_currentInput.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() {
                        _currentInput = '';
                        _lockedTarget = null;
                        for (final w in _words) {
                          w.matched = false;
                        }
                        _focusNode.requestFocus();
                      }),
                      child: const Icon(Icons.backspace_outlined, color: AppTheme.textMuted, size: 16),
                    ),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Difficulty selector
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(children: [
              _DiffBtn('E', WordRainDifficulty.easy,   AppTheme.success, _difficulty, _setDifficulty),
              _DiffBtn('M', WordRainDifficulty.medium, AppTheme.gold,    _difficulty, _setDifficulty),
              _DiffBtn('H', WordRainDifficulty.hard,   AppTheme.error,   _difficulty, _setDifficulty),
            ]),
          ),
        ],
      ),
          // ── On-screen keyboard (mobile only) ─────────────────────────
          if (_isMobile) _buildOsk(),
        ],
      ),
    );
  }

  // ── On-screen keyboard widget ──────────────────────────────────────────
  Widget _buildOsk() {
    final screenW = MediaQuery.of(context).size.width;
    final availW  = screenW - 16.0;
    // Widest row = 10 keys + 9 gaps of 5px
    final keyW    = (availW - 9 * 5) / 10;
    const keyH    = 44.0;

    return Container(
      color: const Color(0xFFF0F2F7),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _kKeyRows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                final isBackspace = key == '⌫';
                final isSpace     = key == 'SPACE';
                final w = isSpace
                    ? keyW * 4 + 3 * 5
                    : isBackspace
                        ? keyW * 1.5
                        : keyW;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: _OskKey(
                    label: key,
                    width: w,
                    height: keyH,
                    onTap: () => _handleOskKey(key),
                    isSpecial: isBackspace || isSpace,
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _setDifficulty(WordRainDifficulty d) {
    setState(() => _difficulty = d);
    _buildWordPool();
    _loadHighScore();
    if (_started && !_gameOver) {
      _spawnTimer?.cancel();
      _startSpawnTimer();
    }
  }

  Widget _buildStartScreen() {
    return Container(
      color: AppTheme.background,
      child: Stack(
        children: [
          const _GameBackground(paused: false),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌧️', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text('Word Rain', style: AppTheme.heading(30, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    'Words fall from above. Type them before they hit the ground. How long can you last?',
                    style: AppTheme.body(14, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Difficulty picker
                  Text('DIFFICULTY', style: AppTheme.body(11, color: AppTheme.textMuted).copyWith(letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _DiffCard('😊\nEasy', WordRainDifficulty.easy, AppTheme.success, _difficulty, _setDifficulty, 'Simple words\nSlow speed'),
                    const SizedBox(width: 8),
                    _DiffCard('😤\nMedium', WordRainDifficulty.medium, AppTheme.gold, _difficulty, _setDifficulty, 'Mixed words\nMedium speed'),
                    const SizedBox(width: 8),
                    _DiffCard('😈\nHard', WordRainDifficulty.hard, AppTheme.error, _difficulty, _setDifficulty, 'Long words\nFast speed'),
                  ]),
                  const SizedBox(height: 12),
                  if (_highScore > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('🏆', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text('Best score: $_highScore', style: AppTheme.body(14, color: AppTheme.textSecondary)),
                      ]),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text('START GAME', style: AppTheme.heading(15, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _startGame,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    final isNewHigh = _score >= _highScore && _score > 0;
    return Container(
      color: AppTheme.background,
      child: Stack(
        children: [
          const _GameBackground(paused: true),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isNewHigh ? '🎉' : '😤', style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 8),
                  Text(
                    isNewHigh ? 'New High Score!' : 'Game Over',
                    style: AppTheme.heading(26, color: isNewHigh ? AppTheme.success : AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  Row(children: [
                    _ResultBox('SCORE', '$_score', AppTheme.primary),
                    const SizedBox(width: 12),
                    _ResultBox('WPM', '$_wpm', AppTheme.success),
                    const SizedBox(width: 12),
                    _ResultBox('WORDS', '$_wordsDestroyed', AppTheme.gold),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _ResultBox('BEST', '$_highScore', const Color(0xFFB197FC)),
                    const SizedBox(width: 12),
                    _ResultBox('DIFFICULTY', _difficulty.name.toUpperCase(), AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    _ResultBox('LIVES LEFT', '$_lives', AppTheme.error),
                  ]),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Change Mode'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => setState(() { _started = false; _gameOver = false; }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Play Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                        ),
                        onPressed: _startGame,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score pop data ─────────────────────────────────────────────────────────
class _ScorePop {
  final String text;
  final double x;
  double y;
  double opacity;
  _ScorePop({required this.text, required this.x, required this.y, required this.opacity});
}

// ── On-screen keyboard key widget ──────────────────────────────────────────
class _OskKey extends StatefulWidget {
  final String label;
  final double width, height;
  final VoidCallback onTap;
  final bool isSpecial;
  const _OskKey({
    required this.label,
    required this.width,
    required this.height,
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  State<_OskKey> createState() => _OskKeyState();
}

class _OskKeyState extends State<_OskKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _pressed
              ? AppTheme.primary.withValues(alpha: 0.18)
              : widget.isSpecial
                  ? const Color(0xFFDDE1EC)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _pressed
                ? AppTheme.primary.withValues(alpha: 0.5)
                : const Color(0xFFCDD1DC),
            width: _pressed ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.04 : 0.10),
              blurRadius: _pressed ? 1 : 3,
              offset: Offset(0, _pressed ? 0 : 2),
            ),
          ],
        ),
        child: Center(
          child: widget.label == 'SPACE'
              ? const Icon(Icons.space_bar, size: 18, color: AppTheme.textSecondary)
              : widget.label == '⌫'
                  ? const Icon(Icons.backspace_outlined, size: 16, color: AppTheme.textSecondary)
                  : Text(
                      widget.label,
                      style: AppTheme.mono(14, color: widget.isSpecial
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary).copyWith(fontWeight: FontWeight.w600),
                    ),
        ),
      ),
    );
  }
}

// ── Animated background (gentle floating shapes) ───────────────────────────
class _GameBackground extends StatefulWidget {
  final bool paused;
  const _GameBackground({required this.paused});

  @override
  State<_GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<_GameBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        painter: _BgPainter(_ctrl.value),
        child: Container(),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Soft gradient background
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFFF4F6FA), const Color(0xFFEEF2FF)],
      ).createShader(rect));

    // Gently floating circles
    final circles = [
      [0.15, 0.2, 120.0, const Color(0xFF5C7CFA)],
      [0.85, 0.15, 90.0, const Color(0xFF20C997)],
      [0.7, 0.7, 150.0, const Color(0xFFB197FC)],
      [0.1, 0.8, 80.0, const Color(0xFFFFBE3D)],
      [0.5, 0.4, 60.0, const Color(0xFFFF6B6B)],
    ];

    for (int i = 0; i < circles.length; i++) {
      final c = circles[i];
      final dx = sin((t + i * 0.4) * 2 * pi) * 20;
      final dy = cos((t + i * 0.3) * 2 * pi) * 15;
      final cx = (c[0] as double) * size.width + dx;
      final cy = (c[1] as double) * size.height + dy;
      final r = c[2] as double;
      final color = c[3] as Color;
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color.withValues(alpha: 0.06));
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

// ── Helper widgets ─────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String icon, label, value; final Color color;
  const _StatPill({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 5),
      Text('$label ', style: AppTheme.body(11, color: AppTheme.textSecondary)),
      Text(value, style: AppTheme.body(12, color: color, weight: FontWeight.bold)),
    ]),
  );
}

class _ControlBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

class _DiffBtn extends StatelessWidget {
  final String label;
  final WordRainDifficulty mode, current;
  final Color color;
  final void Function(WordRainDifficulty) onTap;
  const _DiffBtn(this.label, this.mode, this.color, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = mode == current;
    return GestureDetector(
      onTap: () => onTap(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: AppTheme.body(13, color: active ? color : AppTheme.textMuted, weight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _DiffCard extends StatelessWidget {
  final String label;
  final WordRainDifficulty mode, current;
  final Color color;
  final void Function(WordRainDifficulty) onTap;
  final String desc;
  const _DiffCard(this.label, this.mode, this.color, this.current, this.onTap, this.desc);

  @override
  Widget build(BuildContext context) {
    final active = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.1) : AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : AppTheme.cardBorder, width: active ? 2 : 1),
          ),
          child: Column(children: [
            Text(label, style: AppTheme.body(13, color: active ? color : AppTheme.textSecondary, weight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(desc, style: AppTheme.body(10, color: AppTheme.textMuted), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String label, value; final Color color;
  const _ResultBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value, style: AppTheme.heading(18, color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.body(9, color: AppTheme.textSecondary).copyWith(letterSpacing: 0.8)),
      ]),
    ),
  );
}

// ── Blinking cursor widget ─────────────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 530))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, _) => Opacity(
      opacity: _ctrl.value > 0.5 ? 1.0 : 0.0,
      child: Container(
        width: 2, height: 18,
        margin: const EdgeInsets.only(left: 1),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    ),
  );
}