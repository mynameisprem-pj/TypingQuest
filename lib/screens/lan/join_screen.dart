import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../services/lan_service.dart';
import 'race_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final LanClientService _client = LanClientService();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<LanPlayer> _players = [];
  bool _connecting = false;
  bool _connected = false;
  bool _waiting = false;

  @override
  void dispose() {
    if (!_waiting) _client.dispose();
    _ipController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final name = _nameController.text.trim().isEmpty ? 'Player' : _nameController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the host IP address'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _connecting = true);

    _client.onPlayersChanged = (players) {
      if (mounted) setState(() => _players = players);
    };

    _client.onGameStart = (text, timedMode, timeLimitSeconds, startAtMs) {
      if (mounted) {
        setState(() => _waiting = true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RaceScreen(
              isHost: false,
              clientService: _client,
              playerName: name,
              raceText: text,
              timedMode: timedMode,
              timeLimitSeconds: timeLimitSeconds,
              startAtMs: startAtMs,
              initialPlayers: _players,
            ),
          ),
        );
      }
    };

    _client.onError = (err) {
      if (mounted) {
        setState(() { _connecting = false; _connected = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppTheme.error),
        );
      }
    };

    final success = await _client.connect(ip, name);
    setState(() {
      _connecting = false;
      _connected = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text('JOIN GAME', style: AppTheme.heading(16, color: AppTheme.primary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(32),
          child: _connected ? _buildWaitingPanel() : _buildJoinPanel(),
        ),
      ),
    );
  }

  Widget _buildJoinPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.wifi, color: AppTheme.primary, size: 48),
        const SizedBox(height: 20),
        Text('Join a Race', style: AppTheme.heading(28)),
        const SizedBox(height: 8),
        Text('Ask the host for their IP address and enter it below.', style: AppTheme.body(14, color: AppTheme.textSecondary)),
        const SizedBox(height: 32),

        Text('YOUR NAME', style: AppTheme.body(12, color: AppTheme.textSecondary).copyWith(letterSpacing: 2)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: AppTheme.body(16),
          decoration: const InputDecoration(hintText: 'Enter your name'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),

        Text('HOST IP ADDRESS', style: AppTheme.body(12, color: AppTheme.textSecondary).copyWith(letterSpacing: 2)),
        const SizedBox(height: 8),
        TextField(
          controller: _ipController,
          style: AppTheme.mono(18),
          decoration: const InputDecoration(hintText: 'e.g. 192.168.1.5'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _connecting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.background, strokeWidth: 2))
                : const Icon(Icons.login),
            label: Text(_connecting ? 'Connecting...' : 'CONNECT & JOIN', style: AppTheme.heading(14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _connecting ? null : _connect,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 60),
        const SizedBox(height: 16),
        Text('Connected!', style: AppTheme.heading(28, color: AppTheme.success)),
        const SizedBox(height: 8),
        Text('Waiting for the host to start the race...', style: AppTheme.body(15, color: AppTheme.textSecondary)),
        const SizedBox(height: 32),

        // Players in lobby
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLAYERS IN LOBBY', style: AppTheme.body(12, color: AppTheme.textSecondary).copyWith(letterSpacing: 2)),
              const SizedBox(height: 12),
              ..._players.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      p.id == 'host' ? Icons.stars_rounded : Icons.person,
                      color: p.id == 'host' ? AppTheme.gold : AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(p.name, style: AppTheme.body(14)),
                    if (p.id == 'host') ...[
                      const SizedBox(width: 8),
                      Text('(Host)', style: AppTheme.body(12, color: AppTheme.gold)),
                    ],
                  ],
                ),
              )),
              if (_players.isEmpty)
                Text('Loading players...', style: AppTheme.body(13, color: AppTheme.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Animated dots
        _AnimatedWaiting(),
      ],
    );
  }
}

class _AnimatedWaiting extends StatefulWidget {
  @override
  State<_AnimatedWaiting> createState() => _AnimatedWaitingState();
}

class _AnimatedWaitingState extends State<_AnimatedWaiting> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _dot = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..addListener(() {
        if (_ctrl.status == AnimationStatus.completed) {
          setState(() => _dot = (_dot + 1) % 3);
          _ctrl.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Waiting for host', style: AppTheme.body(14, color: AppTheme.textSecondary)),
        const SizedBox(width: 4),
        Row(children: List.generate(3, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == _dot ? AppTheme.primary : AppTheme.textMuted,
          ),
        ))),
      ],
    );
  }
}
