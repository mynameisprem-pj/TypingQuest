import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'space_shooter_game.dart';
import 'zombie_survival_game.dart';

class FunHubScreen extends StatelessWidget {
  const FunHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          const Text('🎮', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text('LEARN WITH FUN', style: AppTheme.heading(18, color: Colors.white)
              .copyWith(letterSpacing: 3)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white12),
        ),
      ),
      body: CustomPaint(
        painter: _HubBackgroundPainter(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Subtitle
            Text('Play games. Learn typing. Have fun!',
                style: AppTheme.body(14, color: Colors.white54)),
            const SizedBox(height: 8),
            Row(children: [
              _TagChip('⌨  Improve speed'),
              const SizedBox(width: 8),
              _TagChip('🎯  Build accuracy'),
              const SizedBox(width: 8),
              _TagChip('🏆  Beat high scores'),
            ]),
            const SizedBox(height: 32),

            Text('AVAILABLE NOW',
                style: AppTheme.body(11, color: Colors.white38).copyWith(letterSpacing: 3)),
            const SizedBox(height: 14),

            // Space Shooter card — AVAILABLE
            _GameCard(
              title: 'Space Shooter',
              subtitle: 'Destroy alien invaders by typing words',
              icon: '🚀',
              description:
                  'Aliens are invading Earth! Each alien carries a word — '
                  'type it to fire your laser and destroy them before they '
                  'reach the ground. Chain kills for combo multipliers and '
                  'defeat epic boss waves every 10 kills!',
              tags: ['Speed', 'Short words', 'Combo system', 'Boss waves'],
              gradient: const [Color(0xFF0D1B4B), Color(0xFF1A0A3A)],
              accentColor: const Color(0xFF00FFFF),
              available: true,
              onPlay: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SpaceShooterGame())),
            ),

            const SizedBox(height: 24),

            // Zombie Survival — AVAILABLE
            _GameCard(
              title: 'Zombie Survival',
              subtitle: 'Defend your base against endless zombie hordes',
              icon: '🧟',
              description:
                  'Zombies shamble toward your base from the right — type their word to '
                  'shoot them before they break through! Survive endless waves, unlock '
                  'power-ups like FREEZE and BOMB, and keep your base alive!',
              tags: ['Waves', 'Power-ups', 'Base defense', 'Combo system'],
              gradient: const [Color(0xFF0A1F08), Color(0xFF152A0E)],
              accentColor: const Color(0xFFAAFF66),
              available: true,
              onPlay: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ZombieSurvivalGame())),
            ),

            const SizedBox(height: 32),

            Text('COMING SOON',
                style: AppTheme.body(11, color: Colors.white38).copyWith(letterSpacing: 3)),
            const SizedBox(height: 14),

            // Coming soon games grid
            LayoutBuilder(builder: (ctx, box) {
              final crossCount = box.maxWidth > 700 ? 3 : box.maxWidth > 480 ? 2 : 1;
              return Wrap(
                spacing: 16, runSpacing: 16,
                children: [
                  _ComingSoonCard(
                    icon: '🏎️',
                    title: 'Car Race',
                    desc: 'Type words to accelerate your car and beat AI opponents on the track!',
                    color: const Color(0xFFFFD700),
                    width: _cardWidth(box.maxWidth, crossCount),
                  ),
                  _ComingSoonCard(
                    icon: '🐟',
                    title: 'Deep Sea Diver',
                    desc: 'Dive deep, collect treasures, and type words to scare away sharks!',
                    color: const Color(0xFF00B4D8),
                    width: _cardWidth(box.maxWidth, crossCount),
                  ),
                  _ComingSoonCard(
                    icon: '⚔️',
                    title: 'Typing Knight',
                    desc: 'RPG battle! Type words to attack and defend against monsters.',
                    color: const Color(0xFFB197FC),
                    width: _cardWidth(box.maxWidth, crossCount),
                  ),
                  _ComingSoonCard(
                    icon: '🌊',
                    title: 'Word Tsunami',
                    desc: 'Words come in waves — type fast or get swept away by the flood!',
                    color: const Color(0xFF4FC3F7),
                    width: _cardWidth(box.maxWidth, crossCount),
                  ),
                  _ComingSoonCard(
                    icon: '🧩',
                    title: 'Code Breaker',
                    desc: 'Crack codes by typing sequences. Trains accuracy and focus.',
                    color: const Color(0xFFFF8A65),
                    width: _cardWidth(box.maxWidth, crossCount),
                  ),
                ],
              );
            }),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  double _cardWidth(double total, int cols) =>
      (total - (cols - 1) * 16) / cols;
}

// ── Animated dark space background ───────────────────────────────────────────
class _HubBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF060B1A), Color(0xFF0A0F2A), Color(0xFF060B1A)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);

    // Subtle grid lines
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ── Tag chip ──────────────────────────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final String text;
  const _TagChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white12),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
  );
}

// ── Big game card ─────────────────────────────────────────────────────────────
class _GameCard extends StatefulWidget {
  final String title, subtitle, icon, description;
  final List<String> tags;
  final List<Color> gradient;
  final Color accentColor;
  final bool available;
  final VoidCallback? onPlay;

  const _GameCard({
    required this.title, required this.subtitle, required this.icon,
    required this.description, required this.tags, required this.gradient,
    required this.accentColor, required this.available, this.onPlay,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: widget.gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? widget.accentColor.withValues(alpha: 0.7)
                : widget.accentColor.withValues(alpha: 0.25),
            width: _hovered ? 2 : 1.5,
          ),
          boxShadow: _hovered ? [
            BoxShadow(color: widget.accentColor.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 2),
          ] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Left: info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(widget.icon, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: TextStyle(
                    color: widget.accentColor, fontSize: 22, fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: [Shadow(color: widget.accentColor.withValues(alpha: 0.5), blurRadius: 10)],
                  )),
                  Text(widget.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              Text(widget.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 6,
                children: widget.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(t, style: TextStyle(
                      color: widget.accentColor.withValues(alpha: 0.9), fontSize: 11)),
                )).toList(),
              ),
            ])),

            const SizedBox(width: 28),

            // Right: play button
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 20),
              _PlayBtn(
                label: '▶  PLAY',
                color: widget.accentColor,
                onTap: widget.onPlay ?? () {},
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.4)),
                ),
                child: const Text('AVAILABLE',
                    style: TextStyle(color: Color(0xFF00FF88), fontSize: 10,
                        fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Coming soon card ──────────────────────────────────────────────────────────
class _ComingSoonCard extends StatefulWidget {
  final String icon, title, desc;
  final Color color;
  final double width;
  const _ComingSoonCard({required this.icon, required this.title,
      required this.desc, required this.color, required this.width});
  @override
  State<_ComingSoonCard> createState() => _ComingSoonCardState();
}

class _ComingSoonCardState extends State<_ComingSoonCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: widget.width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(widget.icon, style: TextStyle(
                fontSize: 28, color: Colors.white.withValues(alpha: 0.5))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text('SOON', style: TextStyle(
                  color: Colors.white30, fontSize: 9, letterSpacing: 2)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(widget.title, style: TextStyle(
            color: _hovered ? widget.color : Colors.white54,
            fontSize: 15, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 6),
          Text(widget.desc, style: const TextStyle(
              color: Colors.white30, fontSize: 12, height: 1.5)),
        ]),
      ),
    );
  }
}

// ── Play button ───────────────────────────────────────────────────────────────
class _PlayBtn extends StatefulWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _PlayBtn({required this.label, required this.color, required this.onTap});
  @override
  State<_PlayBtn> createState() => _PlayBtnState();
}

class _PlayBtnState extends State<_PlayBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp:   (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: Matrix4.diagonal3Values(
  _pressed ? 0.95 : 1.0, // X
  _pressed ? 0.95 : 1.0, // Y
  1.0,                   // Z (keep depth at 1.0)
),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: _pressed ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color, width: 2),
        boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.3), blurRadius: 16)],
      ),
      child: Text(widget.label, style: TextStyle(
        color: widget.color, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2,
        shadows: [Shadow(color: widget.color.withValues(alpha: 0.8), blurRadius: 8)],
      )),
    ),
  );
}