import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';

class LessonProgress {
  final String courseId;
  final String lessonId;
  final int exerciseIndex;
  final bool completed;
  final int bestWpm;
  final double bestAccuracy;

  const LessonProgress({
    required this.courseId,
    required this.lessonId,
    required this.exerciseIndex,
    required this.completed,
    required this.bestWpm,
    required this.bestAccuracy,
  });
}

class LessonProgressService {
  static final LessonProgressService _i = LessonProgressService._();
  factory LessonProgressService() => _i;
  LessonProgressService._();

  SharedPreferences? _prefs;

  /// Called from main.dart on startup.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Lazily obtains SharedPreferences so calls made before [init] (or if
  /// init is skipped) still work correctly instead of silently doing nothing.
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String get _prefix => ProfileService().keyPrefix;

  // Key for per-lesson data (WPM, accuracy, exercise progress, done flag).
  String _lessonKey(String courseId, String lessonId) =>
      '${_prefix}lesson_${courseId}_$lessonId';

  // Key for the "lesson at this index is now unlocked" flag.
  // Stored by lesson index so the service does not need to know the next
  // lesson's string ID at write time.
  String _unlockKey(String courseId, int lessonIndex) =>
      '${_prefix}lesson_${courseId}_unlock_$lessonIndex';

  // ── Exercise progress ─────────────────────────────────────────────────

  Future<void> markExerciseComplete(
    String courseId,
    String lessonId,
    int exerciseIndex,
    int wpm,
    double accuracy,
  ) async {
    final prefs = await _getPrefs();
    final key   = _lessonKey(courseId, lessonId);

    // Advance highest completed exercise index.
    final current = prefs.getInt('${key}_exercise') ?? -1;
    if (exerciseIndex > current) {
      await prefs.setInt('${key}_exercise', exerciseIndex);
    }

    // Persist personal bests.
    final bestWpm = prefs.getInt('${key}_wpm') ?? 0;
    if (wpm > bestWpm) await prefs.setInt('${key}_wpm', wpm);

    final bestAcc = prefs.getDouble('${key}_acc') ?? 0.0;
    if (accuracy > bestAcc) await prefs.setDouble('${key}_acc', accuracy);
  }

  // ── Lesson completion ─────────────────────────────────────────────────

  /// Mark a lesson complete and unlock the NEXT lesson (at lessonIndex + 1).
  ///
  /// [lessonIndex] is the 0-based position of this lesson within its course.
  ///
  /// BUG FIX: the previous implementation stored `_unlocked_next` on the
  /// current lesson's key and then checked it on the current lesson in
  /// [isLessonUnlocked], meaning lesson N was checking its own key (which
  /// was never set by anyone) instead of the previous lesson's key.
  /// The fix uses an index-based key so the writer and reader agree.
  Future<void> markLessonComplete(
    String courseId,
    String lessonId,
    int lessonIndex,
  ) async {
    final prefs = await _getPrefs();
    await prefs.setBool('${_lessonKey(courseId, lessonId)}_done', true);
    // Unlock the next lesson by its index.
    await prefs.setBool(_unlockKey(courseId, lessonIndex + 1), true);
  }

  // ── Queries ───────────────────────────────────────────────────────────

  bool isLessonComplete(String courseId, String lessonId) {
    return _prefs?.getBool('${_lessonKey(courseId, lessonId)}_done') ?? false;
  }

  /// Lesson 0 (the first in every course) is always unlocked.
  /// Any subsequent lesson is unlocked when the previous one is complete.
  bool isLessonUnlocked(String courseId, String lessonId, int lessonIndex) {
    if (lessonIndex == 0) return true;
    return _prefs?.getBool(_unlockKey(courseId, lessonIndex)) ?? false;
  }

  int getHighestExercise(String courseId, String lessonId) {
    return _prefs?.getInt('${_lessonKey(courseId, lessonId)}_exercise') ?? -1;
  }

  int getBestWpm(String courseId, String lessonId) {
    return _prefs?.getInt('${_lessonKey(courseId, lessonId)}_wpm') ?? 0;
  }

  double getBestAccuracy(String courseId, String lessonId) {
    return _prefs?.getDouble('${_lessonKey(courseId, lessonId)}_acc') ?? 0.0;
  }

  bool isCourseStarted(String courseId) {
    return _prefs?.getBool('${_prefix}course_started_$courseId') ?? false;
  }

  Future<void> markCourseStarted(String courseId) async {
    final prefs = await _getPrefs();
    await prefs.setBool('${_prefix}course_started_$courseId', true);
  }

  int completedLessonsInCourse(String courseId, List<String> lessonIds) {
    return lessonIds.where((id) => isLessonComplete(courseId, id)).length;
  }
}