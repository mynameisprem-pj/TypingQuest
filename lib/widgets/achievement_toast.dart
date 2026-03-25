import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/achievements_service.dart';

/// Shows a beautiful toast notification when an achievement is unlocked.
void showAchievementToast(BuildContext context, Achievement achievement) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _AchievementToast(
      achievement: achievement,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _AchievementToast extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const _AchievementToast({
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<_AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<_AchievementToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double>  _fade;

  @override
  void initState() {
    super.initState();

    // 350 ms is snappy but not jarring on low-end hardware.
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 350),
    );

    // easeOutCubic: smooth deceleration with no spring/bounce physics.
    // Curves.elasticOut recalculates spring forces every frame — unnecessary
    // for a notification toast and noticeably heavier on low-end CPUs.
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:   80,
      left:  0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              margin:  const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color:        AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:      AppTheme.gold.withValues(alpha: 0.18),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    widget.achievement.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievement Unlocked!',
                          style: AppTheme.body(11, color: AppTheme.gold)
                              .copyWith(letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.achievement.title,
                          style: AppTheme.heading(16, color: AppTheme.textPrimary),
                        ),
                        Text(
                          widget.achievement.description,
                          style: AppTheme.body(12, color: AppTheme.textSecondary),
                        ),
                      ],
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
}