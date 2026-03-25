import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_theme.dart';
import 'host_screen.dart';
import 'join_screen.dart';

class LanMenuScreen extends StatelessWidget {
  const LanMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text('LAN RACE', style: AppTheme.heading(16, color: AppTheme.gold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),
      body: Stack(
        children: [
          // Static background — shouldRepaint returns false, painted once
          SizedBox.expand(child: CustomPaint(painter: _LanBgPainter())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 64,
                    ),
                    child: Center(
                      child: kIsWeb
                          ? _buildWebWarning(context)
                          : _buildDesktopMenu(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMenu(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.gold.withValues(alpha: 0.1),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4), width: 1.5),
          ),
          child: const Icon(Icons.lan, color: AppTheme.gold, size: 40),
        ),
        const SizedBox(height: 20),
        Text('LAN RACE MODE', style: AppTheme.heading(28, color: AppTheme.gold)),
        const SizedBox(height: 12),
        Text(
          'Connect your computers on the same school network.\nNo internet required — just your school\'s WiFi or LAN cable.',
          style: AppTheme.body(15, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOW IT WORKS',
                style: AppTheme.body(12, color: AppTheme.textSecondary)
                    .copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 14),
              const _HowToStep(number: '1', text: 'One student clicks HOST and shares their IP address with classmates'),
              const _HowToStep(number: '2', text: 'Other students click JOIN and enter the host\'s IP address'),
              const _HowToStep(number: '3', text: 'When everyone is ready, the host clicks START RACE'),
              const _HowToStep(number: '4', text: 'Everyone types the same text — watch live progress bars!'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LanActionButton(
              icon: Icons.dns_outlined,
              label: 'HOST GAME',
              subtitle: 'Create a room for your class',
              color: AppTheme.gold,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HostScreen()),
              ),
            ),
            const SizedBox(width: 20),
            _LanActionButton(
              icon: Icons.wifi_outlined,
              label: 'JOIN GAME',
              subtitle: 'Enter the host\'s IP address',
              color: AppTheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebWarning(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.info_outline, color: AppTheme.gold, size: 60),
        const SizedBox(height: 20),
        Text('LAN Race Requires Windows App',
            style: AppTheme.heading(22, color: AppTheme.gold)),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
          ),
          child: Text(
            'The LAN race feature uses direct socket connections between computers, which is only available in the Windows desktop app.\n\nPlease use the Windows version of TypingQuest for LAN multiplayer.',
            style: AppTheme.body(15, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _HowToStep extends StatelessWidget {
  final String number;
  final String text;
  const _HowToStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(number, style: AppTheme.body(12, color: AppTheme.gold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTheme.body(14, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _LanActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _LanActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_LanActionButton> createState() => _LanActionButtonState();
}

class _LanActionButtonState extends State<_LanActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.1) : AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered ? widget.color : AppTheme.cardBorder,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: widget.color.withValues(alpha: 0.25), blurRadius: 20)]
                : null,
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: widget.color, size: 40),
              const SizedBox(height: 12),
              Text(widget.label, style: AppTheme.heading(15, color: widget.color)),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: AppTheme.body(12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}