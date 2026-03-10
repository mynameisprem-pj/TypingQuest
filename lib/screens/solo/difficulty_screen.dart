import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../services/progress_service.dart';
import 'level_select_screen.dart';

class DifficultyScreen extends StatelessWidget {
  final String? initialDifficulty;
  const DifficultyScreen({super.key, this.initialDifficulty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text('SOLO PRACTICE', style: AppTheme.heading(16)),
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
          SizedBox.expand(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose Your Level', style: AppTheme.heading(28)),
                  const SizedBox(height: 8),
                  Text(
                    'Each difficulty has 100 levels. Progress saves automatically.',
                    style: AppTheme.body(15, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _DifficultyCard(difficulty: Difficulty.beginner)),
                        const SizedBox(width: 16),
                        Expanded(child: _DifficultyCard(difficulty: Difficulty.intermediate)),
                        const SizedBox(width: 16),
                        Expanded(child: _DifficultyCard(difficulty: Difficulty.master)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatefulWidget {
  final Difficulty difficulty;
  const _DifficultyCard({required this.difficulty});

  @override
  State<_DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<_DifficultyCard> {
  bool _hovered = false;

  Color get _color {
    switch (widget.difficulty) {
      case Difficulty.beginner: return AppTheme.beginner;
      case Difficulty.intermediate: return AppTheme.intermediate;
      case Difficulty.master: return AppTheme.master;
    }
  }

  IconData get _icon {
    switch (widget.difficulty) {
      case Difficulty.beginner: return Icons.keyboard_outlined;
      case Difficulty.intermediate: return Icons.speed_outlined;
      case Difficulty.master: return Icons.local_fire_department_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService();
    final highestLevel = progress.getHighestUnlockedLevel(widget.difficulty);
    final totalStars = progress.getTotalStars(widget.difficulty);
    final progressPercent = highestLevel / 100;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LevelSelectScreen(difficulty: widget.difficulty)),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovered ? _color.withValues(alpha: 0.1) : AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered ? _color : AppTheme.cardBorder,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: _color.withValues(alpha: 0.25), blurRadius: 30, spreadRadius: 3)]
                : null,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon & badge
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_icon, color: _color, size: 30),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.difficulty.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              Text(widget.difficulty.label.toUpperCase(), style: AppTheme.heading(22, color: _color)),
              const SizedBox(height: 8),
              Text(widget.difficulty.description, style: AppTheme.body(13, color: AppTheme.textSecondary)),

              // Keyboard note for beginner
              if (widget.difficulty == Difficulty.beginner) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_outlined, color: AppTheme.primary, size: 14),
                      const SizedBox(width: 6),
                      Text('On-screen keyboard guide included', style: AppTheme.body(11, color: AppTheme.primary)),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level $highestLevel / 100', style: AppTheme.body(13, color: AppTheme.textSecondary)),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.gold, size: 14),
                      const SizedBox(width: 4),
                      Text('$totalStars / 300', style: AppTheme.body(13, color: AppTheme.gold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: _color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(_color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),

              // Play button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _color,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: _hovered ? 8 : 2,
                    shadowColor: _color.withValues(alpha: 0.5),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LevelSelectScreen(difficulty: widget.difficulty)),
                  ),
                  child: Text('SELECT LEVELS', style: AppTheme.heading(13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.primary.withValues(alpha: 0.03)..strokeWidth = 1;
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