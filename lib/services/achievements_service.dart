import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';

// ── Achievement Definition ─────────────────────────────────────────────────
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category; // 'speed', 'accuracy', 'progress', 'dedication'

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
  });
}

// ── All Achievements ───────────────────────────────────────────────────────
const List<Achievement> allAchievements = [
  // 🚀 Speed achievements
  Achievement(id: 'wpm_10',  title: 'Slow Start',       description: 'Reach 10 WPM',           icon: '🐢', category: 'speed'),
  Achievement(id: 'wpm_20',  title: 'Getting There',     description: 'Reach 20 WPM',           icon: '🚶', category: 'speed'),
  Achievement(id: 'wpm_30',  title: 'Decent Typist',     description: 'Reach 30 WPM',           icon: '🏃', category: 'speed'),
  Achievement(id: 'wpm_40',  title: 'Fast Fingers',      description: 'Reach 40 WPM',           icon: '💨', category: 'speed'),
  Achievement(id: 'wpm_50',  title: 'Half Century',      description: 'Reach 50 WPM',           icon: '⚡', category: 'speed'),
  Achievement(id: 'wpm_60',  title: 'Speed Demon',       description: 'Reach 60 WPM',           icon: '🔥', category: 'speed'),
  Achievement(id: 'wpm_80',  title: 'Lightning Hands',   description: 'Reach 80 WPM',           icon: '⚡🔥', category: 'speed'),
  Achievement(id: 'wpm_100', title: 'Century Club',      description: 'Reach 100 WPM',          icon: '💯', category: 'speed'),

  // 🎯 Accuracy achievements
  Achievement(id: 'acc_90',  title: 'Sharp Eyes',        description: 'Complete a session at 90%+ accuracy', icon: '👁️', category: 'accuracy'),
  Achievement(id: 'acc_95',  title: 'Near Perfect',      description: 'Complete a session at 95%+ accuracy', icon: '🎯', category: 'accuracy'),
  Achievement(id: 'acc_100', title: 'Perfect Round',     description: 'Complete a session with 100% accuracy', icon: '💎', category: 'accuracy'),
  Achievement(id: 'acc_streak_5', title: 'Consistent',  description: '5 sessions in a row above 90% accuracy', icon: '📈', category: 'accuracy'),

  // 📈 Progress achievements
  Achievement(id: 'levels_10',  title: 'Level Up',       description: 'Complete 10 solo levels', icon: '🔟', category: 'progress'),
  Achievement(id: 'levels_50',  title: 'Halfway Hero',   description: 'Complete 50 solo levels', icon: '🌟', category: 'progress'),
  Achievement(id: 'levels_100', title: 'Level Master',   description: 'Complete all 100 solo levels in one difficulty', icon: '👑', category: 'progress'),
  Achievement(id: 'lesson_1',   title: 'First Lesson',   description: 'Complete your first lesson', icon: '📚', category: 'progress'),
  Achievement(id: 'lesson_all', title: 'Scholar',        description: 'Complete all lessons',   icon: '🎓', category: 'progress'),
  Achievement(id: 'timed_first', title: 'Race the Clock', description: 'Complete a timed challenge', icon: '⏱️', category: 'progress'),
  Achievement(id: 'custom_first', title: 'Your Words',   description: 'Practice with custom text', icon: '✏️', category: 'progress'),
  Achievement(id: 'lan_first',  title: 'Racer',          description: 'Finish a LAN race',       icon: '🏁', category: 'progress'),
  Achievement(id: 'lan_win',    title: 'Champion',       description: 'Win a LAN race',          icon: '🏆', category: 'progress'),

  // 💪 Dedication achievements
  Achievement(id: 'sessions_5',   title: 'Getting Serious',  description: 'Complete 5 practice sessions',     icon: '✊', category: 'dedication'),
  Achievement(id: 'sessions_25',  title: 'Dedicated',        description: 'Complete 25 practice sessions',    icon: '💪', category: 'dedication'),
  Achievement(id: 'sessions_100', title: 'True Practitioner', description: 'Complete 100 practice sessions', icon: '🧘', category: 'dedication'),
  Achievement(id: 'words_100',    title: 'Word Starter',     description: 'Type 100 words total',             icon: '📝', category: 'dedication'),
  Achievement(id: 'words_1000',   title: 'Word Writer',      description: 'Type 1,000 words total',           icon: '📖', category: 'dedication'),
  Achievement(id: 'words_10000',  title: 'Word Master',      description: 'Type 10,000 words total',          icon: '📜', category: 'dedication'),
  Achievement(id: 'time_30min',   title: 'Half Hour Hero',   description: 'Practice for 30 minutes total',    icon: '⏰', category: 'dedication'),
  Achievement(id: 'time_1hr',     title: '1 Hour Typist',    description: 'Practice for 1 hour total',        icon: '🕐', category: 'dedication'),
  Achievement(id: 'time_5hr',     title: '5 Hour Legend',    description: 'Practice for 5 hours total',       icon: '🌙', category: 'dedication'),
];

// ── Achievements Service ───────────────────────────────────────────────────
class AchievementsService {
  static final AchievementsService _i = AchievementsService._();
  factory AchievementsService() => _i;
  AchievementsService._();

  SharedPreferences? _prefs;
  // Callback for newly unlocked achievements
  Function(Achievement)? onUnlock;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get _prefix => ProfileService().keyPrefix;

  bool isUnlocked(String id) => _prefs?.getBool('${_prefix}ach_$id') ?? false;

  Future<bool> unlock(String id) async {
    if (isUnlocked(id)) return false;
    await _prefs?.setBool('${_prefix}ach_$id', true);
    final ach = allAchievements.where((a) => a.id == id).firstOrNull;
    if (ach != null) onUnlock?.call(ach);
    return true;
  }

  List<Achievement> getUnlocked() => allAchievements.where((a) => isUnlocked(a.id)).toList();
  List<Achievement> getLocked() => allAchievements.where((a) => !isUnlocked(a.id)).toList();
  int get totalUnlocked => getUnlocked().length;
  int get total => allAchievements.length;

  // Check and auto-unlock based on stats
  Future<void> checkAll({
    int? bestWpm,
    double? lastAccuracy,
    int? totalSessions,
    int? totalWords,
    int? totalTimeSeconds,
    int? completedLevels,
    bool firstLesson = false,
    bool allLessons = false,
    bool timedFirst = false,
    bool customFirst = false,
    bool lanFirst = false,
    bool lanWin = false,
  }) async {
    // Speed
    if (bestWpm != null) {
      if (bestWpm >= 10) await unlock('wpm_10');
      if (bestWpm >= 20) await unlock('wpm_20');
      if (bestWpm >= 30) await unlock('wpm_30');
      if (bestWpm >= 40) await unlock('wpm_40');
      if (bestWpm >= 50) await unlock('wpm_50');
      if (bestWpm >= 60) await unlock('wpm_60');
      if (bestWpm >= 80) await unlock('wpm_80');
      if (bestWpm >= 100) await unlock('wpm_100');
    }
    // Accuracy
    if (lastAccuracy != null) {
      if (lastAccuracy >= 90) await unlock('acc_90');
      if (lastAccuracy >= 95) await unlock('acc_95');
      if (lastAccuracy >= 100) await unlock('acc_100');
    }
    // Sessions
    if (totalSessions != null) {
      if (totalSessions >= 5) await unlock('sessions_5');
      if (totalSessions >= 25) await unlock('sessions_25');
      if (totalSessions >= 100) await unlock('sessions_100');
    }
    // Words
    if (totalWords != null) {
      if (totalWords >= 100) await unlock('words_100');
      if (totalWords >= 1000) await unlock('words_1000');
      if (totalWords >= 10000) await unlock('words_10000');
    }
    // Time
    if (totalTimeSeconds != null) {
      if (totalTimeSeconds >= 1800) await unlock('time_30min');
      if (totalTimeSeconds >= 3600) await unlock('time_1hr');
      if (totalTimeSeconds >= 18000) await unlock('time_5hr');
    }
    // Levels
    if (completedLevels != null) {
      if (completedLevels >= 10) await unlock('levels_10');
      if (completedLevels >= 50) await unlock('levels_50');
      if (completedLevels >= 100) await unlock('levels_100');
    }
    // One-time
    if (firstLesson) await unlock('lesson_1');
    if (allLessons) await unlock('lesson_all');
    if (timedFirst) await unlock('timed_first');
    if (customFirst) await unlock('custom_first');
    if (lanFirst) await unlock('lan_first');
    if (lanWin) await unlock('lan_win');
  }
}