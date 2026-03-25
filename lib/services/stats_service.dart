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
    'date':            date.millisecondsSinceEpoch,
    'wpm':             wpm,
    'accuracy':        accuracy,
    'wordsTyped':      wordsTyped,
    'durationSeconds': durationSeconds,
    'mode':            mode,
  };

  factory TypingSession.fromJson(Map<String, dynamic> j) => TypingSession(
    date:            DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
    wpm:             j['wpm']             ?? 0,
    accuracy:       (j['accuracy'] as num?)?.toDouble() ?? 0.0,
    wordsTyped:      j['wordsTyped']      ?? 0,
    durationSeconds: j['durationSeconds'] ?? 0,
    mode:            j['mode']            ?? 'solo',
  );
}

class StatsService {
  static final StatsService _i = StatsService._();
  factory StatsService() => _i;
  StatsService._();

  SharedPreferences? _prefs;

  // ── In-memory session cache ───────────────────────────────────────────
  // Loaded once from SharedPreferences. All reads use this list directly,
  // avoiding repeated full JSON deserialisation of up to 500 sessions.
  List<TypingSession>? _sessionCache;

  // The profile prefix active when the cache was last loaded.
  // If the active profile changes, the cache is invalidated automatically.
  String _cachedPrefix = '\x00'; // impossible real prefix

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get _prefix => ProfileService().keyPrefix;

  // ── Session cache management ──────────────────────────────────────────

  /// Returns the in-memory session list, loading from storage if needed.
  /// Automatically reloads when the active profile changes.
  Future<List<TypingSession>> getSessions() async {
    final prefix = _prefix;
    if (_sessionCache == null || _cachedPrefix != prefix) {
      _sessionCache  = await _loadSessions(prefix);
      _cachedPrefix  = prefix;
    }
    return _sessionCache!;
  }

  Future<List<TypingSession>> _loadSessions(String prefix) async {
    final raw = _prefs?.getString('${prefix}sessions');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(TypingSession.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Write path ────────────────────────────────────────────────────────

  Future<void> recordSession(TypingSession session) async {
    // Ensure cache is warm before we mutate it.
    final sessions = await getSessions();
    sessions.add(session);

    // Cap at 500 sessions per profile.
    if (sessions.length > 500) {
      sessions.removeRange(0, sessions.length - 500);
    }

    // Persist the updated list — single serialisation call.
    await _prefs?.setString(
      '${_prefix}sessions',
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );

    // Update scalar aggregates (best WPM, totals) as single, cheap writes.
    final bestWpm = _prefs?.getInt('${_prefix}best_wpm') ?? 0;
    if (session.wpm > bestWpm) {
      await _prefs?.setInt('${_prefix}best_wpm', session.wpm);
    }

    await _prefs?.setInt(
      '${_prefix}total_words',
      (_prefs?.getInt('${_prefix}total_words') ?? 0) + session.wordsTyped,
    );
    await _prefs?.setInt(
      '${_prefix}total_time',
      (_prefs?.getInt('${_prefix}total_time') ?? 0) + session.durationSeconds,
    );
    await _prefs?.setInt(
      '${_prefix}total_sessions',
      (_prefs?.getInt('${_prefix}total_sessions') ?? 0) + 1,
    );
  }

  // ── Fast scalar reads (no JSON parsing) ──────────────────────────────

  int getBestWpm()          => _prefs?.getInt('${_prefix}best_wpm')       ?? 0;
  int getTotalWords()       => _prefs?.getInt('${_prefix}total_words')     ?? 0;
  int getTotalTimeSeconds() => _prefs?.getInt('${_prefix}total_time')      ?? 0;
  int getTotalSessions()    => _prefs?.getInt('${_prefix}total_sessions')  ?? 0;

  // ── Aggregate reads (use the cache — no repeated JSON parse) ─────────

  Future<double> getAverageAccuracy() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) return 0.0;
    final recent = sessions.length > 50
        ? sessions.sublist(sessions.length - 50)
        : sessions;
    return recent.map((s) => s.accuracy).reduce((a, b) => a + b) / recent.length;
  }

  /// Returns (date, avgWpm) pairs for each of the last 7 days.
  Future<List<MapEntry<DateTime, double>>> getLast7DaysWpm() async {
    final sessions = await getSessions(); // single cache hit
    final now      = DateTime.now();
    final result   = <MapEntry<DateTime, double>>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final daySessions = sessions.where((s) =>
          s.date.year  == day.year  &&
          s.date.month == day.month &&
          s.date.day   == day.day).toList();

      final avgWpm = daySessions.isEmpty
          ? 0.0
          : daySessions.map((s) => s.wpm.toDouble()).reduce((a, b) => a + b) /
              daySessions.length;

      result.add(MapEntry(day, avgWpm));
    }
    return result;
  }

  /// Returns session counts grouped by mode.
  Future<Map<String, int>> getModeSessionCounts() async {
    final sessions = await getSessions(); // single cache hit
    final counts   = <String, int>{};
    for (final s in sessions) {
      counts[s.mode] = (counts[s.mode] ?? 0) + 1;
    }
    return counts;
  }
}