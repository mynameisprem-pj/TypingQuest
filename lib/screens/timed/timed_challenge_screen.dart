import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../../services/stats_service.dart';
import '../../services/achievements_service.dart';
import '../../widgets/wpm_graph.dart';
import '../../widgets/achievement_toast.dart';

// Word bank for timed mode — mix of common English words
const List<String> _kWords = [
  'the',
  'and',
  'to',
  'a',
  'of',
  'in',
  'is',
  'it',
  'you',
  'that',
  'he',
  'was',
  'for',
  'on',
  'are',
  'with',
  'as',
  'his',
  'they',
  'at',
  'be',
  'this',
  'from',
  'or',
  'one',
  'had',
  'by',
  'word',
  'but',
  'not',
  'what',
  'all',
  'were',
  'we',
  'when',
  'your',
  'can',
  'said',
  'there',
  'use',
  'an',
  'each',
  'which',
  'she',
  'do',
  'how',
  'their',
  'if',
  'will',
  'up',
  'other',
  'about',
  'out',
  'many',
  'then',
  'them',
  'these',
  'so',
  'some',
  'her',
  'would',
  'make',
  'like',
  'him',
  'has',
  'look',
  'two',
  'more',
  'write',
  'go',
  'see',
  'number',
  'no',
  'way',
  'could',
  'people',
  'my',
  'than',
  'first',
  'water',
  'been',
  'call',
  'who',
  'oil',
  'its',
  'now',
  'find',
  'long',
  'down',
  'day',
  'did',
  'get',
  'come',
  'made',
  'may',
  'part',
  'over',
  'new',
  'sound',
  'take',
  'only',
  'little',
  'work',
  'know',
  'place',
  'year',
  'live',
  'give',
  'most',
  'very',
  'after',
  'thing',
  'our',
  'just',
  'name',
  'good',
  'sentence',
  'man',
  'think',
  'say',
  'great',
  'where',
  'help',
  'through',
  'much',
  'before',
  'line',
  'right',
  'too',
  'mean',
  'old',
  'any',
  'same',
  'tell',
  'boy',
  'following',
  'came',
  'want',
  'show',
  'also',
  'around',
  'form',
  'small',
  'set',
  'put',
  'end',
  'does',
  'another',
  'well',
  'large',
  'need',
  'big',
  'high',
  'such',
  'turn',
  'here',
  'why',
  'went',
  'men',
  'read',
  'land',
  'different',
  'home',
  'move',
  'try',
  'kind',
  'hand',
  'picture',
  'again',
  'change',
  'off',
  'play',
  'spell',
  'air',
  'away',
  'animal',
  'house',
  'point',
  'page',
  'letter',
  'mother',
  'answer',
  'found',
  'study',
  'still',
  'learn',
  'should',
  'world',
  'school',
  'keep',
  'plant',
  'cover',
  'food',
  'sun',
  'computer',
  'type',
  'fast',
  'practice',
  'keyboard',
  'finger',
  'speed',
  'word',
  'level',
  'Nepal',
  'mountain',
  'student',
  'teacher',
  'class',
  'book',
  'write',
  'read',
  'learn',
];

String _generateText(int targetWords) {
  final rng = Random();
  final words = <String>[];
  while (words.length < targetWords) {
    words.add(_kWords[rng.nextInt(_kWords.length)]);
  }
  return words.join(' ');
}

class TimedChallengeScreen extends StatefulWidget {
  final int initialDuration;
  const TimedChallengeScreen({super.key, this.initialDuration = 60});

  @override
  State<TimedChallengeScreen> createState() => _TimedChallengeScreenState();
}

class _TimedChallengeScreenState extends State<TimedChallengeScreen>
    with TickerProviderStateMixin {
  static const List<int> _durations = [60, 120, 300];
  static const List<String> _labels = ['1 MIN', '2 MIN', '5 MIN'];

  late int _selectedDuration;
  bool _isCustom = false;
  late String _text;
  int _currentIndex = 0;
  bool _lastWasWrong = false;
  int _errorCount = 0;
  bool _started = false;
  bool _finished = false;

  int _timeLeft = 60;
  Timer? _timer;
  late Stopwatch _stopwatch;
  int _wpm = 0;

  // WPM graph
  final List<int> _wpmSamples = [];

  // Streak for ding sound
  int _correctStreak = 0;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _cursorKey = GlobalKey();
  late AnimationController _finishCtrl;
  late Animation<double> _finishAnim;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDuration;
    _text = _generateText(300);
    _timeLeft = _selectedDuration;
    _stopwatch = Stopwatch();
    _finishCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _finishAnim = CurvedAnimation(
      parent: _finishCtrl,
      curve: Curves.elasticOut,
    );

    AchievementsService().onUnlock = (ach) {
      if (mounted) {
        SoundService().playAchievement();
        showAchievementToast(context, ach);
      }
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    _finishCtrl.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  void _reset(int duration, {bool isCustom = false}) {
    _timer?.cancel();
    _finishCtrl.reset();
    setState(() {
      _selectedDuration = duration;
      _isCustom = isCustom;
      _text = _generateText(300);
      _currentIndex = 0;
      _lastWasWrong = false;
      _errorCount = 0;
      _started = false;
      _finished = false;
      _timeLeft = duration;
      _wpm = 0;
      _wpmSamples.clear();
      _correctStreak = 0;
    });
    _stopwatch.reset();
  }

  Future<void> _pickCustomTime() async {
    int minutes = _isCustom ? _selectedDuration ~/ 60 : 3;
    int seconds = _isCustom ? _selectedDuration % 60 : 0;

    await showDialog(
      context: context,
      builder: (ctx) => _CustomTimeDialog(
        initialMinutes: minutes,
        initialSeconds: seconds,
        onConfirm: (m, s) {
          final total = m * 60 + s;
          if (total >= 10) _reset(total, isCustom: true);
        },
      ),
    );
  }

  void _scrollToCursor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cursorKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          alignment: 0.3, // keep cursor in upper-third of scroll area
        );
      }
    });
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _timeLeft--;
        final secs = _stopwatch.elapsed.inSeconds;
        if (secs > 0) _wpm = ((_currentIndex / 5) / (secs / 60)).round();
        _wpmSamples.add(_wpm);
        if (_timeLeft <= 0) _onTimeUp();
      });
    });
  }

  void _onTimeUp() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() => _finished = true);
    _finishCtrl.forward();
    SoundService().playLevelComplete();
    _saveSession();
  }

  Future<void> _saveSession() async {
    final wordsTyped = _currentIndex ~/ 5;
    final accuracy = _errorCount == 0 || _currentIndex == 0
        ? 100.0
        : ((_currentIndex - _errorCount) / _currentIndex * 100).clamp(
            0.0,
            100.0,
          );

    await StatsService().recordSession(
      TypingSession(
        date: DateTime.now(),
        wpm: _wpm,
        accuracy: accuracy,
        wordsTyped: wordsTyped,
        durationSeconds: _selectedDuration,
        mode: 'timed',
      ),
    );

    await AchievementsService().checkAll(
      bestWpm: StatsService().getBestWpm(),
      lastAccuracy: accuracy,
      totalSessions: StatsService().getTotalSessions(),
      totalWords: StatsService().getTotalWords(),
      totalTimeSeconds: StatsService().getTotalTimeSeconds(),
      timedFirst: true,
    );
  }

  void _handleKey(KeyEvent event) {
    if (_finished) return;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    String? char;
    if (event.character != null && event.character!.isNotEmpty) {
      char = event.character!;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      char = ' ';
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_currentIndex > 0 && _lastWasWrong) {
        setState(() {
          _currentIndex--;
          _lastWasWrong = false;
        });
        SoundService().playKeyClick();
        _scrollToCursor();
      }
      return;
    }
    if (char == null) return;

    if (!_started) {
      _started = true;
      _startTimer();
    }

    if (_currentIndex >= _text.length) return;
    final expected = _text[_currentIndex];

    if (char == expected) {
      SoundService().playKeyClick();
      setState(() {
        _currentIndex++;
        _lastWasWrong = false;
        _correctStreak++;
      });

      _scrollToCursor();

      if (_correctStreak > 0 && _correctStreak % 20 == 0) {
        SoundService().playStreak();
      }
      // Generate more text if running low
      if (_currentIndex > _text.length - 50) {
        setState(() => _text += ' ${_generateText(100)}');
      }
    } else {
      SoundService().playError();
      setState(() {
        _lastWasWrong = true;
        _errorCount++;
        _correctStreak = 0;
      });
      _scrollToCursor();
    }
  }

  String get _timerColor {
    if (_timeLeft > 30) return 'normal';
    if (_timeLeft > 10) return 'warning';
    return 'danger';
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = _errorCount == 0 || _currentIndex == 0
        ? 100.0
        : ((_currentIndex - _errorCount) / _currentIndex * 100).clamp(
            0.0,
            100.0,
          );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'TIMED CHALLENGE',
          style: AppTheme.heading(16, color: AppTheme.primary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: _finished ? _buildResults(accuracy) : _buildTypingView(accuracy),
      ),
    );
  }

  Widget _buildTypingView(double accuracy) {
    final timerColor = _timerColor == 'danger'
        ? AppTheme.error
        : _timerColor == 'warning'
        ? AppTheme.error
        : AppTheme.primary;

    return Column(
      children: [
        // Top bar: timer + duration selector + stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: AppTheme.surface,
          child: Row(
            children: [
              // Duration pills
              if (!_started) ...[
                ..._durations.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _reset(_durations[e.key]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _selectedDuration == _durations[e.key] &&
                                  !_isCustom
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : AppTheme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                _selectedDuration == _durations[e.key] &&
                                    !_isCustom
                                ? AppTheme.primary
                                : AppTheme.cardBorder,
                          ),
                        ),
                        child: Text(
                          _labels[e.key],
                          style: AppTheme.body(
                            12,
                            color:
                                _selectedDuration == _durations[e.key] &&
                                    !_isCustom
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Custom time pill
                GestureDetector(
                  onTap: _pickCustomTime,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isCustom
                          ? AppTheme.lavender.withValues(alpha: 0.15)
                          : AppTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isCustom
                            ? AppTheme.lavender
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 13,
                          color: _isCustom
                              ? AppTheme.lavender
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isCustom
                              ? _formatDuration(_selectedDuration)
                              : 'Custom',
                          style: AppTheme.body(
                            12,
                            color: _isCustom
                                ? AppTheme.lavender
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Big timer
              Text(
                _timeLeft >= 60
                    ? '${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}'
                    : '$_timeLeft',
                style: AppTheme.heading(28, color: timerColor),
              ),
              const SizedBox(width: 24),
              _StatsChip('WPM', '$_wpm', AppTheme.primary),
              const SizedBox(width: 16),
              _StatsChip(
                'ACC',
                '${accuracy.toStringAsFixed(0)}%',
                AppTheme.gold,
              ),
            ],
          ),
        ),

        // WPM graph
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          color: AppTheme.surface,
          child: WpmGraph(samples: _wpmSamples, height: 60),
        ),
        Container(height: 1, color: AppTheme.cardBorder),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                if (!_started)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Type as many words as you can before the timer runs out!',
                          style: AppTheme.body(13, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                if (!_started) const SizedBox(height: 16),
                Expanded(child: _buildTextArea()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _lastWasWrong
              ? AppTheme.error.withValues(alpha: 0.4)
              : AppTheme.cardBorder,
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Wrap(
          children: List.generate(min(_currentIndex + 200, _text.length), (i) {
            Color color;
            Color? bg;
            if (i < _currentIndex) {
              color = AppTheme.textSecondary.withValues(alpha: 0.4);
              bg = null;
            } else if (i == _currentIndex) {
              color = _lastWasWrong ? AppTheme.error : AppTheme.textPrimary;
              bg = _lastWasWrong
                  ? AppTheme.error.withValues(alpha: 0.2)
                  : AppTheme.primary.withValues(alpha: 0.2);
            } else {
              color = AppTheme.textPrimary;
              bg = null;
            }
            return Container(
              key: i == _currentIndex ? _cursorKey : null,
              padding: const EdgeInsets.symmetric(vertical: 1),
              decoration: bg != null
                  ? BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(3),
                    )
                  : null,
              child: Text(_text[i], style: AppTheme.mono(22, color: color)),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildResults(double accuracy) {
    final wordsTyped = _currentIndex ~/ 5;

    return ScaleTransition(
      scale: _finishAnim,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏱️', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                'TIME\'S UP!',
                style: AppTheme.heading(28, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _ResultStat('WPM', '$_wpm', AppTheme.primary),
                  ),
                  Container(width: 1, height: 50, color: AppTheme.cardBorder),
                  Expanded(
                    child: _ResultStat(
                      'ACCURACY',
                      '${accuracy.toStringAsFixed(1)}%',
                      AppTheme.gold,
                    ),
                  ),
                  Container(width: 1, height: 50, color: AppTheme.cardBorder),
                  Expanded(
                    child: _ResultStat(
                      'WORDS',
                      '$wordsTyped',
                      AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Mini graph
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: WpmGraph(samples: _wpmSamples),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('AGAIN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () =>
                          _reset(_selectedDuration, isCustom: _isCustom),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ..._durations
                      .where((d) => d != _selectedDuration || _isCustom)
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                            onPressed: () => _reset(d),
                            child: Text(
                              d >= 60 ? '${d ~/ 60}MIN' : '${d}s',
                              style: AppTheme.body(13),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsChip extends StatelessWidget {
  final String label;
  final String val;
  final Color color;
  const _StatsChip(this.label, this.val, this.color);
  @override
  Widget build(BuildContext ctx) => Row(
    children: [
      Text(
        label,
        style: AppTheme.body(
          11,
          color: AppTheme.textMuted,
        ).copyWith(letterSpacing: 1),
      ),
      const SizedBox(width: 5),
      Text(val, style: AppTheme.heading(16, color: color)),
    ],
  );
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String val;
  final Color color;
  const _ResultStat(this.label, this.val, this.color);
  @override
  Widget build(BuildContext ctx) => Column(
    children: [
      Text(val, style: AppTheme.heading(26, color: color)),
      const SizedBox(height: 4),
      Text(
        label,
        style: AppTheme.body(
          11,
          color: AppTheme.textSecondary,
        ).copyWith(letterSpacing: 1),
      ),
    ],
  );
}

// ── Custom Time Picker Dialog ──────────────────────────────────────────────
class _CustomTimeDialog extends StatefulWidget {
  final int initialMinutes;
  final int initialSeconds;
  final void Function(int minutes, int seconds) onConfirm;

  const _CustomTimeDialog({
    required this.initialMinutes,
    required this.initialSeconds,
    required this.onConfirm,
  });

  @override
  State<_CustomTimeDialog> createState() => _CustomTimeDialogState();
}

class _CustomTimeDialogState extends State<_CustomTimeDialog> {
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes;
    _seconds = widget.initialSeconds;
  }

  bool get _valid => (_minutes * 60 + _seconds) >= 10;

  String get _preview {
    final total = _minutes * 60 + _seconds;
    if (total < 60) return '${total}s';
    if (_seconds == 0) return '$_minutes min';
    return '$_minutes min ${_seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lavender.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: AppTheme.lavender,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Custom Time', style: AppTheme.heading(18)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Set your own practice duration.',
              style: AppTheme.body(13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // Minutes picker
            _PickerRow(
              label: 'Minutes',
              value: _minutes,
              min: 0,
              max: 99,
              onChanged: (v) => setState(() => _minutes = v),
            ),
            const SizedBox(height: 16),

            // Seconds picker
            _PickerRow(
              label: 'Seconds',
              value: _seconds,
              min: 0,
              max: 59,
              step: 5,
              onChanged: (v) => setState(() => _seconds = v),
            ),
            const SizedBox(height: 20),

            // Preview
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _valid
                    ? AppTheme.lavender.withValues(alpha: 0.1)
                    : AppTheme.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _valid
                      ? AppTheme.lavender.withValues(alpha: 0.4)
                      : AppTheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _valid ? _preview : 'Too short',
                    style: AppTheme.heading(
                      26,
                      color: _valid ? AppTheme.lavender : AppTheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _valid ? 'duration selected' : 'minimum is 10 seconds',
                    style: AppTheme.body(11, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text('Cancel', style: AppTheme.body(14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _valid
                        ? () {
                            Navigator.pop(context);
                            widget.onConfirm(_minutes, _seconds);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lavender,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      disabledBackgroundColor: AppTheme.cardBorder,
                      elevation: 0,
                    ),
                    child: Text(
                      'Start',
                      style: AppTheme.body(14, weight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stepper row for minutes/seconds ───────────────────────────────────────
class _PickerRow extends StatelessWidget {
  final String label;
  final int value, min, max;
  final int step;
  final void Function(int) onChanged;

  const _PickerRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTheme.body(14, color: AppTheme.textSecondary),
          ),
        ),
        const Spacer(),
        // Decrement
        _StepBtn(
          icon: Icons.remove_rounded,
          enabled: value > min,
          onTap: () => onChanged((value - step).clamp(min, max)),
        ),
        const SizedBox(width: 16),
        // Value display
        SizedBox(
          width: 52,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: AppTheme.heading(28, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 16),
        // Increment
        _StepBtn(
          icon: Icons.add_rounded,
          enabled: value < max,
          onTap: () => onChanged((value + step).clamp(min, max)),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: enabled
            ? AppTheme.primary.withValues(alpha: 0.1)
            : AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.cardBorder,
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: enabled ? AppTheme.primary : AppTheme.textMuted,
      ),
    ),
  );
}
