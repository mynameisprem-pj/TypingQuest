import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../services/progress_service.dart';
import 'typing_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  final Difficulty difficulty;
  const LevelSelectScreen({super.key, required this.difficulty});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Color get _color {
    switch (widget.difficulty) {
      case Difficulty.beginner: return AppTheme.beginner;
      case Difficulty.intermediate: return AppTheme.intermediate;
      case Difficulty.master: return AppTheme.master;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.difficulty.label.toUpperCase(), style: AppTheme.heading(16, color: _color)),
            Text('Select a level to play', style: AppTheme.body(12, color: AppTheme.textSecondary)),
          ],
        ),
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
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 80,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: 100,
          itemBuilder: (context, index) {
            final level = index + 1;
            final unlocked = progress.isUnlocked(widget.difficulty, level);
            final stars = progress.getStars(widget.difficulty, level);
            final wpm = progress.getBestWpm(widget.difficulty, level);

            return _LevelCell(
              level: level,
              unlocked: unlocked,
              stars: stars,
              wpm: wpm,
              color: _color,
              onTap: unlocked
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TypingScreen(
                            difficulty: widget.difficulty,
                            level: level,
                          ),
                        ),
                      );
                      setState(() {}); // refresh stars after returning
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _LevelCell extends StatefulWidget {
  final int level;
  final bool unlocked;
  final int stars;
  final int wpm;
  final Color color;
  final VoidCallback? onTap;

  const _LevelCell({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.wpm,
    required this.color,
    this.onTap,
  });

  @override
  State<_LevelCell> createState() => _LevelCellState();
}

class _LevelCellState extends State<_LevelCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final completed = widget.stars > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.unlocked
            ? (completed
                ? '${widget.stars}⭐ • Best: ${widget.wpm} WPM'
                : 'Level ${widget.level} — Click to play')
            : 'Complete level ${widget.level - 1} to unlock',
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: !widget.unlocked
                  ? AppTheme.surface
                  : completed
                      ? widget.color.withValues(alpha: _hovered ? 0.25 : 0.12)
                      : AppTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: !widget.unlocked
                    ? AppTheme.textMuted.withValues(alpha: 0.2)
                    : _hovered
                        ? widget.color
                        : completed
                            ? widget.color.withValues(alpha: 0.4)
                            : AppTheme.cardBorder,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered && widget.unlocked
                  ? [BoxShadow(color: widget.color.withValues(alpha: 0.3), blurRadius: 10)]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!widget.unlocked)
                  Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 16)
                else ...[
                  Text(
                    '${widget.level}',
                    style: AppTheme.heading(15, color: _hovered ? widget.color : AppTheme.textPrimary),
                  ),
                  if (completed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Icon(
                        i < widget.stars ? Icons.star : Icons.star_border,
                        color: AppTheme.gold,
                        size: 10,
                      )),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}