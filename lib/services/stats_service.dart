import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';

class TypingSession {
  final DateTime date;
  final int wpm;
  final double accuracy;
  final int wordsTyped;
  final int durationSeconds;
  final String mode; // 'solo', 'timed', 'lesson', 'custom', 'lan'

  const TypingSession({
    required this.date,
    required this.wpm,
    required this.accuracy,
    required this.wordsTyped,
    required this.durationSeconds,
    required this.mode,
  });

  Map<String, dynamic> toJson() => {
    'date': date.millisecondsSinceEpoch,
    'wpm': wpm,
    'accuracy': accuracy,
    'wordsTyped': wordsTyped,
    'durationSeconds': durationSeconds,
    'mode': mode,
  };

  factory TypingSession.fromJson(Map<String, dynamic> j) => TypingSession(
    date: DateTime.fromMillisecondsSinceEpoch(j['date']),
    wpm: j['wpm'] ?? 0,
    accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0.0,
    wordsTyped: j['wordsTyped'] ?? 0,
    durationSeconds: j['durationSeconds'] ?? 0,
    mode: j['mode'] ?? 'solo',
  );
}

class StatsService {
  static final StatsService _i = StatsService._();
  factory StatsService() => _i;
  StatsService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get _prefix => ProfileService().keyPrefix;

  Future<void> recordSession(TypingSession session) async {
    final sessions = await getSessions();
    sessions.add(session);
    // Keep max 500 sessions per profile
    if (sessions.length > 500) sessions.removeRange(0, sessions.length - 500);
    await _prefs?.setString('${_prefix}sessions', jsonEncode(sessions.map((s) => s.toJson()).toList()));

    // Update best WPM
    final bestWpm = _prefs?.getInt('${_prefix}best_wpm') ?? 0;
    if (session.wpm > bestWpm) await _prefs?.setInt('${_prefix}best_wpm', session.wpm);

    // Update totals
    final totalWords = (_prefs?.getInt('${_prefix}total_words') ?? 0) + session.wordsTyped;
    await _prefs?.setInt('${_prefix}total_words', totalWords);

    final totalTime = (_prefs?.getInt('${_prefix}total_time') ?? 0) + session.durationSeconds;
    await _prefs?.setInt('${_prefix}total_time', totalTime);

    final totalSessions = (_prefs?.getInt('${_prefix}total_sessions') ?? 0) + 1;
    await _prefs?.setInt('${_prefix}total_sessions', totalSessions);
  }

  Future<List<TypingSession>> getSessions() async {
    final raw = _prefs?.getString('${_prefix}sessions');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((j) => TypingSession.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  int getBestWpm() => _prefs?.getInt('${_prefix}best_wpm') ?? 0;
  int getTotalWords() => _prefs?.getInt('${_prefix}total_words') ?? 0;
  int getTotalTimeSeconds() => _prefs?.getInt('${_prefix}total_time') ?? 0;
  int getTotalSessions() => _prefs?.getInt('${_prefix}total_sessions') ?? 0;

  Future<double> getAverageAccuracy() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) return 0.0;
    final recent = sessions.length > 50 ? sessions.sublist(sessions.length - 50) : sessions;
    return recent.map((s) => s.accuracy).reduce((a, b) => a + b) / recent.length;
  }

  // Returns list of (date, avgWpm) for last 7 days
  Future<List<MapEntry<DateTime, double>>> getLast7DaysWpm() async {
    final sessions = await getSessions();
    final now = DateTime.now();
    final result = <MapEntry<DateTime, double>>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final daySessions = sessions.where((s) =>
        s.date.year == day.year && s.date.month == day.month && s.date.day == day.day
      ).toList();

      final avgWpm = daySessions.isEmpty
          ? 0.0
          : daySessions.map((s) => s.wpm.toDouble()).reduce((a, b) => a + b) / daySessions.length;

      result.add(MapEntry(day, avgWpm));
    }
    return result;
  }

  // Per-mode stats
  Future<Map<String, int>> getModeSessionCounts() async {
    final sessions = await getSessions();
    final counts = <String, int>{};
    for (final s in sessions) {
      counts[s.mode] = (counts[s.mode] ?? 0) + 1;
    }
    return counts;
  }
}