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

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get _prefix => ProfileService().keyPrefix;
  String _key(String courseId, String lessonId) => '${_prefix}lesson_${courseId}_$lessonId';

  Future<void> markExerciseComplete(String courseId, String lessonId, int exerciseIndex, int wpm, double accuracy) async {
    final key = _key(courseId, lessonId);
    final current = _prefs?.getInt('${key}_exercise') ?? -1;
    if (exerciseIndex > current) {
      await _prefs?.setInt('${key}_exercise', exerciseIndex);
    }
    // Save best WPM
    final bestWpm = _prefs?.getInt('${key}_wpm') ?? 0;
    if (wpm > bestWpm) await _prefs?.setInt('${key}_wpm', wpm);
    // Save best accuracy
    final bestAcc = _prefs?.getDouble('${key}_acc') ?? 0.0;
    if (accuracy > bestAcc) await _prefs?.setDouble('${key}_acc', accuracy);
  }

  Future<void> markLessonComplete(String courseId, String lessonId) async {
    await _prefs?.setBool('${_key(courseId, lessonId)}_done', true);
    // Unlock next lesson indicator
    await _prefs?.setBool('${_key(courseId, lessonId)}_unlocked_next', true);
  }

  bool isLessonComplete(String courseId, String lessonId) {
    return _prefs?.getBool('${_key(courseId, lessonId)}_done') ?? false;
  }

  int getHighestExercise(String courseId, String lessonId) {
    return _prefs?.getInt('${_key(courseId, lessonId)}_exercise') ?? -1;
  }

  int getBestWpm(String courseId, String lessonId) {
    return _prefs?.getInt('${_key(courseId, lessonId)}_wpm') ?? 0;
  }

  double getBestAccuracy(String courseId, String lessonId) {
    return _prefs?.getDouble('${_key(courseId, lessonId)}_acc') ?? 0.0;
  }

  // Is lesson unlocked? (first lesson of each course always unlocked,
  // subsequent lessons unlock when previous is complete)
  bool isLessonUnlocked(String courseId, String lessonId, int lessonIndex) {
    if (lessonIndex == 0) return true;
    return _prefs?.getBool('${_key(courseId, lessonId)}_unlocked_next') ?? false;
  }

  bool isCourseStarted(String courseId) {
    final key = '${_prefix}course_started_$courseId';
    return _prefs?.getBool(key) ?? false;
  }

  Future<void> markCourseStarted(String courseId) async {
    await _prefs?.setBool('${_prefix}course_started_$courseId', true);
  }

  int completedLessonsInCourse(String courseId, List<String> lessonIds) {
    return lessonIds.where((id) => isLessonComplete(courseId, id)).length;
  }
}
