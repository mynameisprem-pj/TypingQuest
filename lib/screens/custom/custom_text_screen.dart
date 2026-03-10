import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../../services/stats_service.dart';
import '../../services/achievements_service.dart';
import '../../widgets/wpm_graph.dart';
import '../../widgets/achievement_toast.dart';

class CustomTextScreen extends StatefulWidget {
  const CustomTextScreen({super.key});

  @override
  State<CustomTextScreen> createState() => _CustomTextScreenState();
}

class _CustomTextScreenState extends State<CustomTextScreen> {
  bool _practiceMode = false;
  final _textCtrl = TextEditingController();

  // Practice state
  late String _targetText;
  int _currentIndex = 0;
  bool _lastWasWrong = false;
  int _errorCount = 0;
  bool _started = false;
  bool _finished = false;
  int _wpm = 0;
  int _seconds = 0;
  late Stopwatch _stopwatch;
  Timer? _timer;
  final List<int> _wpmSamples = [];
  int _correctStreak = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    // Rebuild when text changes so the Start button enables/disables correctly
    _textCtrl.addListener(() => setState(() {}));
    AchievementsService().onUnlock = (ach) {
      if (mounted) { SoundService().playAchievement(); showAchievementToast(context, ach); }
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startPractice() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _targetText = text;
      _practiceMode = true;
      _currentIndex = 0;
      _lastWasWrong = false;
      _errorCount = 0;
      _started = false;
      _finished = false;
      _wpm = 0;
      _seconds = 0;
      _wpmSamples.clear();
      _correctStreak = 0;
    });
    _stopwatch.reset();
    _timer?.cancel();
  }

  void _handleKey(KeyEvent event) {
    if (_finished) return;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    String? char;
    if (event.character != null && event.character!.isNotEmpty) {
      char = event.character!;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {char = ' ';}
    else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_currentIndex > 0 && _lastWasWrong) setState(() { _currentIndex--; _lastWasWrong = false; });
      return;
    }
    if (char == null) return;

    if (!_started) {
      _started = true;
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _seconds = _stopwatch.elapsed.inSeconds;
          if (_seconds > 0) _wpm = ((_currentIndex / 5) / (_seconds / 60)).round();
          _wpmSamples.add(_wpm);
        });
      });
    }

    final expected = _targetText[_currentIndex];
    if (char == expected) {
      SoundService().playKeyClick();
      setState(() { _currentIndex++; _lastWasWrong = false; _correctStreak++; });
      if (_correctStreak % 20 == 0) SoundService().playStreak();
      if (_currentIndex == _targetText.length) _onFinish();
    } else {
      SoundService().playError();
      setState(() { _lastWasWrong = true; _errorCount++; _correctStreak = 0; });
    }
  }

  Future<void> _onFinish() async {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() => _finished = true);
    SoundService().playLevelComplete();
    final accuracy = _errorCount == 0 || _currentIndex == 0 ? 100.0 : ((_targetText.length - _errorCount) / _targetText.length * 100).clamp(0.0, 100.0);
    await StatsService().recordSession(TypingSession(date: DateTime.now(), wpm: _wpm, accuracy: accuracy, wordsTyped: _currentIndex ~/ 5, durationSeconds: _seconds, mode: 'custom'));
    await AchievementsService().checkAll(bestWpm: StatsService().getBestWpm(), lastAccuracy: accuracy, totalSessions: StatsService().getTotalSessions(), customFirst: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text('CUSTOM TEXT', style: AppTheme.heading(16, color: const Color(0xFFCE93D8))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: _practiceMode ? () => setState(() => _practiceMode = false) : () => Navigator.pop(context),
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppTheme.cardBorder)),
      ),
      body: _practiceMode ? _buildPractice() : _buildInputPanel(),
    );
  }

  Widget _buildInputPanel() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.edit_outlined, color: Color(0xFFCE93D8), size: 40),
            const SizedBox(height: 16),
            Text('Practice Your Own Text', style: AppTheme.heading(26)),
            const SizedBox(height: 8),
            Text('Paste any text — your notes, an article, a book chapter, code — and practice typing it.', style: AppTheme.body(14, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),

            // Quick presets
            Text('QUICK PRESETS', style: AppTheme.body(12, color: AppTheme.textSecondary).copyWith(letterSpacing: 2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _PresetChip('Alphabet', 'the quick brown fox jumps over the lazy dog'),
                _PresetChip('Nepal facts', 'Nepal is a landlocked country in South Asia. It is home to eight of the ten tallest mountains in the world, including Mount Everest.'),
                _PresetChip('Computer basics', 'A computer is an electronic device that processes data. It takes input from the user, processes it, and produces output.'),
                _PresetChip('Code snippet', 'void main() { print("Hello, World!"); int x = 42; if (x > 0) { print("Positive"); } }'),
              ].map((c) => GestureDetector(
                onTap: () {
                  _textCtrl.value = TextEditingValue(
                    text: c.text,
                    selection: TextSelection.collapsed(offset: c.text.length),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCE93D8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCE93D8).withValues(alpha: 0.3)),
                  ),
                  child: Text(c.label, style: AppTheme.body(12, color: const Color(0xFFCE93D8))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Text input
            Expanded(
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                expands: true,
                style: AppTheme.mono(14),
                decoration: InputDecoration(
                  hintText: 'Paste or type your practice text here...',
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(16),
                  filled: true,
                  fillColor: AppTheme.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCE93D8), width: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('START PRACTICE', style: AppTheme.heading(14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCE93D8),
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _textCtrl.text.trim().isEmpty ? null : _startPractice,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPractice() {
    final accuracy = _errorCount == 0 || _currentIndex == 0 ? 100.0 : ((_currentIndex - _errorCount) / _currentIndex * 100).clamp(0.0, 100.0);
    final prog = _currentIndex / _targetText.length;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppTheme.surface,
            child: Row(children: [
              _Chip('WPM', '$_wpm', AppTheme.primary),
              const SizedBox(width: 16),
              _Chip('ACC', '${accuracy.toStringAsFixed(0)}%', AppTheme.gold),
              const SizedBox(width: 16),
              _Chip('TIME', '${_seconds}s', AppTheme.textSecondary),
              const Spacer(),
              Text('$_currentIndex/${_targetText.length}', style: AppTheme.body(12, color: AppTheme.textSecondary)),
            ]),
          ),
          LinearProgressIndicator(value: prog, backgroundColor: AppTheme.cardBorder, valueColor: const AlwaysStoppedAnimation(Color(0xFFCE93D8)), minHeight: 3),
          // WPM graph
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: WpmGraph(samples: _wpmSamples, height: 50),
          ),
          Container(height: 1, color: AppTheme.cardBorder),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _finished ? AppTheme.success.withValues(alpha: 0.4) : AppTheme.cardBorder),
                ),
                child: _finished
                    ? _buildDoneOverlay(accuracy)
                    : SingleChildScrollView(child: _buildTextDisplay()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextDisplay() {
    return RichText(
      text: TextSpan(
        children: List.generate(_targetText.length, (i) {
          Color color; Color? bg;
          if (i < _currentIndex) {
            color = AppTheme.textSecondary.withValues(alpha: 0.4);
          } else if (i == _currentIndex) { color = _lastWasWrong ? AppTheme.error : AppTheme.textPrimary; bg = _lastWasWrong ? AppTheme.error.withValues(alpha: 0.2) : AppTheme.primary.withValues(alpha: 0.2); }
          else {color = AppTheme.textPrimary;}
          return WidgetSpan(child: Container(
            padding: const EdgeInsets.symmetric(vertical: 1),
            decoration: bg != null ? BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)) : null,
            child: Text(_targetText[i], style: AppTheme.mono(20, color: color)),
          ));
        }),
      ),
    );
  }

  Widget _buildDoneOverlay(double accuracy) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('✅', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      Text('Text Complete!', style: AppTheme.heading(24, color: AppTheme.success)),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _ResultStat('WPM', '$_wpm', AppTheme.primary),
        const SizedBox(width: 32),
        _ResultStat('ACC', '${accuracy.toStringAsFixed(1)}%', AppTheme.gold),
        const SizedBox(width: 32),
        _ResultStat('WORDS', '${_currentIndex ~/ 5}', AppTheme.success),
      ]),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text('AGAIN'), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary, side: const BorderSide(color: AppTheme.cardBorder)), onPressed: _startPractice),
        const SizedBox(width: 12),
        ElevatedButton.icon(icon: const Icon(Icons.edit_outlined), label: const Text('NEW TEXT'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCE93D8), foregroundColor: AppTheme.background), onPressed: () => setState(() => _practiceMode = false)),
      ]),
    ]));
  }
}

class _PresetChip { final String label; final String text; const _PresetChip(this.label, this.text); }
class _Chip extends StatelessWidget {
  final String l, v; final Color c;
  const _Chip(this.l, this.v, this.c);
  @override Widget build(BuildContext ctx) => Row(children: [Text(l, style: AppTheme.body(11, color: AppTheme.textMuted).copyWith(letterSpacing: 1)), const SizedBox(width: 5), Text(v, style: AppTheme.heading(16, color: c))]);
}
class _ResultStat extends StatelessWidget {
  final String l, v; final Color c;
  const _ResultStat(this.l, this.v, this.c);
  @override Widget build(BuildContext ctx) => Column(children: [Text(v, style: AppTheme.heading(24, color: c)), const SizedBox(height: 4), Text(l, style: AppTheme.body(11, color: AppTheme.textSecondary))]);
}