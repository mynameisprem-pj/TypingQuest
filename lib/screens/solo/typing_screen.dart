import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../data/typing_content.dart';
import '../../services/progress_service.dart';
import '../../widgets/virtual_keyboard.dart';

class TypingScreen extends StatefulWidget {
  final Difficulty difficulty;
  final int level;

  const TypingScreen({super.key, required this.difficulty, required this.level});

  @override
  State<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen> with TickerProviderStateMixin {
  late String _targetText;
  String _typedText = '';
  int _currentIndex = 0;
  bool _lastWasWrong = false;
  int _errorCount = 0;
  bool _started = false;
  bool _finished = false;

  // Countdown timer
  late Stopwatch _stopwatch;
  Timer? _timer;
  int _seconds = 0;       // elapsed (for WPM calc)
  int _timeLeft = 60;     // countdown
  int _timeLimit = 60;
  bool _timeFailed = false;

  // WPM calculation
  int _wpm = 0;
  double _accuracy = 100.0;

  // Animations
  late AnimationController _wrongShakeController;
  late AnimationController _finishController;
  late AnimationController _pulseController;
  late Animation<Offset> _shakeAnim;

  // Focus
  final FocusNode _focusNode = FocusNode();

  // Beginner keyboard visibility (fades out at higher levels)
  bool get _showKeyboard => widget.difficulty == Difficulty.beginner && widget.level <= 70;
  bool get _showHints => widget.difficulty == Difficulty.beginner && widget.level <= 50;

  @override
  void initState() {
    super.initState();
    _targetText = TypingContent.getText(widget.difficulty, widget.level);
    _timeLimit = TypingContent.timeLimitSeconds(widget.difficulty, widget.level);
    _timeLeft = _timeLimit;
    _stopwatch = Stopwatch();

    _wrongShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0.02, 0))
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_wrongShakeController);

    _finishController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
        ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wrongShakeController.dispose();
    _finishController.dispose();
    _pulseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_finished || _timeFailed) return;
      setState(() {
        _seconds = _stopwatch.elapsed.inSeconds;
        _timeLeft = (_timeLimit - _seconds).clamp(0, _timeLimit);
        _updateWpm();
        if (_timeLeft <= 0) _onTimeFail();
      });
    });
  }

  void _onTimeFail() {
    _stopwatch.stop();
    _timer?.cancel();
    _timeFailed = true;
    _finished = true; // block further typing
    _updateWpm();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _showTimeFailDialog();
    });
  }

  void _showTimeFailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TimeFailDialog(
        progress: _currentIndex,
        total: _targetText.length,
        wpm: _wpm,
        accuracy: _accuracy,
        onRetry: () {
          Navigator.pop(context);
          Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => TypingScreen(difficulty: widget.difficulty, level: widget.level)));
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        difficultyColor: _difficultyColor,
      ),
    );
  }

  void _updateWpm() {
    if (_seconds > 0) {
      final wordsTyped = _currentIndex / 5;
      _wpm = (wordsTyped / (_seconds / 60)).round();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_finished) return;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    // Get character
    String? char;
    if (event.character != null && event.character!.isNotEmpty) {
      char = event.character!;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      char = ' ';
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      // Allow backspace for wrong chars
      if (_currentIndex > 0 && _lastWasWrong) {
        setState(() {
          _currentIndex--;
          _typedText = _typedText.substring(0, _typedText.length - 1);
          _lastWasWrong = false;
        });
      }
      return;
    }

    if (char == null) return;

    if (!_started) {
      _started = true;
      _startTimer();
    }

    final expected = _targetText[_currentIndex];

    if (char == expected) {
      setState(() {
        _typedText += char!;
        _currentIndex++;
        _lastWasWrong = false;
        _accuracy = _currentIndex > 0
            ? ((_currentIndex - _errorCount) / _currentIndex * 100)
            : 100;
        if (_currentIndex == _targetText.length) {
          _onFinish();
        }
      });
    } else {
      // Wrong key
      setState(() {
        _lastWasWrong = true;
        _errorCount++;
        _accuracy = _currentIndex > 0
            ? ((_currentIndex - _errorCount) / _currentIndex * 100)
            : 100;
      });
      _wrongShakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  void _onFinish() {
    _stopwatch.stop();
    _timer?.cancel();
    _finished = true;
    _updateWpm();

    final accuracy = ((_targetText.length - _errorCount) / _targetText.length * 100).clamp(0, 100).toDouble();
    final stars = LevelResult.calculateStars(accuracy, _wpm, TypingContent.targetWpm(widget.difficulty, widget.level));

    final result = LevelResult(
      wpm: _wpm,
      accuracy: accuracy,
      stars: stars,
      timeTaken: _stopwatch.elapsed,
    );

    ProgressService().saveResult(widget.difficulty, widget.level, result);
    _finishController.forward();

    // Show result dialog after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _showResultDialog(result);
    });
  }

  void _showResultDialog(LevelResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        result: result,
        level: widget.level,
        difficulty: widget.difficulty,
        onRetry: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TypingScreen(difficulty: widget.difficulty, level: widget.level)),
          );
        },
        onNext: widget.level < 100
            ? () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => TypingScreen(difficulty: widget.difficulty, level: widget.level + 1)),
                );
              }
            : null,
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            _buildStatsBar(),
            Expanded(child: _buildTypingArea()),
            if (_showKeyboard) VirtualKeyboard(
              highlightChar: _finished ? null : (_currentIndex < _targetText.length ? _targetText[_currentIndex] : null),
              wasWrong: _lastWasWrong,
              showFingerColors: _showHints,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _difficultyColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _difficultyColor.withValues(alpha: 0.4)),
            ),
            child: Text(widget.difficulty.label, style: AppTheme.body(12, color: _difficultyColor)),
          ),
          const SizedBox(width: 12),
          Text('Level ${widget.level}', style: AppTheme.heading(16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('${_timeLimit}s', style: AppTheme.body(11, color: AppTheme.textSecondary)),
            ]),
          ),
        ],
      ),
      actions: [
        // Restart button
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TypingScreen(difficulty: widget.difficulty, level: widget.level)),
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: LinearProgressIndicator(
          value: _currentIndex / _targetText.length,
          backgroundColor: AppTheme.cardBorder,
          valueColor: AlwaysStoppedAnimation(_difficultyColor),
          minHeight: 3,
        ),
      ),
    );
  }

  Color get _difficultyColor {
    switch (widget.difficulty) {
      case Difficulty.beginner: return AppTheme.beginner;
      case Difficulty.intermediate: return AppTheme.intermediate;
      case Difficulty.master: return AppTheme.master;
    }
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          _StatChip(label: 'WPM', value: '$_wpm', color: AppTheme.primary),
          const SizedBox(width: 16),
          _StatChip(label: 'ACC', value: '${_accuracy.toStringAsFixed(1)}%', color: AppTheme.gold),
          const SizedBox(width: 16),
          // Countdown timer chip
          _CountdownChip(
            timeLeft: _timeLeft,
            timeLimit: _timeLimit,
            started: _started,
            pulseController: _pulseController,
          ),
          const Spacer(),
          Text(
            '$_currentIndex/${_targetText.length}',
            style: AppTheme.body(13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Widget _buildTypingArea() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SlideTransition(
          position: _shakeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hint banner
              if (!_started && widget.difficulty == Difficulty.beginner && widget.level <= 20)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_outlined, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text('Watch the keyboard below. Type the highlighted key!', style: AppTheme.body(13, color: AppTheme.primary)),
                    ],
                  ),
                ),

              // The main text display
              Container(
                constraints: const BoxConstraints(maxWidth: 900),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: _buildTextDisplay(),
              ),

              const SizedBox(height: 20),

              if (!_started)
                Column(children: [
                  Text(
                    'Start typing to begin...',
                    style: AppTheme.body(14, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '⏱  You have ${_formatTime(_timeLimit)} to complete this level',
                    style: AppTheme.body(12, color: AppTheme.primary.withValues(alpha: 0.7)),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextDisplay() {
    return RichText(
      text: TextSpan(
        children: List.generate(_targetText.length, (i) {
          final char = _targetText[i];
          Color color;
          Color? bg;

          if (i < _currentIndex) {
            // Already typed correctly
            color = AppTheme.textSecondary.withValues(alpha: 0.6);
            bg = null;
          } else if (i == _currentIndex) {
            // Current character
            color = _lastWasWrong ? AppTheme.error : AppTheme.textPrimary;
            bg = _lastWasWrong ? AppTheme.error.withValues(alpha: 0.2) : AppTheme.primary.withValues(alpha: 0.2);
          } else {
            // Upcoming
            color = AppTheme.textPrimary;
            bg = null;
          }

          return WidgetSpan(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: bg != null
                  ? BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3))
                  : null,
              child: Text(
                char,
                style: AppTheme.mono(22, color: color),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTheme.body(11, color: AppTheme.textMuted).copyWith(letterSpacing: 1)),
        const SizedBox(width: 6),
        Text(value, style: AppTheme.heading(16, color: color)),
      ],
    );
  }
}

// ── Result Dialog ─────────────────────────────────────────────────────────
class _ResultDialog extends StatelessWidget {
  final LevelResult result;
  final int level;
  final Difficulty difficulty;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final VoidCallback onHome;

  const _ResultDialog({
    required this.result,
    required this.level,
    required this.difficulty,
    required this.onRetry,
    this.onNext,
    required this.onHome,
  });

  Color get _color {
    switch (difficulty) {
      case Difficulty.beginner: return AppTheme.beginner;
      case Difficulty.intermediate: return AppTheme.intermediate;
      case Difficulty.master: return AppTheme.master;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _color.withValues(alpha: 0.5)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + i * 150),
                curve: Curves.elasticOut,
                builder: (_, v, _) => Transform.scale(
                  scale: v,
                  child: Icon(
                    i < result.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < result.stars ? AppTheme.gold : AppTheme.textMuted,
                    size: 48,
                  ),
                ),
              )),
            ),
            const SizedBox(height: 16),

            Text(
              result.stars == 3 ? '🎉 PERFECT!' : result.stars == 2 ? '👏 GREAT JOB!' : '👍 LEVEL COMPLETE!',
              style: AppTheme.heading(22, color: _color),
            ),
            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                Expanded(child: _ResultStat(label: 'WPM', value: '${result.wpm}', color: AppTheme.primary)),
                Container(width: 1, height: 40, color: AppTheme.cardBorder),
                Expanded(child: _ResultStat(label: 'ACCURACY', value: '${result.accuracy.toStringAsFixed(1)}%', color: AppTheme.gold)),
                Container(width: 1, height: 40, color: AppTheme.cardBorder),
                Expanded(child: _ResultStat(
                  label: 'TIME',
                  value: '${result.timeTaken.inMinutes}:${(result.timeTaken.inSeconds % 60).toString().padLeft(2, '0')}',
                  color: AppTheme.textSecondary,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('RETRY'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onRetry,
                  ),
                ),
                if (onNext != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('NEXT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onNext,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onHome,
              child: Text('Back to Levels', style: AppTheme.body(13, color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTheme.heading(24, color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.body(11, color: AppTheme.textSecondary).copyWith(letterSpacing: 1)),
      ],
    );
  }
}

// ── Countdown chip ─────────────────────────────────────────────────────────
class _CountdownChip extends StatelessWidget {
  final int timeLeft, timeLimit;
  final bool started;
  final AnimationController pulseController;

  const _CountdownChip({
    required this.timeLeft,
    required this.timeLimit,
    required this.started,
    required this.pulseController,
  });

  String _fmt(int s) {
  final m = s ~/ 60;
  final sec = s % 60;

  return m > 0
      ? '$m:${sec.toString().padLeft(2, '0')}'
      : '${sec}s';
}

  @override
  Widget build(BuildContext context) {
    final fraction = timeLimit > 0 ? timeLeft / timeLimit : 1.0;
    final isLow   = timeLeft <= 10 && started;
    final isCrit  = timeLeft <= 5  && started;

    final Color barColor = isLow ? AppTheme.error : fraction > 0.5
        ? AppTheme.success : AppTheme.gold;
    final Color textColor = isLow ? AppTheme.error : AppTheme.textSecondary;

    if (isCrit) {
      return AnimatedBuilder(
        animation: pulseController,
        builder: (_, _) => _buildChip(
          barColor, textColor,
          scale: 1.0 + pulseController.value * 0.06,
          glowOpacity: pulseController.value * 0.4,
        ),
      );
    }
    return _buildChip(barColor, textColor);
  }

  Widget _buildChip(Color barColor, Color textColor,
      {double scale = 1.0, double glowOpacity = 0}) {
    final fraction = timeLimit > 0 ? timeLeft / timeLimit : 1.0;
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: barColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: barColor.withValues(alpha: 0.4 + glowOpacity)),
          boxShadow: glowOpacity > 0
              ? [BoxShadow(color: barColor.withValues(alpha: glowOpacity), blurRadius: 10)]
              : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.timer_outlined, size: 11, color: textColor.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Text('TIME', style: AppTheme.body(10, color: textColor.withValues(alpha: 0.7))
                .copyWith(letterSpacing: 1)),
          ]),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_fmt(timeLeft), style: AppTheme.heading(16, color: textColor)),
            const SizedBox(width: 6),
            SizedBox(
              width: 48, height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0, 1),
                  backgroundColor: barColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(barColor),
                  minHeight: 4,
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Time fail dialog ────────────────────────────────────────────────────────
class _TimeFailDialog extends StatelessWidget {
  final int progress, total, wpm;
  final double accuracy;
  final VoidCallback onRetry, onHome;
  final Color difficultyColor;

  const _TimeFailDialog({
    required this.progress, required this.total, required this.wpm,
    required this.accuracy, required this.onRetry, required this.onHome,
    required this.difficultyColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress / total * 100).toStringAsFixed(0);
    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.error.withValues(alpha: 0.12),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.4), width: 2),
            ),
            child: const Center(child: Text('⏰', style: TextStyle(fontSize: 34))),
          ),
          const SizedBox(height: 16),

          Text("TIME'S UP!", style: AppTheme.heading(24, color: AppTheme.error)),
          const SizedBox(height: 6),
          Text('You ran out of time for this level.',
              style: AppTheme.body(13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),

          // Progress bar
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progress', style: AppTheme.body(12, color: AppTheme.textSecondary)),
              Text('$progress/$total chars ($pct%)',
                  style: AppTheme.body(12, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / total,
                minHeight: 8,
                backgroundColor: AppTheme.cardBorder,
                valueColor: AlwaysStoppedAnimation(difficultyColor.withValues(alpha: 0.6)),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Stats
          Row(children: [
            Expanded(child: _ResultStat(label: 'WPM', value: '$wpm', color: AppTheme.primary)),
            Container(width: 1, height: 36, color: AppTheme.cardBorder),
            Expanded(child: _ResultStat(label: 'ACC', value: '${accuracy.toStringAsFixed(1)}%', color: AppTheme.gold)),
          ]),
          const SizedBox(height: 24),

          // Tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(
                wpm < 10
                    ? "Try to type faster — don't look at your hands!"
                    : accuracy < 80
                        ? 'Focus on accuracy first, then speed will follow.'
                        : 'Good speed! Keep practicing to beat the timer.',
                style: AppTheme.body(12, color: AppTheme.primary.withValues(alpha: 0.8)),
              )),
            ]),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text('LEVELS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onHome,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('RETRY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onRetry,
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}