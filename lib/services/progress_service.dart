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

  // Profile-scoped key: "p_{id}_beginner_5_stars"
  String get _p => ProfileService().keyPrefix;
  String _key(Difficulty d, int level) => '$_p${d.name}_$level';

  Future<void> saveResult(Difficulty d, int level, LevelResult result) async {
    await _prefs?.setInt('${_key(d, level)}_wpm', result.wpm);
    await _prefs?.setDouble('${_key(d, level)}_acc', result.accuracy);
    await _prefs?.setInt('${_key(d, level)}_stars', result.stars);
    await _prefs?.setBool('${_key(d, level + 1)}_unlocked', true);
  }

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

  Future<void> resetAll() async => await _prefs?.clear();
}