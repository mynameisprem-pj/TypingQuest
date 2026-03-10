import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/lesson_data.dart';
import '../../services/lesson_progress_service.dart';
import 'exercise_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final LessonCourse course;
  const LessonDetailScreen({super.key, required this.course});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final _p = LessonProgressService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(widget.course.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.course.title, style: AppTheme.heading(15)),
                Text('${widget.course.lessons.length} lessons', style: AppTheme.body(12, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: widget.course.lessons.length,
        itemBuilder: (_, i) {
          final lesson = widget.course.lessons[i];
          final done = _p.isLessonComplete(widget.course.id, lesson.id);
          final highestEx = _p.getHighestExercise(widget.course.id, lesson.id);
          final bestWpm = _p.getBestWpm(widget.course.id, lesson.id);
          final unlocked = i == 0 || _p.isLessonComplete(widget.course.id, widget.course.lessons[i - 1].id);
          final inProgress = !done && highestEx >= 0;

          return _LessonRow(
            lesson: lesson,
            index: i,
            done: done,
            unlocked: unlocked,
            inProgress: inProgress,
            highestExercise: highestEx,
            bestWpm: bestWpm,
            totalExercises: lesson.exercises.length,
            onTap: unlocked
                ? () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseScreen(
                          course: widget.course,
                          lesson: lesson,
                          startExercise: inProgress ? highestEx : 0,
                        ),
                      ),
                    );
                    setState(() {});
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _LessonRow extends StatefulWidget {
  final Lesson lesson;
  final int index;
  final bool done;
  final bool unlocked;
  final bool inProgress;
  final int highestExercise;
  final int bestWpm;
  final int totalExercises;
  final VoidCallback? onTap;

  const _LessonRow({
    required this.lesson,
    required this.index,
    required this.done,
    required this.unlocked,
    required this.inProgress,
    required this.highestExercise,
    required this.bestWpm,
    required this.totalExercises,
    this.onTap,
  });

  @override
  State<_LessonRow> createState() => _LessonRowState();
}

class _LessonRowState extends State<_LessonRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.done
        ? AppTheme.success
        : widget.inProgress
            ? AppTheme.gold
            : widget.unlocked
                ? AppTheme.primary
                : AppTheme.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _hovered && widget.unlocked ? statusColor.withValues(alpha: 0.08) : AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.done ? AppTheme.success.withValues(alpha: 0.4)
                    : _hovered && widget.unlocked ? statusColor
                    : AppTheme.cardBorder,
              ),
              boxShadow: _hovered && widget.unlocked
                  ? [BoxShadow(color: statusColor.withValues(alpha: 0.15), blurRadius: 12)]
                  : null,
            ),
            child: Row(
              children: [
                // Number circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.15),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: widget.done
                        ? Icon(Icons.check, color: AppTheme.success, size: 18)
                        : !widget.unlocked
                            ? Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 16)
                            : Text('${widget.index + 1}', style: AppTheme.heading(14, color: statusColor)),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.lesson.title, style: AppTheme.body(15, color: widget.unlocked ? AppTheme.textPrimary : AppTheme.textMuted)),
                      const SizedBox(height: 3),
                      Text(widget.lesson.subtitle, style: AppTheme.body(12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      // Keys badge
                      Wrap(
                        spacing: 4,
                        children: widget.lesson.keys.split(' ').map((k) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(k, style: AppTheme.mono(10, color: statusColor)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Right stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.done && widget.bestWpm > 0)
                      Text('${widget.bestWpm} WPM', style: AppTheme.body(12, color: AppTheme.primary)),
                    if (widget.inProgress)
                      Text(
                        '${widget.highestExercise + 1}/${widget.totalExercises}',
                        style: AppTheme.body(12, color: AppTheme.gold),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.totalExercises} exercises',
                      style: AppTheme.body(11, color: AppTheme.textMuted),
                    ),
                    if (widget.unlocked && !widget.done)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(Icons.arrow_forward_ios, size: 14, color: statusColor.withValues(alpha: 0.6)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}