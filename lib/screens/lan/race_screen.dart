import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../services/lan_service.dart';
import '../../services/sound_service.dart';

class RaceScreen extends StatefulWidget {
  final bool isHost;
  final String playerName, raceText;
  final LanHostService? hostService;
  final LanClientService? clientService;
  final bool timedMode;
  final int timeLimitSeconds;
  final int? startAtMs;
  final List<LanPlayer> initialPlayers;

  const RaceScreen({
    super.key,
    required this.isHost,
    required this.playerName,
    required this.raceText,
    this.hostService,
    this.clientService,
    this.timedMode = false,
    this.timeLimitSeconds = 60,
    this.startAtMs,
    this.initialPlayers = const [],
  });

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  // Typing
  int _currentIndex = 0;
  bool _lastWasWrong = false;
  int _errorCount = 0;
  bool _finished = false;

  // Players
  List<LanPlayer> _allPlayers = [];
  bool _allDone = false;

  // Timers
  late Stopwatch _stopwatch;
  Timer? _uiTimer, _progressTimer;

  // Stats — WPM is only recalculated when _currentIndex changes,
  // not on every UI timer tick, to save CPU on low-end PCs
  int _wpm = 0, _elapsedSecs = 0, _remainingSecs = 0, _wordsTyped = 0;
  int _lastIndexForWpm = -1; // tracks whether recalc is needed
  bool _timedEnded = false;
  bool _cleanedUp = false;
  int? _serverStartAtMs;
  LanRacePhase _phase = LanRacePhase.lobby;

  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();

    _allPlayers = List.from(widget.initialPlayers);
    _remainingSecs = widget.timeLimitSeconds;
    _serverStartAtMs = widget.startAtMs;
    _phase = _serverStartAtMs == null
        ? LanRacePhase.racing
        : LanRacePhase.countdown;

    _stopwatch = Stopwatch();
    if (_phase == LanRacePhase.racing) _stopwatch.start();

    // UI timer: 200ms — only calls setState when something actually changed
    _uiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (_phase == LanRacePhase.countdown &&
          _serverStartAtMs != null &&
          nowMs >= _serverStartAtMs!) {
        _handlePhaseChanged(LanRacePhase.racing);
      }

      final newElapsed = _stopwatch.elapsed.inSeconds;
      final newRemaining = widget.timedMode && _phase == LanRacePhase.racing
          ? (widget.timeLimitSeconds - newElapsed).clamp(0, widget.timeLimitSeconds)
          : _remainingSecs;

      // Only recalculate WPM if index changed since last check
      if (_currentIndex != _lastIndexForWpm) {
        _lastIndexForWpm = _currentIndex;
        _updateWpm(newElapsed);
      }

      bool timedShouldEnd = widget.timedMode &&
          _phase == LanRacePhase.racing &&
          newRemaining == 0 &&
          !_timedEnded;

      setState(() {
        _elapsedSecs = newElapsed;
        _remainingSecs = newRemaining;
      });

      if (timedShouldEnd) _onTimedEnd();
    });

    _progressTimer = Timer.periodic(
        const Duration(milliseconds: 250), (_) => _sendProgress());

    // Callbacks
    if (widget.isHost && widget.hostService != null) {
      widget.hostService!.onPlayersChanged = (p) {
        if (mounted) setState(() => _allPlayers = p);
      };
      widget.hostService!.onPhaseChanged = _handlePhaseChanged;
      widget.hostService!.onRaceComplete = (players) {
        if (!mounted) return;
        setState(() => _allPlayers = players);
        _markRaceComplete();
      };
    } else if (!widget.isHost && widget.clientService != null) {
      widget.clientService!.onPlayersChanged = (p) {
        if (mounted) setState(() => _allPlayers = p);
      };
      widget.clientService!.onPhaseChanged = _handlePhaseChanged;
      widget.clientService!.onRaceComplete = (players) {
        if (!mounted) return;
        setState(() => _allPlayers = players);
        _markRaceComplete();
      };
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _progressTimer?.cancel();
    _focus.dispose();
    _cleanupNetwork();
    super.dispose();
  }

  Future<void> _cleanupNetwork() async {
    if (_cleanedUp) return;
    _cleanedUp = true;
    if (widget.isHost) {
      await widget.hostService?.dispose();
    } else {
      await widget.clientService?.dispose();
    }
  }

  Future<void> _leaveRace() async {
    await _cleanupNetwork();
    if (mounted) Navigator.pop(context);
  }

  void _handlePhaseChanged(LanRacePhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
    if (phase == LanRacePhase.racing) {
      if (!_stopwatch.isRunning) _stopwatch.start();
    } else if (phase == LanRacePhase.results) {
      _markRaceComplete();
    }
  }

  void _markRaceComplete() {
    if (!mounted) return;
    _stopwatch.stop();
    _uiTimer?.cancel();
    _progressTimer?.cancel();
    setState(() {
      _phase = LanRacePhase.results;
      _allDone = true;
      if (widget.timedMode) _timedEnded = true;
      _finished = true;
    });
  }

  List<LanPlayer> get _sortedPlayers {
    final list = List<LanPlayer>.from(_allPlayers);
    if (widget.timedMode) {
      list.sort((a, b) => b.wordsTyped.compareTo(a.wordsTyped));
    } else if (_allDone) {
      list.sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));
    } else {
      list.sort((a, b) => b.progress.compareTo(a.progress));
    }
    return list;
  }

  // WPM + word count — only recomputed when _currentIndex changes
  void _updateWpm(int elapsedSecs) {
    if (elapsedSecs > 0) {
      _wpm = ((_currentIndex / 5) / (elapsedSecs / 60)).round();
    }
    _wordsTyped = _currentIndex == 0
        ? 0
        : widget.raceText
            .substring(0, _currentIndex)
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
  }

  void _sendProgress({bool force = false}) {
    // Simplified guard: _finished covers all done states
    if (!force && (_finished || _phase != LanRacePhase.racing)) return;
    final progress = widget.raceText.isEmpty
        ? 0.0
        : (_currentIndex / widget.raceText.length).clamp(0.0, 1.0);
    if (widget.isHost) {
      widget.hostService
          ?.updateHostProgress(progress, _wpm, wordsTyped: _wordsTyped);
    } else {
      widget.clientService
          ?.sendProgress(progress, _wpm, wordsTyped: _wordsTyped, force: force);
    }
  }

  void _onTimedEnd() {
    if (_timedEnded) return;
    _stopwatch.stop();
    _uiTimer?.cancel();
    _progressTimer?.cancel();
    _updateWpm(_stopwatch.elapsed.inSeconds);
    _sendProgress(force: true);
    _timedEnded = true;
    _finished = true;
    if (mounted) setState(() {});
  }

  void _onFinish() {
    if (_finished) return;
    _stopwatch.stop();
    _uiTimer?.cancel();
    _progressTimer?.cancel();
    _updateWpm(_stopwatch.elapsed.inSeconds);
    _sendProgress(force: true);
    _finished = true;
    final finishClientTimestampMs = DateTime.now().millisecondsSinceEpoch;
    final finishElapsedMs = _stopwatch.elapsedMilliseconds;
    if (widget.isHost) {
      widget.hostService?.hostFinished(
        finishClientTimestampMs: finishClientTimestampMs,
        finishElapsedMs: finishElapsedMs,
        wpm: _wpm,
        wordsTyped: _wordsTyped,
      );
    } else {
      widget.clientService?.sendFinished(
        finishClientTimestampMs: finishClientTimestampMs,
        finishElapsedMs: finishElapsedMs,
        wpm: _wpm,
        wordsTyped: _wordsTyped,
      );
    }
  }

  // ── Key handler ───────────────────────────────────────────────────────
  void _handleKey(KeyEvent event) {
    if (_finished || _timedEnded || _phase != LanRacePhase.racing) return;
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
      }
      return;
    }

    if (char == null) return;

    final textLen = widget.raceText.length;
    if (_currentIndex >= textLen) {
      if (widget.timedMode) setState(() => _currentIndex = 0);
      return;
    }

    if (char == widget.raceText[_currentIndex]) {
      setState(() {
        _currentIndex++;
        _lastWasWrong = false;
        // WPM is updated lazily in the UI timer, but force a quick update here
        _updateWpm(_stopwatch.elapsed.inSeconds);
        if (!widget.timedMode && _currentIndex >= textLen) _onFinish();
      });
      SoundService().playKeyClick();
    } else {
      setState(() {
        _lastWasWrong = true;
        _errorCount++;
      });
      SoundService().playError();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = widget.raceText.isEmpty
        ? 0.0
        : (_currentIndex / widget.raceText.length).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          KeyboardListener(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _handleKey,
            child: Row(children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBanner(progress),
                      const SizedBox(height: 16),
                      _buildProgressRow(progress),
                      const SizedBox(height: 14),
                      Expanded(child: _buildTextBox()),
                    ],
                  ),
                ),
              ),
              _buildRightPanel(),
            ]),
          ),
          if (_phase == LanRacePhase.countdown && _serverStartAtMs != null)
            _buildCountdownOverlay(),
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final leftMs = (_serverStartAtMs! - nowMs).clamp(0, 60000);
    final leftSecs = (leftMs / 1000).ceil();
    final label = leftSecs > 0 ? '$leftSecs' : 'GO!';

    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.72),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                );
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: curved, child: child),
                );
              },
              child: Column(
                key: ValueKey(label),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTheme.heading(
                      140,
                      color: leftSecs <= 1 ? AppTheme.gold : Colors.white,
                    ).copyWith(fontWeight: FontWeight.w900, height: 0.95),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Get ready',
                    style: AppTheme.body(
                      18,
                      color: Colors.white.withValues(alpha: 0.9),
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(children: [
        const Icon(Icons.lan, color: AppTheme.gold, size: 18),
        const SizedBox(width: 8),
        Text('LAN RACE', style: AppTheme.heading(15, color: AppTheme.gold)),
        const SizedBox(width: 10),
        _ModeBadge(timed: widget.timedMode),
      ]),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(children: [
            _Pill('WPM', '$_wpm', AppTheme.primary),
            const SizedBox(width: 8),
            if (widget.timedMode) ...[
              _Pill(
                _timedEnded ? 'ENDED' : 'LEFT',
                _timedEnded ? '✓' : '${_remainingSecs}s',
                _remainingSecs <= 10 ? AppTheme.error : AppTheme.gold,
              ),
              const SizedBox(width: 8),
              _Pill('WORDS', '$_wordsTyped', AppTheme.success),
            ] else
              _Pill('TIME', '${_elapsedSecs}s', AppTheme.textSecondary),
          ]),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.cardBorder),
      ),
    );
  }

  // ── Status banner ─────────────────────────────────────────────────────
  Widget _buildStatusBanner(double progress) {
    if (_phase == LanRacePhase.countdown && _serverStartAtMs != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final leftMs = (_serverStartAtMs! - nowMs).clamp(0, 60000);
      final leftSecs = (leftMs / 1000).ceil();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.timer_outlined, color: AppTheme.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Race starts in ${leftSecs}s (synchronized)',
              style: AppTheme.heading(15, color: AppTheme.gold),
            ),
          ),
        ]),
      );
    }

    // All done — show winner announcement
    if (_allDone && !widget.timedMode) {
      final sorted = _sortedPlayers;
      final winner = sorted.isNotEmpty ? sorted.first : null;
      final isWinner = winner?.name == widget.playerName;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Text('🏆', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isWinner ? '🎉 You won!' : '${winner?.name ?? "Someone"} won!',
                style: AppTheme.heading(15, color: AppTheme.gold),
              ),
              Text('All players finished — see results on the right',
                  style: AppTheme.body(12, color: AppTheme.textSecondary)),
            ]),
          ),
        ]),
      );
    }

    // Timed ended
    if (_timedEnded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          const Text('⏱', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Time's up!",
                  style: AppTheme.heading(15, color: AppTheme.success)),
              Text('You typed $_wordsTyped words at $_wpm WPM',
                  style: AppTheme.body(12, color: AppTheme.textSecondary)),
            ]),
          ),
        ]),
      );
    }

    // Finished, waiting for others (race mode)
    if (_finished && !widget.timedMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: AppTheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('You finished! $_wpm WPM',
                  style: AppTheme.heading(15, color: AppTheme.primary)),
              Text('Waiting for other players to finish...',
                  style: AppTheme.body(12, color: AppTheme.textSecondary)),
            ]),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.primary),
          ),
        ]),
      );
    }

    // Countdown warning
    if (widget.timedMode && _remainingSecs <= 10) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.alarm, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Text('$_remainingSecs seconds left!',
              style: AppTheme.body(14,
                  color: AppTheme.error, weight: FontWeight.bold)),
        ]),
      );
    }

    return Text(
      widget.timedMode
          ? 'Type as many words as you can! Time: ${_remainingSecs}s'
          : 'Type the text as fast as you can!',
      style: AppTheme.body(14, color: AppTheme.textSecondary),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────
  Widget _buildProgressRow(double progress) {
    final timerProgress =
        (_elapsedSecs / widget.timeLimitSeconds).clamp(0.0, 1.0);
    return Row(children: [
      Text(widget.playerName,
          style: AppTheme.body(13, color: AppTheme.primary)),
      const SizedBox(width: 10),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: widget.timedMode ? timerProgress : progress,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(
                widget.timedMode ? AppTheme.gold : AppTheme.primary),
            minHeight: 8,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        widget.timedMode
            ? '$_wordsTyped words'
            : '${(progress * 100).round()}%',
        style: AppTheme.body(12,
            color: widget.timedMode ? AppTheme.gold : AppTheme.primary),
      ),
    ]);
  }

  // ── Text box ──────────────────────────────────────────────────────────
  Widget _buildTextBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _lastWasWrong
              ? AppTheme.error.withValues(alpha: 0.5)
              : _finished
                  ? AppTheme.success.withValues(alpha: 0.3)
                  : AppTheme.cardBorder,
          width: _lastWasWrong || _finished ? 1.5 : 1,
        ),
      ),
      child: _timedEnded
          ? _buildTimedResults()
          : (_finished && !widget.timedMode)
              ? _buildRaceResults()
              : SingleChildScrollView(child: _buildTextDisplay()),
    );
  }

  Widget _buildTimedResults() {
    final sorted = _sortedPlayers;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('⏱', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 10),
        Text("Time's Up!",
            style: AppTheme.heading(24, color: AppTheme.gold)),
        const SizedBox(height: 6),
        Text('You typed $_wordsTyped words at $_wpm WPM',
            style: AppTheme.body(14, color: AppTheme.textSecondary)),
        if (sorted.length > 1) ...[
          const SizedBox(height: 20),
          Text('FINAL STANDINGS',
              style: AppTheme.body(11, color: AppTheme.textMuted)
                  .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...sorted.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final isMe = p.name == widget.playerName;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isMe
                        ? AppTheme.primary.withValues(alpha: 0.3)
                        : AppTheme.cardBorder),
              ),
              child: Row(children: [
                Text(i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(p.name + (isMe ? ' (You)' : ''),
                      style: AppTheme.body(14,
                          color: isMe
                              ? AppTheme.primary
                              : AppTheme.textPrimary)),
                ),
                Text('${p.wordsTyped} words  •  ${p.wpm} wpm',
                    style: AppTheme.body(12, color: AppTheme.textSecondary)),
              ]),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildRaceResults() {
    if (!_allDone) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🏁', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text('You finished!',
              style: AppTheme.heading(22, color: AppTheme.success)),
          const SizedBox(height: 8),
          Text('$_wpm WPM  •  $_errorCount errors',
              style: AppTheme.body(14, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppTheme.primary),
          ),
          const SizedBox(height: 10),
          Text('Waiting for others to finish...',
              style: AppTheme.body(13, color: AppTheme.textSecondary)),
        ]),
      );
    }

    final sorted = _sortedPlayers;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🏆', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 10),
        Text('Race Complete!',
            style: AppTheme.heading(24, color: AppTheme.gold)),
        const SizedBox(height: 16),
        ...sorted.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          final isMe = p.name == widget.playerName;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: i == 0
                  ? AppTheme.gold.withValues(alpha: 0.1)
                  : isMe
                      ? AppTheme.primary.withValues(alpha: 0.07)
                      : AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: i == 0
                    ? AppTheme.gold.withValues(alpha: 0.4)
                    : isMe
                        ? AppTheme.primary.withValues(alpha: 0.3)
                        : AppTheme.cardBorder,
              ),
            ),
            child: Row(children: [
              Text(i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.name + (isMe ? ' (You)' : ''),
                  style: AppTheme.body(14,
                      color: i == 0
                          ? AppTheme.gold
                          : isMe
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                      weight: i == 0 ? FontWeight.bold : FontWeight.normal),
                ),
              ),
              Text('#${p.rank ?? i + 1}  •  ${p.wpm} wpm',
                  style: AppTheme.body(12,
                      color: i == 0
                          ? AppTheme.gold
                          : AppTheme.textSecondary)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildTextDisplay() {
    final text = widget.raceText;
    // Show a window of characters around the cursor — avoids rebuilding
    // thousands of spans for very long texts
    final start = (_currentIndex - 60).clamp(0, text.length);
    final end = (_currentIndex + 200).clamp(0, text.length);
    final slice = text.substring(start, end);
    final local = _currentIndex - start;

    return RichText(
      text: TextSpan(
        children: List.generate(slice.length, (i) {
          final char = slice[i];
          Color color;
          Color? bg;
          if (i < local) {
            color = AppTheme.success.withValues(alpha: 0.55);
          } else if (i == local) {
            color = _lastWasWrong ? AppTheme.error : AppTheme.textPrimary;
            bg = _lastWasWrong
                ? AppTheme.error.withValues(alpha: 0.2)
                : AppTheme.primary.withValues(alpha: 0.2);
          } else {
            color = AppTheme.textPrimary;
          }
          return WidgetSpan(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 1),
              decoration: bg != null
                  ? BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(3),
                    )
                  : null,
              child: Text(char, style: AppTheme.mono(20, color: color)),
            ),
          );
        }),
      ),
    );
  }

  // ── Right panel (leaderboard) ─────────────────────────────────────────
  Widget _buildRightPanel() {
    final sorted = _sortedPlayers;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(left: BorderSide(color: AppTheme.cardBorder)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(
            'LIVE STANDINGS',
            style: AppTheme.body(10, color: AppTheme.textSecondary)
                .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${sorted.length}',
                style: AppTheme.body(10, color: AppTheme.primary)),
          ),
        ]),
        const SizedBox(height: 12),

        if (sorted.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'Waiting for player\ndata...',
                style: AppTheme.body(12, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final p = sorted[i];
                final isMe = p.name == widget.playerName;
                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isMe
                            ? AppTheme.primary.withValues(alpha: 0.3)
                            : AppTheme.cardBorder),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('${i + 1}.',
                              style: AppTheme.heading(12,
                                  color: i == 0
                                      ? AppTheme.gold
                                      : AppTheme.textSecondary)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              p.name + (isMe ? ' (You)' : ''),
                              style: AppTheme.body(12,
                                  color: isMe
                                      ? AppTheme.primary
                                      : AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            widget.timedMode
                                ? '${p.wordsTyped}w'
                                : '${p.wpm}wpm',
                            style: AppTheme.body(10,
                                color: AppTheme.textSecondary),
                          ),
                        ]),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: widget.timedMode
                                ? (p.wordsTyped / 80).clamp(0.0, 1.0)
                                : p.progress,
                            backgroundColor: AppTheme.cardBorder,
                            valueColor: AlwaysStoppedAnimation(
                              p.finished
                                  ? AppTheme.success
                                  : isMe
                                      ? AppTheme.primary
                                      : AppTheme.gold,
                            ),
                            minHeight: 5,
                          ),
                        ),
                        if (p.finished && !widget.timedMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(children: [
                              const Icon(Icons.flag,
                                  color: AppTheme.success, size: 11),
                              const SizedBox(width: 4),
                              Text('Finished! #${p.rank ?? '?'}',
                                  style: AppTheme.body(10,
                                      color: AppTheme.success)),
                            ]),
                          ),
                        if (p.dnf || p.disconnected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(children: [
                              const Icon(Icons.link_off,
                                  color: AppTheme.error, size: 11),
                              const SizedBox(width: 4),
                              Text('Disconnected / DNF',
                                  style: AppTheme.body(10,
                                      color: AppTheme.error)),
                            ]),
                          ),
                      ]),
                );
              },
            ),
          ),

        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            onPressed: _leaveRace,
            child: Text('Leave Race', style: AppTheme.body(13)),
          ),
        ),
      ]),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Pill(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text('$label: $value', style: AppTheme.body(11, color: color)),
      );
}

class _ModeBadge extends StatelessWidget {
  final bool timed;
  const _ModeBadge({required this.timed});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: timed
              ? AppTheme.gold.withValues(alpha: 0.15)
              : AppTheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            timed ? Icons.timer_rounded : Icons.flag_rounded,
            color: timed ? AppTheme.gold : AppTheme.primary,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            timed ? 'TIMED' : 'RACE',
            style: AppTheme.body(10,
                color: timed ? AppTheme.gold : AppTheme.primary,
                weight: FontWeight.bold),
          ),
        ]),
      );
}