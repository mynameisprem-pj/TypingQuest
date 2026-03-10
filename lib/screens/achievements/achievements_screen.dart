import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/achievements_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = AchievementsService();
    final total = svc.total;
    final done = svc.totalUnlocked;

    // Group by category
    final categories = ['speed', 'accuracy', 'progress', 'dedication'];
    final catNames = {'speed': '🚀 Speed', 'accuracy': '🎯 Accuracy', 'progress': '📈 Progress', 'dedication': '💪 Dedication'};
    final catColors = {'speed': AppTheme.primary, 'accuracy': AppTheme.gold, 'progress': AppTheme.success, 'dedication': const Color(0xFFCE93D8)};

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ACHIEVEMENTS', style: AppTheme.heading(16, color: AppTheme.gold)),
          Text('$done / $total unlocked', style: AppTheme.body(12, color: AppTheme.textSecondary)),
        ]),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppTheme.cardBorder)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.gold.withValues(alpha: 0.12), AppTheme.primary.withValues(alpha: 0.06)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total Progress', style: AppTheme.body(13, color: AppTheme.textSecondary)),
                  Text('$done / $total', style: AppTheme.heading(18, color: AppTheme.gold)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(value: total > 0 ? done / total : 0, backgroundColor: AppTheme.gold.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation(AppTheme.gold), minHeight: 8),
                ),
              ]),
            ),
            const SizedBox(height: 28),

            // Categories
            ...categories.map((cat) {
              final catAchs = allAchievements.where((a) => a.category == cat).toList();
              final catColor = catColors[cat] ?? AppTheme.primary;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catNames[cat]!, style: AppTheme.heading(16, color: catColor)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: catAchs.length,
                    itemBuilder: (_, i) {
                      final ach = catAchs[i];
                      final isUnlocked = svc.isUnlocked(ach.id);
                      return _AchievementCard(achievement: ach, isUnlocked: isUnlocked, color: catColor);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final Color color;
  const _AchievementCard({required this.achievement, required this.isUnlocked, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withValues(alpha: 0.1) : AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnlocked ? color.withValues(alpha: 0.4) : AppTheme.cardBorder),
        boxShadow: isUnlocked ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8)] : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUnlocked ? achievement.icon : '🔒',
            style: TextStyle(fontSize: 28, color: isUnlocked ? null : Colors.transparent.withValues(alpha: 0),
            shadows: isUnlocked ? null : [const Shadow(color: Colors.grey, blurRadius: 0)]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isUnlocked ? achievement.title : '???',
                  style: AppTheme.body(13, color: isUnlocked ? AppTheme.textPrimary : AppTheme.textMuted, weight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isUnlocked ? achievement.description : 'Keep practicing to unlock',
                  style: AppTheme.body(11, color: AppTheme.textSecondary),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(Icons.check_circle, color: color, size: 16),
        ],
      ),
    );
  }
}