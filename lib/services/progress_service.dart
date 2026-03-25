import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';
import 'profile_service.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Lazily obtains SharedPreferences so calls before [init] still work.
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Profile-scoped key: "p_{id}_beginner_5"
  String get _p   => ProfileService().keyPrefix;
  String _key(Difficulty d, int level) => '$_p${d.name}_$level';

  // ── Write ──────────────────────────────────────────────────────────────

  Future<void> saveResult(Difficulty d, int level, LevelResult result) async {
    final prefs = await _getPrefs();
    await prefs.setInt(   '${_key(d, level)}_wpm',              result.wpm);
    await prefs.setDouble('${_key(d, level)}_acc',              result.accuracy);
    await prefs.setInt(   '${_key(d, level)}_stars',            result.stars);
    await prefs.setBool(  '${_key(d, level + 1)}_unlocked',     true);
  }

  // ── Read ───────────────────────────────────────────────────────────────

  bool isUnlocked(Difficulty d, int level) {
    if (level == 1) return true;
    return _prefs?.getBool('${_key(d, level)}_unlocked') ?? false;
  }

  int getStars(Difficulty d, int level) =>
      _prefs?.getInt('${_key(d, level)}_stars') ?? 0;

  int getBestWpm(Difficulty d, int level) =>
      _prefs?.getInt('${_key(d, level)}_wpm') ?? 0;

  double getBestAccuracy(Difficulty d, int level) =>
      _prefs?.getDouble('${_key(d, level)}_acc') ?? 0.0;

  int getTotalStars(Difficulty d) {
    int total = 0;
    for (int i = 1; i <= 100; i++) {
      total += getStars(d, i);
    }
    return total;
  }

  int getHighestUnlockedLevel(Difficulty d) {
    for (int i = 100; i >= 1; i--) {
      if (isUnlocked(d, i)) return i;
    }
    return 1;
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  /// Removes only the keys that belong to the currently active profile.
  ///
  /// Previously this called [SharedPreferences.clear()] which wiped ALL
  /// profiles — a critical data-loss bug. Now only keys starting with the
  /// active profile's prefix are deleted.
  Future<void> resetAll() async {
    final prefs  = await _getPrefs();
    final prefix = _p;

    if (prefix.isEmpty) {
      // Guest profile — nothing was ever written to storage; nothing to clear.
      return;
    }

    final keysToRemove = prefs.getKeys()
        .where((k) => k.startsWith(prefix))
        .toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}
