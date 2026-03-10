import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/lesson_data.dart';
import '../../services/lesson_progress_service.dart';
import 'lesson_detail_screen.dart';

class LessonsHomeScreen extends StatefulWidget {
  const LessonsHomeScreen({super.key});

  @override
  State<LessonsHomeScreen> createState() => _LessonsHomeScreenState();
}

class _LessonsHomeScreenState extends State<LessonsHomeScreen> {
  final _progress = LessonProgressService();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _progress.init().then((_) => setState(() => _loaded = true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TYPING LESSONS', style: AppTheme.heading(16, color: AppTheme.primary)),
            Text('Learn finger by finger, key by key', style: AppTheme.body(12, color: AppTheme.textSecondary)),
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
      body: _loaded ? _buildBody() : const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        SizedBox.expand(child: CustomPaint(painter: _BgPainter())),
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              _buildHeaderBanner(),
              const SizedBox(height: 28),
              Text('COURSES', style: AppTheme.body(12, color: AppTheme.textSecondary).copyWith(letterSpacing: 3)),
              const SizedBox(height: 14),
              // Course grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 420,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.7,
                ),
                itemCount: LessonData.courses.length,
                itemBuilder: (_, i) {
                  final course = LessonData.courses[i];
                  final lessonIds = course.lessons.map((l) => l.id).toList();
                  final completed = _progress.completedLessonsInCourse(course.id, lessonIds);
                  final total = course.lessons.length;
                  final started = _progress.isCourseStarted(course.id);

                  return _CourseCard(
                    course: course,
                    completedLessons: completed,
                    totalLessons: total,
                    started: started,
                    locked: i > 2 && !started && completed == 0,
                    courseIndex: i,
                    onTap: () async {
                      await _progress.markCourseStarted(course.id);
                      if (mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LessonDetailScreen(course: course)),
                        );
                        setState(() {});
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    // Count total completed lessons
    int totalCompleted = 0;
    int totalLessons = 0;
    for (final course in LessonData.courses) {
      totalLessons += course.lessons.length;
      totalCompleted += _progress.completedLessonsInCourse(
        course.id,
        course.lessons.map((l) => l.id).toList(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.15), AppTheme.gold.withValues(alpha: 0.08)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Progress', style: AppTheme.body(13, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(
                '$totalCompleted / $totalLessons lessons complete',
                style: AppTheme.heading(20, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalLessons > 0 ? totalCompleted / totalLessons : 0,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Text('${LessonData.courses.length}', style: AppTheme.heading(32, color: AppTheme.gold)),
              Text('COURSES', style: AppTheme.body(11, color: AppTheme.textSecondary).copyWith(letterSpacing: 1)),
            ],
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              Text('$totalLessons', style: AppTheme.heading(32, color: AppTheme.primary)),
              Text('LESSONS', style: AppTheme.body(11, color: AppTheme.textSecondary).copyWith(letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Course Card ───────────────────────────────────────────────────────────
class _CourseCard extends StatefulWidget {
  final LessonCourse course;
  final int completedLessons;
  final int totalLessons;
  final bool started;
  final bool locked;
  final int courseIndex;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.completedLessons,
    required this.totalLessons,
    required this.started,
    required this.locked,
    required this.courseIndex,
    required this.onTap,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _hovered = false;

  Color get _color {
    final colors = [
      AppTheme.primary,
      const Color(0xFF00E676),
      AppTheme.gold,
      const Color(0xFFFF6B35),
      const Color(0xFFCE93D8),
      const Color(0xFFFF1744),
    ];
    return colors[widget.courseIndex % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalLessons > 0 ? widget.completedLessons / widget.totalLessons : 0.0;
    final allDone = widget.completedLessons == widget.totalLessons;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered ? _color.withValues(alpha: 0.1) : AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: allDone ? _color : (_hovered ? _color : AppTheme.cardBorder),
              width: allDone || _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered ? [BoxShadow(color: _color.withValues(alpha: 0.2), blurRadius: 20)] : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(widget.course.icon, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.course.title, style: AppTheme.heading(15, color: _color)),
                        ),
                        if (allDone)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('✓ DONE', style: AppTheme.body(10, color: AppTheme.success)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.course.description,
                      style: AppTheme.body(11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: _color.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(_color),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.completedLessons}/${widget.totalLessons}',
                          style: AppTheme.body(11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios, color: _color.withValues(alpha: 0.6), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppTheme.primary.withValues(alpha: 0.03)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}