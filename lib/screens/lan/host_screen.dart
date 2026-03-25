import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../services/lan_service.dart';
import 'race_screen.dart';

const List<String> _kPresets = [
  'The quick brown fox jumps over the lazy dog near the old farm.',
  'Learning to type fast is a skill that helps you in school and work.',
  'Nepal is a beautiful country with high mountains and amazing people.',
  'Computers have changed the way students learn and teachers teach.',
  'Practice every day and you will become better than you were before.',
  'The keyboard is your friend. Learn every key and you will fly.',
  'Success comes to those who work hard and never give up on their goals.',
  'Technology connects people from all parts of the world together.',
  'Every great typist started as a beginner just like you right now.',
  'The mountains of Nepal stand tall just like students who work hard.',
];

// For timed mode — a long text that repeats so players never run out
const String _kTimedText =
    'the quick brown fox jumps over the lazy dog '
    'a good typist practices every single day and never gives up '
    'nepal is a beautiful country with mountains and rivers '
    'computers help students learn many new things every day '
    'hard work and practice make you the best typist in class '
    'keep your eyes on the screen and fingers on the home row keys '
    'the quick brown fox jumps over the lazy dog '
    'learning to type without looking is called touch typing '
    'every key on the keyboard has its own correct finger '
    'speed and accuracy both improve with daily practice sessions '
    'the quick brown fox jumps over the lazy dog again and again ';

enum _RaceMode { race, timed }

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  final LanHostService _host = LanHostService();
  final TextEditingController _nameCtrl = TextEditingController(text: 'Host');
  final TextEditingController _customCtrl = TextEditingController();

  List<LanPlayer> _players = [];
  String? _hostIp;
  bool _starting = false, _hosting = false;
  bool _inRace = false;

  _RaceMode _mode = _RaceMode.race;
  bool _useCustomText = false;
  int _selectedPreset = 0;
  int _timeLimitSecs = 60;

  @override
  void initState() {
    super.initState();
    _customCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (!_inRace) _host.dispose();
    _nameCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  String get _effectiveText {
    if (_mode == _RaceMode.timed) return _kTimedText * 5;
    return _useCustomText ? _customCtrl.text.trim() : _kPresets[_selectedPreset];
  }

  bool get _canStart {
    if (_mode == _RaceMode.race && _useCustomText) {
      return _customCtrl.text.trim().length >= 10;
    }
    return true;
  }

  Future<void> _startHosting() async {
    final name = _nameCtrl.text.trim().isEmpty ? 'Host' : _nameCtrl.text.trim();
    setState(() => _hosting = true);

    final ip = await _host.startHosting(name);
    if (ip == null) {
      setState(() => _hosting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to start hosting. Check your network.'),
          backgroundColor: AppTheme.error,
        ));
      }
      return;
    }

    _host.onPlayersChanged = (players) {
      if (mounted) setState(() => _players = players);
    };
    setState(() {
      _hostIp = ip;
      _players = _host.players.values.toList();
    });
  }

  void _startRace() {
    if (!_canStart) return;
    setState(() => _starting = true);

    final text = _effectiveText;
    final started = _host.startRace(
      text,
      timedMode: _mode == _RaceMode.timed,
      timeLimitSecs: _timeLimitSecs,
    );
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Race is already in progress.'),
          backgroundColor: AppTheme.error,
        ));
      }
      setState(() => _starting = false);
      return;
    }

    _inRace = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RaceScreen(
          isHost: true,
          hostService: _host,
          playerName: _nameCtrl.text.trim().isEmpty
              ? 'Host'
              : _nameCtrl.text.trim(),
          raceText: text,
          timedMode: _mode == _RaceMode.timed,
          timeLimitSeconds: _timeLimitSecs,
          startAtMs: _host.startAtMs,
          initialPlayers: _players,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text('HOST GAME',
            style: AppTheme.heading(16, color: AppTheme.gold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _hostIp == null ? _buildSetup() : _buildWaitingRoom(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SETUP PANEL
  // ════════════════════════════════════════════════════════════════
  Widget _buildSetup() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set Up Room',
                  style: AppTheme.heading(24, color: AppTheme.gold)),
              const SizedBox(height: 4),
              Text('Choose your mode, text, and start hosting.',
                  style: AppTheme.body(14, color: AppTheme.textSecondary)),
              const SizedBox(height: 28),

              // ── Name ──────────────────────────────────────────────────
              const _Label('YOUR NAME'),
              const SizedBox(height: 8),
              // textCapitalization removed — keyboard-only desktop app
              TextField(
                controller: _nameCtrl,
                style: AppTheme.body(16),
                decoration: const InputDecoration(hintText: 'Enter your name'),
              ),
              const SizedBox(height: 24),

              // ── Mode Toggle ───────────────────────────────────────────
              const _Label('RACE MODE'),
              const SizedBox(height: 10),
              Row(children: [
                _ModeChip(
                  icon: Icons.flag_rounded,
                  label: 'Finish Race',
                  sub: 'Type full text first',
                  selected: _mode == _RaceMode.race,
                  color: AppTheme.primary,
                  onTap: () => setState(() => _mode = _RaceMode.race),
                ),
                const SizedBox(width: 12),
                _ModeChip(
                  icon: Icons.timer_rounded,
                  label: 'Timed Battle',
                  sub: 'Most words in time limit',
                  selected: _mode == _RaceMode.timed,
                  color: AppTheme.gold,
                  onTap: () => setState(() => _mode = _RaceMode.timed),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Race mode: text selection ─────────────────────────────
              if (_mode == _RaceMode.race) ...[
                const _Label('RACE TEXT'),
                const SizedBox(height: 10),
                Row(children: [
                  _TabBtn(
                    label: 'Preset Texts',
                    active: !_useCustomText,
                    onTap: () => setState(() => _useCustomText = false),
                  ),
                  const SizedBox(width: 8),
                  _TabBtn(
                    label: 'Custom Text',
                    active: _useCustomText,
                    onTap: () => setState(() => _useCustomText = true),
                  ),
                ]),
                const SizedBox(height: 12),

                if (!_useCustomText) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(children: [
                      Text(_kPresets[_selectedPreset],
                          style: AppTheme.mono(14)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Text ${_selectedPreset + 1} / ${_kPresets.length}',
                            style: AppTheme.body(12,
                                color: AppTheme.textSecondary),
                          ),
                          Row(children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left,
                                  color: AppTheme.textSecondary),
                              onPressed: _selectedPreset > 0
                                  ? () => setState(() => _selectedPreset--)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondary),
                              onPressed: _selectedPreset < _kPresets.length - 1
                                  ? () => setState(() => _selectedPreset++)
                                  : null,
                            ),
                          ]),
                        ],
                      ),
                    ]),
                  ),
                ] else ...[
                  TextField(
                    controller: _customCtrl,
                    style: AppTheme.mono(14),
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText:
                          'Type or paste your custom race text here...\n(minimum 10 characters)',
                      hintStyle: AppTheme.body(13, color: AppTheme.textMuted),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _customCtrl.text.trim().length < 10
                            ? 'Minimum 10 characters required'
                            : '${_customCtrl.text.trim().split(' ').length} words  •  ${_customCtrl.text.trim().length} chars',
                        style: AppTheme.body(11,
                            color: _customCtrl.text.trim().length < 10
                                ? AppTheme.error
                                : AppTheme.success),
                      ),
                      TextButton(
                        onPressed: () => _customCtrl.clear(),
                        child: Text('Clear',
                            style: AppTheme.body(11,
                                color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ],

              // ── Timed mode: time picker ───────────────────────────────
              if (_mode == _RaceMode.timed) ...[
                const _Label('TIME LIMIT'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [30, 60, 90, 120, 180].map((secs) {
                    final sel = _timeLimitSecs == secs;
                    final label =
                        secs < 60 ? '${secs}s' : '${secs ~/ 60}min';
                    return GestureDetector(
                      onTap: () => setState(() => _timeLimitSecs = secs),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.gold.withValues(alpha: 0.15)
                              : AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? AppTheme.gold : AppTheme.cardBorder,
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          label,
                          style: AppTheme.body(15,
                              color: sel
                                  ? AppTheme.gold
                                  : AppTheme.textSecondary,
                              weight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.gold, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Everyone types the same text for $_timeLimitSecs seconds. '
                        'Most words typed wins!',
                        style:
                            AppTheme.body(12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.dns_outlined),
                  label: Text(
                    _hosting ? 'Starting...' : 'START HOSTING',
                    style: AppTheme.heading(14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: AppTheme.cardBorder,
                  ),
                  onPressed: (_hosting || !_canStart) ? null : _startHosting,
                ),
              ),
              if (_mode == _RaceMode.race && _useCustomText && !_canStart)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Enter at least 10 characters to continue',
                      style: AppTheme.body(12, color: AppTheme.error),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WAITING ROOM
  // ════════════════════════════════════════════════════════════════
  Widget _buildWaitingRoom() {
    return Row(children: [
      Expanded(
        flex: 2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Waiting Room',
              style: AppTheme.heading(24, color: AppTheme.gold)),
          const SizedBox(height: 6),
          Text('Share your IP with classmates.',
              style: AppTheme.body(14, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),

          // IP
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
            ),
            child: Row(children: [
              const Icon(Icons.wifi, color: AppTheme.gold, size: 26),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('YOUR IP ADDRESS',
                    style: AppTheme.body(10, color: AppTheme.textSecondary)
                        .copyWith(letterSpacing: 1)),
                Text(_hostIp!,
                    style: AppTheme.heading(26, color: AppTheme.gold)),
                Text('Port: 8765',
                    style:
                        AppTheme.body(11, color: AppTheme.textSecondary)),
              ]),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, color: AppTheme.gold),
                tooltip: 'Copy IP',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _hostIp!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('IP copied!'),
                    duration: Duration(seconds: 1),
                  ));
                },
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Mode summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                      _mode == _RaceMode.timed
                          ? Icons.timer_rounded
                          : Icons.flag_rounded,
                      color: _mode == _RaceMode.timed
                          ? AppTheme.gold
                          : AppTheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _mode == _RaceMode.timed
                          ? 'TIMED BATTLE  •  ${_timeLimitSecs < 60 ? "${_timeLimitSecs}s" : "${_timeLimitSecs ~/ 60}min"}'
                          : 'FINISH RACE',
                      style: AppTheme.body(11,
                              color: _mode == _RaceMode.timed
                                  ? AppTheme.gold
                                  : AppTheme.primary)
                          .copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold),
                    ),
                  ]),
                  if (_mode == _RaceMode.race) ...[
                    const SizedBox(height: 8),
                    Text(_effectiveText,
                        style: AppTheme.mono(12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      'Most words typed in $_timeLimitSecs seconds wins',
                      style:
                          AppTheme.body(12, color: AppTheme.textSecondary),
                    ),
                  ],
                ]),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                _players.length < 2
                    ? 'Waiting for players...'
                    : 'START RACE',
                style: AppTheme.heading(16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _players.length >= 2
                    ? AppTheme.gold
                    : AppTheme.textMuted,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed:
                  (_players.length >= 2 && !_starting) ? _startRace : null,
            ),
          ),
          if (_players.length < 2) ...[
            const SizedBox(height: 8),
            Center(
              child: Text('Need at least 2 players to start',
                  style: AppTheme.body(12, color: AppTheme.textSecondary)),
            ),
          ],
        ]),
      ),

      const SizedBox(width: 24),

      // Players list
      Expanded(
        flex: 1,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('PLAYERS',
                style: AppTheme.body(12, color: AppTheme.textSecondary)
                    .copyWith(letterSpacing: 2)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${_players.length}',
                  style: AppTheme.body(12, color: AppTheme.primary)),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _players.length,
              itemBuilder: (_, i) {
                final p = _players[i];
                final isHost = p.id == 'host';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isHost
                        ? AppTheme.gold.withValues(alpha: 0.1)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isHost
                            ? AppTheme.gold.withValues(alpha: 0.3)
                            : AppTheme.cardBorder),
                  ),
                  child: Row(children: [
                    Icon(
                      isHost ? Icons.stars_rounded : Icons.person,
                      color: isHost ? AppTheme.gold : AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.name, style: AppTheme.body(14))),
                    if (isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('HOST',
                            style:
                                AppTheme.body(10, color: AppTheme.gold)),
                      ),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTheme.body(11, color: AppTheme.textSecondary)
            .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
      );
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn(
      {required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryLight : AppTheme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppTheme.primary : AppTheme.cardBorder,
              width: active ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.body(13,
                color: active ? AppTheme.primary : AppTheme.textSecondary,
                weight: active ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      );
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.sub,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : AppTheme.cardBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(children: [
              Icon(icon,
                  color: selected ? color : AppTheme.textMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTheme.body(14,
                            color: selected
                                ? color
                                : AppTheme.textPrimary,
                            weight: FontWeight.bold),
                      ),
                      Text(sub,
                          style: AppTheme.body(11,
                              color: AppTheme.textSecondary)),
                    ]),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: color, size: 18),
            ]),
          ),
        ),
      );
}