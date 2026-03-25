import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../data/lesson_data.dart';
import '../../services/lesson_progress_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/virtual_keyboard.dart';

class ExerciseScreen extends StatefulWidget {
  final LessonCourse course;
  final Lesson lesson;
  final int startExercise;

  const ExerciseScreen({
    super.key,
    required this.course,
    required this.lesson,
    required this.startExercise,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with TickerProviderStateMixin {
  late int _exerciseIndex;
  late LessonExercise _currentExercise;

  // Typing state
  int _currentIndex = 0;
  bool _lastWasWrong = false;
  bool _errorRecordedForCurrentChar = false;
  int _errorCount = 0;
  bool _started = false;
  bool _exerciseDone = false;

  // Timer
  late Stopwatch _stopwatch;
  Timer? _timer;
  int _seconds = 0;
  int _wpm = 0;

  // Animations
  late AnimationController _completeController;
  late AnimationController _shakeController;
  late Animation<double> _completeAnim;
  late Animation<Offset> _shakeAnim;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _exerciseIndex = widget.startExercise;
    _currentExercise = widget.lesson.exercises[_exerciseIndex];
    _stopwatch = Stopwatch();

    _completeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _completeAnim = CurvedAnimation(parent: _completeController, curve: Curves.elasticOut);

    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _shakeAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0.015, 0))
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _completeController.dispose();
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetForExercise(int index) {
    setState(() {
      _exerciseIndex = index;
      _currentExercise = widget.lesson.exercises[index];
      _currentIndex = 0;
      _lastWasWrong = false;
      _errorRecordedForCurrentChar = false;
      _errorCount = 0;
      _started = false;
      _exerciseDone = false;
      _seconds = 0;
      _wpm = 0;
    });
    _stopwatch.reset();
    _timer?.cancel();
    _completeController.reset();
  }

  void _handleKey(KeyEvent event) {
    if (_exerciseDone) return;
    if (event is! KeyDownEvent) return;

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
          _errorRecordedForCurrentChar = false;
        });
        SoundService().playKeyClick();
      }
      return;
    }
    if (char == null) return;

    if (!_started) {
      _started = true;
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        setState(() {
          _seconds = _stopwatch.elapsed.inSeconds;
          final elapsedMs = _stopwatch.elapsedMilliseconds;
          if (elapsedMs > 0) {
            _wpm = ((_currentIndex / 5) / (elapsedMs / 60000)).round();
          }
        });
      });
    }

    final expected = _currentExercise.text[_currentIndex];

    if (char == expected) {
      SoundService().playKeyClick();
      setState(() {
        _currentIndex++;
        _lastWasWrong = false;
        _errorRecordedForCurrentChar = false;
        if (_currentIndex == _currentExercise.text.length) _onExerciseComplete();
      });
    } else {
      SoundService().playError();
      setState(() {
        _lastWasWrong = true;
        if (!_errorRecordedForCurrentChar) {
          _errorCount++;
          _errorRecordedForCurrentChar = true;
        }
      });
      _shakeController.forward(from: 0);
    }
  }

  void _onExerciseComplete() {
    _stopwatch.stop();
    _timer?.cancel();
    _exerciseDone = true;
    SoundService().playLevelComplete();

    final accuracy = _errorCount == 0
        ? 100.0
        : ((_currentExercise.text.length - _errorCount) / _currentExercise.text.length * 100).clamp(0, 100).toDouble();

    LessonProgressService().markExerciseComplete(
      widget.course.id,
      widget.lesson.id,
      _exerciseIndex,
      _wpm,
      accuracy,
    );

    _completeController.forward();
  }

  void _goNextExercise() {
    if (_exerciseIndex < widget.lesson.exercises.length - 1) {
      _resetForExercise(_exerciseIndex + 1);
    } else {
      // All exercises done — mark lesson complete
      final lessonIndex = widget.course.lessons.indexWhere((l) => l.id == widget.lesson.id);
      LessonProgressService().markLessonComplete(
        widget.course.id,
        widget.lesson.id,
        lessonIndex >= 0 ? lessonIndex : 0,
      );
      _showLessonCompleteDialog();
    }
  }

  void _showLessonCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LessonCompleteDialog(
        lessonTitle: widget.lesson.title,
        bestWpm: LessonProgressService().getBestWpm(widget.course.id, widget.lesson.id),
        onContinue: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _currentExercise.text;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Column(
          children: [
            // Stats bar
            _buildStatsBar(),
            Expanded(
              child: SlideTransition(
                position: _shakeAnim,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      // Hint box
                      _buildHintBox(),
                      const SizedBox(height: 20),
                      // Text display
                      Expanded(child: _buildTextArea(text)),
                      const SizedBox(height: 16),
                      // Next button (when done)
                      if (_exerciseDone) _buildNextButton(),
                    ],
                  ),
                ),
              ),
            ),
            // Virtual keyboard
            RepaintBoundary(
              child: IgnorePointer(
                child: VirtualKeyboard(
                  highlightChar: _exerciseDone ? null : (_currentIndex < text.length ? text[_currentIndex] : null),
                  wasWrong: _lastWasWrong,
                  showFingerColors: true,
                  showHandGuide: true,
                ),
              ),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.lesson.title, style: AppTheme.heading(14)),
          Text(
            'Exercise ${_exerciseIndex + 1} of ${widget.lesson.exercises.length}: ${_currentExercise.title}',
            style: AppTheme.body(11, color: AppTheme.textSecondary),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Row(
          children: List.generate(widget.lesson.exercises.length, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: i < _exerciseIndex
                    ? AppTheme.success
                    : i == _exerciseIndex
                        ? (_exerciseDone ? AppTheme.success : AppTheme.primary)
                        : AppTheme.cardBorder,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final accuracy = _errorCount == 0 || _currentIndex == 0
        ? 100.0
        : ((_currentIndex - _errorCount) / _currentIndex * 100).clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          _Chip('WPM', '$_wpm', AppTheme.primary),
          const SizedBox(width: 16),
          _Chip('ACC', '${accuracy.toStringAsFixed(0)}%', AppTheme.gold),
          const SizedBox(width: 16),
          _Chip('TIME', '${_seconds}s', AppTheme.textSecondary),
          const Spacer(),
          Text('$_currentIndex/${_currentExercise.text.length}', style: AppTheme.body(13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildHintBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(_currentExercise.hint, style: AppTheme.body(13, color: AppTheme.primary))),
        ],
      ),
    );
  }

  Widget _buildTextArea(String text) {
    final beforeStyle = AppTheme.mono(
      26,
      color: AppTheme.textSecondary.withValues(alpha: 0.5),
    );
    final afterStyle = AppTheme.mono(26, color: AppTheme.textPrimary);
    final currentStyle = AppTheme.mono(
      26,
      color: _lastWasWrong ? AppTheme.error : AppTheme.textPrimary,
    ).copyWith(
      backgroundColor: _lastWasWrong
          ? AppTheme.error.withValues(alpha: 0.2)
          : AppTheme.primary.withValues(alpha: 0.2),
    );

    final spans = <InlineSpan>[];
    if (_currentIndex > 0) {
      spans.add(TextSpan(text: text.substring(0, _currentIndex), style: beforeStyle));
    }
    if (_currentIndex < text.length) {
      spans.add(TextSpan(text: text[_currentIndex], style: currentStyle));
    }
    if (_currentIndex + 1 < text.length) {
      spans.add(TextSpan(text: text.substring(_currentIndex + 1), style: afterStyle));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _exerciseDone ? AppTheme.success.withValues(alpha: 0.5) : (_lastWasWrong ? AppTheme.error.withValues(alpha: 0.5) : AppTheme.cardBorder),
        ),
      ),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: spans),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return ScaleTransition(
      scale: _completeAnim,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(_exerciseIndex < widget.lesson.exercises.length - 1 ? Icons.arrow_forward : Icons.check_circle_outline),
          label: Text(
            _exerciseIndex < widget.lesson.exercises.length - 1 ? 'NEXT EXERCISE' : 'COMPLETE LESSON',
            style: AppTheme.heading(14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: AppTheme.background,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _goNextExercise,
        ),
      ),
    );
  }
}

// ── Small chips ───────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Chip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: AppTheme.body(11, color: AppTheme.textMuted).copyWith(letterSpacing: 1)),
      const SizedBox(width: 6),
      Text(value, style: AppTheme.heading(16, color: color)),
    ]);
  }
}

// ── Lesson complete dialog ─────────────────────────────────────────────────
class _LessonCompleteDialog extends StatelessWidget {
  final String lessonTitle;
  final int bestWpm;
  final VoidCallback onContinue;

  const _LessonCompleteDialog({
    required this.lessonTitle,
    required this.bestWpm,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.success.withValues(alpha: 0.5)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: const Text('🎉', style: TextStyle(fontSize: 60)),
            ),
            const SizedBox(height: 16),
            Text('LESSON COMPLETE!', style: AppTheme.heading(22, color: AppTheme.success)),
            const SizedBox(height: 8),
            Text(lessonTitle, style: AppTheme.body(15, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            if (bestWpm > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Best: $bestWpm WPM', style: AppTheme.heading(18, color: AppTheme.primary)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onContinue,
                child: Text('CONTINUE', style: AppTheme.heading(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
