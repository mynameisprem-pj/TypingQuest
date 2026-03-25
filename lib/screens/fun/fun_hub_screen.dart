import 'package:flutter/material.dart';
import 'space_shooter_game.dart';
import 'zombie_survival_game.dart';
import 'typing_knight_game.dart';

class FunHubScreen extends StatelessWidget {
  const FunHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08070F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF7B5EA7).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF7B5EA7).withValues(alpha: 0.40),
                ),
              ),
              child: const Text('🎮', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            const Text(
              'GAME HUB',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white10),
        ),
      ),
      body: CustomPaint(
        painter: _HubBgPainter(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderBanner(),
              const SizedBox(height: 32),

              const _SectionLabel(
                label: 'AVAILABLE NOW',
                accent: Color(0xFF7B5EA7),
                count: 3,
              ),
              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (_, box) {
                  final cols =
                      box.maxWidth > 700
                          ? 3
                          : box.maxWidth > 460
                          ? 2
                          : 1;
                  final w = (box.maxWidth - (cols - 1) * 12) / cols;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _GameCard(
                        icon: '🚀',
                        title: 'Space Shooter',
                        desc:
                            'Destroy alien invaders by typing words. Chain kills for combo multipliers and survive epic boss waves.',
                        tags: const [
                          'Speed',
                          'Short words',
                          'Combo system',
                          'Boss waves',
                        ],
                        accentColor: const Color(0xFF00E5FF),
                        width: w,
                        onPlay: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SpaceShooterGame(),
                          ),
                        ),
                      ),
                      _GameCard(
                        icon: '🧟',
                        title: 'Zombie Survival',
                        desc:
                            'Defend your base against endless zombie hordes. Unlock FREEZE and BOMB power-ups to survive.',
                        tags: const [
                          'Waves',
                          'Power-ups',
                          'Base defense',
                          'Combo',
                        ],
                        accentColor: const Color(0xFF76FF03),
                        width: w,
                        onPlay: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ZombieSurvivalGame(),
                          ),
                        ),
                      ),
                      _GameCard(
                        icon: '⚔️',
                        title: 'Typing Knight',
                        desc:
                            "You are the last knight! Slash enemies, deflect fireballs, and fight the Dragon boss. Protect your castle!",
                        tags: const [
                          'Enemies',
                          'Dragon Boss',
                          'Fireballs',
                          'Castle HP',
                        ],
                        accentColor: const Color(0xFFFFD700),
                        width: w,
                        onPlay: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TypingKnightGame(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 36),

              const _SectionLabel(
                label: 'COMING SOON',
                accent: Colors.white30,
                count: 5,
              ),
              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (_, box) {
                  final cols =
                      box.maxWidth > 700
                          ? 3
                          : box.maxWidth > 460
                          ? 2
                          : 1;
                  final w = (box.maxWidth - (cols - 1) * 12) / cols;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ComingSoonCard(
                        icon: '🥷',
                        title: 'Ninja Fruit',
                        desc:
                            'Slice fruits by typing their letters. Beware the bombs!',
                        color: const Color(0xFFEF5350),
                        width: w,
                      ),
                      _ComingSoonCard(
                        icon: '🏎️',
                        title: 'Car Race',
                        desc:
                            'Type words to accelerate and beat AI opponents on the track!',
                        color: const Color(0xFFFFD700),
                        width: w,
                      ),
                      _ComingSoonCard(
                        icon: '🐟',
                        title: 'Deep Sea Diver',
                        desc:
                            'Dive deep, collect treasures, type to scare away sharks!',
                        color: const Color(0xFF00B4D8),
                        width: w,
                      ),
                      _ComingSoonCard(
                        icon: '🌊',
                        title: 'Word Tsunami',
                        desc:
                            'Words come in waves — type fast or get swept away!',
                        color: const Color(0xFF4FC3F7),
                        width: w,
                      ),
                      _ComingSoonCard(
                        icon: '🧩',
                        title: 'Code Breaker',
                        desc:
                            'Crack codes by typing sequences. Trains accuracy and focus.',
                        color: const Color(0xFFFF8A65),
                        width: w,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background painter ────────────────────────────────────────────────────────
// Flat fill + sparse static grid — drawn once, never redrawn.
class _HubBgPainter extends CustomPainter {
  static final Paint _bgPaint = Paint()..color = const Color(0xFF08070F);
  static final Paint _gridPaint = Paint()
    ..color = const Color(0x06FFFFFF)
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _bgPaint,
    );
    // Sparse grid — fewer draw calls than the original 56-px spacing
    const spacing = 80.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Header banner ─────────────────────────────────────────────────────────────
class _HeaderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Play games. Learn typing. Have fun!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _TagChip('⌨  Improve speed'),
              SizedBox(width: 8),
              _TagChip('🎯  Build accuracy'),
              SizedBox(width: 8),
              _TagChip('🏆  Beat high scores'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color accent;
  final int count;
  const _SectionLabel({
    required this.label,
    required this.accent,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: accent.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

// ── Game card (available) ─────────────────────────────────────────────────────
// StatelessWidget — matches the coming-soon card style; no hover, no animation.
class _GameCard extends StatelessWidget {
  final String icon, title, desc;
  final List<String> tags;
  final Color accentColor;
  final double width;
  final VoidCallback onPlay;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.tags,
    required this.accentColor,
    required this.width,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF100F1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon row + PLAY badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const Spacer(),
              _PlayBadge(accentColor: accentColor, onTap: onPlay),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          // Description
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          // Tags
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: accentColor.withValues(alpha: 0.80),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Play badge ────────────────────────────────────────────────────────────────
// Lightweight tap-only button — no AnimatedContainer, no box shadow.
class _PlayBadge extends StatefulWidget {
  final Color accentColor;
  final VoidCallback onTap;
  const _PlayBadge({required this.accentColor, required this.onTap});

  @override
  State<_PlayBadge> createState() => _PlayBadgeState();
}

class _PlayBadgeState extends State<_PlayBadge> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.accentColor.withValues(alpha: 0.22)
              : widget.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.accentColor.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: widget.accentColor,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              'PLAY',
              style: TextStyle(
                color: widget.accentColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coming soon card ──────────────────────────────────────────────────────────
// StatelessWidget — no hover state, no animation overhead.
class _ComingSoonCard extends StatelessWidget {
  final String icon, title, desc;
  final Color color;
  final double width;
  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF100F1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'SOON',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.60),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
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
    child: Text(
      text,
      style: const TextStyle(color: Colors.white54, fontSize: 11),
    ),
  );
}