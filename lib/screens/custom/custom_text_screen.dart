import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../../services/stats_service.dart';
import '../../services/achievements_service.dart';
import '../../widgets/wpm_graph.dart';
import '../../widgets/achievement_toast.dart';

// ── Token: one word or one paragraph-break marker ───────────────────────────
class _Token {
  final String text;       // actual characters to type
  final bool isParagraph;  // visual paragraph break (typed as a space)
  const _Token(this.text, {this.isParagraph = false});
}

// ── Normalize raw pasted text into a token list ──────────────────────────────
List<_Token> _tokenize(String raw) {
  // Split on paragraph breaks (2+ newlines)
  final paragraphs = raw.split(RegExp(r'\n{2,}'));
  final tokens = <_Token>[];

  for (int pi = 0; pi < paragraphs.length; pi++) {
    // Within each paragraph collapse all whitespace to single spaces
    final words = paragraphs[pi]
        .trim()
        .replaceAll(RegExp(r'[ \t\r\n]+'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    for (int wi = 0; wi < words.length; wi++) {
      tokens.add(_Token(words[wi]));
      // Add a space after every word except the last word of the last paragraph
      if (wi < words.length - 1 || pi < paragraphs.length - 1) {
        tokens.add(_Token(' '));
      }
    }

    // After each paragraph (except last) add a visible paragraph-break token
    // typed as a single space
    if (pi < paragraphs.length - 1) {
      tokens.add(_Token(' ', isParagraph: true));
    }
  }
  return tokens;
}

// ── Flatten tokens back to a single string for WPM counting ─────────────────
String _tokensToString(List<_Token> tokens) =>
    tokens.map((t) => t.text).join();

// ═════════════════════════════════════════════════════════════════════════════
class CustomTextScreen extends StatefulWidget {
  const CustomTextScreen({super.key});
  @override
  State<CustomTextScreen> createState() => _CustomTextScreenState();
}

class _CustomTextScreenState extends State<CustomTextScreen> {
  bool _practiceMode = false;
  final _textCtrl = TextEditingController();

  // ── Practice state ─────────────────────────────────────────────────────────
  List<_Token> _tokens = [];
  String _targetFlat = '';   // flat string for index math

  int  _currentIndex = 0;    // index into _targetFlat
  bool _lastWasWrong = false;
  int  _errorCount   = 0;
  bool _started      = false;
  bool _finished     = false;
  int  _wpm          = 0;
  int  _seconds      = 0;
  late Stopwatch _stopwatch;
  Timer? _timer;
  final List<int> _wpmSamples = [];
  int _correctStreak = 0;

  // ── Scroll / cursor ────────────────────────────────────────────────────────
  final FocusNode       _focusNode      = FocusNode();
  final ScrollController _scrollCtrl    = ScrollController();
  final GlobalKey        _cursorKey     = GlobalKey();

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const _accent = Color(0xFFCE93D8);

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _textCtrl.addListener(() => setState(() {}));
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
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Start ──────────────────────────────────────────────────────────────────
  void _startPractice() {
    final raw = _textCtrl.text;
    if (raw.trim().isEmpty) return;

    final tokens = _tokenize(raw);
    final flat   = _tokensToString(tokens);
    if (flat.isEmpty) return;

    _timer?.cancel();
    _stopwatch.reset();

    setState(() {
      _tokens       = tokens;
      _targetFlat   = flat;
      _currentIndex = 0;
      _lastWasWrong = false;
      _errorCount   = 0;
      _started      = false;
      _finished     = false;
      _wpm          = 0;
      _seconds      = 0;
      _wpmSamples.clear();
      _correctStreak = 0;
      _practiceMode  = true;
    });
  }

  // ── Key handler ────────────────────────────────────────────────────────────
  void _handleKey(KeyEvent event) {
    if (_finished) return;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    String? char;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_currentIndex > 0 && _lastWasWrong) {
        setState(() { _currentIndex--; _lastWasWrong = false; });
        _scrollToCursor();
      }
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      char = ' '; // paragraph transition
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      char = ' ';
    } else if (event.character != null && event.character!.isNotEmpty) {
      // Primary source — works for letters, numbers
      char = event.character!;
    } else {
      // Fallback for symbols that event.character misses (apostrophe, quotes,
      // brackets, etc.) — keyLabel gives the raw key string e.g. "'" ";" "["
      final label = event.logicalKey.keyLabel;
      if (label.length == 1) char = label;
    }

    if (char == null) return;

    if (!_started) {
      _started = true;
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _seconds = _stopwatch.elapsed.inSeconds;
          if (_seconds > 0) {
            _wpm = ((_currentIndex / 5) / (_seconds / 60)).round();
          }
          _wpmSamples.add(_wpm);
        });
      });
    }

    if (_currentIndex >= _targetFlat.length) return;
    final expected = _targetFlat[_currentIndex];

    // If expected is a space (or paragraph-space), accept EITHER space OR enter
    final isSpaceToken = expected == ' ';
    final pressed      = char;
    final correct      = pressed == expected ||
        (isSpaceToken && (pressed == ' ' || pressed == '\n'));

    if (correct) {
      SoundService().playKeyClick();
      setState(() {
        _currentIndex++;
        _lastWasWrong  = false;
        _correctStreak++;
      });
      if (_correctStreak % 20 == 0) SoundService().playStreak();
      _scrollToCursor();
      if (_currentIndex == _targetFlat.length) _onFinish();
    } else {
      SoundService().playError();
      setState(() { _lastWasWrong = true; _errorCount++; _correctStreak = 0; });
    }
  }

  // ── Auto-scroll ────────────────────────────────────────────────────────────
  void _scrollToCursor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cursorKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          alignment: 0.35,
        );
      }
    });
  }

  // ── Finish ─────────────────────────────────────────────────────────────────
  Future<void> _onFinish() async {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() => _finished = true);
    SoundService().playLevelComplete();
    final accuracy = _errorCount == 0 || _currentIndex == 0
        ? 100.0
        : ((_targetFlat.length - _errorCount) / _targetFlat.length * 100)
            .clamp(0.0, 100.0);
    await StatsService().recordSession(TypingSession(
      date: DateTime.now(), wpm: _wpm, accuracy: accuracy,
      wordsTyped: _currentIndex ~/ 5, durationSeconds: _seconds, mode: 'custom',
    ));
    await AchievementsService().checkAll(
      bestWpm: StatsService().getBestWpm(), lastAccuracy: accuracy,
      totalSessions: StatsService().getTotalSessions(), customFirst: true,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text('CUSTOM TEXT', style: AppTheme.heading(16, color: _accent)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: _practiceMode
              ? () => setState(() => _practiceMode = false)
              : () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),
      body: _practiceMode ? _buildPractice() : _buildInputPanel(),
    );
  }

  // ── Input panel ────────────────────────────────────────────────────────────
  Widget _buildInputPanel() {
    final wordCount = _textCtrl.text.trim().isEmpty
        ? 0
        : _textCtrl.text.trim().split(RegExp(r'\s+')).length;
    final charCount = _textCtrl.text.length;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.edit_outlined, color: _accent, size: 40),
            const SizedBox(height: 16),
            Text('Practice Your Own Text', style: AppTheme.heading(26)),
            const SizedBox(height: 8),
            Text(
              'Paste any text — notes, articles, book chapters, code — and practice typing it.',
              style: AppTheme.body(14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // Presets
            Text('QUICK PRESETS',
                style: AppTheme.body(12, color: AppTheme.textSecondary)
                    .copyWith(letterSpacing: 2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _presets.map((p) => GestureDetector(
                onTap: () {
                  _textCtrl.value = TextEditingValue(
                    text: p.text,
                    selection: TextSelection.collapsed(offset: p.text.length),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(p.label, style: AppTheme.body(12, color: _accent)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Counter row
            Row(children: [
              Text('TEXT', style: AppTheme.body(11, color: AppTheme.textMuted)
                  .copyWith(letterSpacing: 2)),
              const Spacer(),
              if (wordCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$wordCount words',
                      style: AppTheme.body(11, color: _accent)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$charCount chars',
                      style: AppTheme.body(11, color: AppTheme.primary)),
                ),
              ],
            ]),
            const SizedBox(height: 8),

            // Text field
            Expanded(
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                expands: true,
                style: AppTheme.mono(14),
                decoration: InputDecoration(
                  hintText: 'Paste or type your text here...\n\nParagraphs are supported — each blank line creates a new paragraph.',
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(16),
                  filled: true,
                  fillColor: AppTheme.card,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.cardBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _accent, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Word count hint
            if (wordCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Icon(Icons.check_circle_outline,
                      size: 14,
                      color: wordCount >= 10 ? AppTheme.success : AppTheme.gold),
                  const SizedBox(width: 6),
                  Text(
                    wordCount < 10
                        ? 'Add a few more words to get started'
                        : 'Ready! $wordCount words across ${_textCtrl.text.split(RegExp(r'\n{2,}')).where((p) => p.trim().isNotEmpty).length} paragraph(s)',
                    style: AppTheme.body(12,
                        color: wordCount >= 10 ? AppTheme.success : AppTheme.gold),
                  ),
                ]),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('START PRACTICE', style: AppTheme.heading(14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: AppTheme.cardBorder,
                ),
                onPressed:
                    _textCtrl.text.trim().split(RegExp(r'\s+')).length >= 5
                        ? _startPractice
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Practice screen ────────────────────────────────────────────────────────
  Widget _buildPractice() {
    final accuracy = _errorCount == 0 || _currentIndex == 0
        ? 100.0
        : ((_currentIndex - _errorCount) / _currentIndex * 100)
            .clamp(0.0, 100.0);
    final prog = _currentIndex / _targetFlat.length;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Column(children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppTheme.surface,
          child: Row(children: [
            _Chip('WPM',  '$_wpm',                          AppTheme.primary),
            const SizedBox(width: 16),
            _Chip('ACC',  '${accuracy.toStringAsFixed(0)}%', AppTheme.gold),
            const SizedBox(width: 16),
            _Chip('TIME', '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2,'0')}',
                AppTheme.textSecondary),
            const Spacer(),
            // word progress
            Text(
              '${(_currentIndex / 5).floor()} / ${(_targetFlat.length / 5).floor()} words',
              style: AppTheme.body(12, color: AppTheme.textSecondary),
            ),
          ]),
        ),
        LinearProgressIndicator(
          value: prog,
          backgroundColor: AppTheme.cardBorder,
          valueColor: const AlwaysStoppedAnimation(_accent),
          minHeight: 3,
        ),
        // WPM graph
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: WpmGraph(samples: _wpmSamples, height: 48),
        ),
        Container(height: 1, color: AppTheme.cardBorder),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _finished
                      ? AppTheme.success.withValues(alpha: 0.4)
                      : _lastWasWrong
                          ? AppTheme.error.withValues(alpha: 0.35)
                          : AppTheme.cardBorder,
                ),
              ),
              child: _finished
                  ? _buildDoneOverlay(accuracy)
                  : _buildTextDisplay(),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Text display — word-by-word with auto-scroll ───────────────────────────
  Widget _buildTextDisplay() {
    // Build position map: token index → start char index in _targetFlat
    int pos = 0;
    final List<int> tokenStart = [];
    for (final t in _tokens) {
      tokenStart.add(pos);
      pos += t.text.length;
    }

    return SingleChildScrollView(
      controller: _scrollCtrl,
      child: Wrap(
        children: List.generate(_tokens.length, (ti) {
          final token   = _tokens[ti];
          final tStart  = tokenStart[ti];
          final tEnd    = tStart + token.text.length;
          final isCurrent = _currentIndex >= tStart && _currentIndex < tEnd;

          // ── Paragraph break marker ─────────────────────────────────────
          if (token.isParagraph) {
            return SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Container(
                    width: 28, height: 1,
                    color: AppTheme.cardBorder,
                  ),
                  const SizedBox(width: 8),
                  Text('¶',
                      style: AppTheme.body(12, color: AppTheme.textMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Container(height: 1, color: AppTheme.cardBorder)),
                ]),
              ),
            );
          }

          // ── Space token ────────────────────────────────────────────────
          if (token.text == ' ') {
            final done     = _currentIndex > tStart;
            final isCurSp  = _currentIndex == tStart;
            return Container(
              key: isCurSp ? _cursorKey : null,
              child: Text(
                ' ',
                style: AppTheme.mono(20,
                    color: done
                        ? AppTheme.textSecondary.withValues(alpha: 0.3)
                        : isCurSp
                            ? (_lastWasWrong
                                ? AppTheme.error
                                : AppTheme.textPrimary)
                            : AppTheme.textPrimary),
              ),
            );
          }

          // ── Word token: render character by character ──────────────────
          // NOTE: key is on the individual char below, NOT here — no duplicate keys
          return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(token.text.length, (ci) {
                final globalIdx = tStart + ci;
                final charDone  = globalIdx < _currentIndex;
                final charCur   = globalIdx == _currentIndex;

                Color charColor;
                Color? charBg;

                if (charDone) {
                  charColor = AppTheme.textSecondary.withValues(alpha: 0.45);
                } else if (charCur) {
                  charColor = _lastWasWrong
                      ? AppTheme.error
                      : AppTheme.textPrimary;
                  charBg    = _lastWasWrong
                      ? AppTheme.error.withValues(alpha: 0.18)
                      : _accent.withValues(alpha: 0.18);
                } else {
                  charColor = AppTheme.textPrimary;
                }

                return Container(
                  key: charCur ? _cursorKey : null,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: charBg != null
                      ? BoxDecoration(
                          color: charBg,
                          borderRadius: BorderRadius.circular(3))
                      : null,
                  child: Text(
                    token.text[ci],
                    style: AppTheme.mono(20, color: charColor),
                  ),
                );
              }),
          );
        }),
      ),
    );
  }

  // ── Done overlay ───────────────────────────────────────────────────────────
  Widget _buildDoneOverlay(double accuracy) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('✅', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text('Text Complete!', style: AppTheme.heading(24, color: AppTheme.success)),
        const SizedBox(height: 6),
        Text(
          '${(_targetFlat.length / 5).floor()} words typed',
          style: AppTheme.body(13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ResultStat('WPM',   '$_wpm',                         AppTheme.primary),
          const SizedBox(width: 32),
          _ResultStat('ACC',   '${accuracy.toStringAsFixed(1)}%', AppTheme.gold),
          const SizedBox(width: 32),
          _ResultStat('WORDS', '${_currentIndex ~/ 5}',          AppTheme.success),
          const SizedBox(width: 32),
          _ResultStat('TIME',
              '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, "0")}',
              AppTheme.textSecondary),
        ]),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('AGAIN'),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20)),
            onPressed: _startPractice,
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('NEW TEXT'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20)),
            onPressed: () => setState(() => _practiceMode = false),
          ),
        ]),
      ]),
    );
  }

  // ── Presets ────────────────────────────────────────────────────────────────
  static const _presets = [
    _PresetChip('Alphabet',
        'the quick brown fox jumps over the lazy dog'),
    _PresetChip('Nepal facts',
        'Nepal is a landlocked country in South Asia.\n\nIt is home to eight of the ten tallest mountains in the world, including Mount Everest.\n\nThe capital city is Kathmandu, which is also the largest city in Nepal.'),
    _PresetChip('Computer basics',
        'A computer is an electronic device that processes data.\n\nIt takes input from the user, processes it, and produces output.\n\nModern computers can perform billions of calculations per second.'),
    _PresetChip('Code snippet',
        'void main() {\n  print("Hello, World!");\n  int x = 42;\n  if (x > 0) {\n    print("Positive number");\n  }\n}'),
  ];
}

// ── Small helper widgets ──────────────────────────────────────────────────────
class _PresetChip {
  final String label, text;
  const _PresetChip(this.label, this.text);
}

class _Chip extends StatelessWidget {
  final String l, v; final Color c;
  const _Chip(this.l, this.v, this.c);
  @override
  Widget build(BuildContext ctx) => Row(children: [
    Text(l, style: AppTheme.body(11, color: AppTheme.textMuted)
        .copyWith(letterSpacing: 1)),
    const SizedBox(width: 5),
    Text(v, style: AppTheme.heading(16, color: c)),
  ]);
}

class _ResultStat extends StatelessWidget {
  final String l, v; final Color c;
  const _ResultStat(this.l, this.v, this.c);
  @override
  Widget build(BuildContext ctx) => Column(children: [
    Text(v, style: AppTheme.heading(22, color: c)),
    const SizedBox(height: 4),
    Text(l, style: AppTheme.body(11, color: AppTheme.textSecondary)),
  ]);
}