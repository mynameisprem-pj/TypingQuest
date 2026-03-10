// ── Difficulty Enum ───────────────────────────────────────────────────────
enum Difficulty { beginner, intermediate, master }

extension DifficultyExt on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.beginner:     return 'Beginner';
      case Difficulty.intermediate: return 'Intermediate';
      case Difficulty.master:       return 'Master';
    }
  }

  String get description {
    switch (this) {
      case Difficulty.beginner:     return 'Learn keys with on-screen keyboard guide';
      case Difficulty.intermediate: return 'Sentences & paragraphs without hints';
      case Difficulty.master:       return 'Complex text, high speed required';
    }
  }

  String get emoji {
    switch (this) {
      case Difficulty.beginner:     return '🟢';
      case Difficulty.intermediate: return '🟡';
      case Difficulty.master:       return '🔴';
    }
  }
}

// ── Level Result ──────────────────────────────────────────────────────────
class LevelResult {
  final int wpm;
  final double accuracy;
  final int stars; // 1, 2, or 3
  final Duration timeTaken;

  const LevelResult({
    required this.wpm,
    required this.accuracy,
    required this.stars,
    required this.timeTaken,
  });

  static int calculateStars(double accuracy, int wpm, int targetWpm) {
    if (accuracy >= 98 && wpm >= targetWpm) return 3;
    if (accuracy >= 90 && wpm >= targetWpm * 0.8) return 2;
    return 1;
  }
}

// ── LAN Player ────────────────────────────────────────────────────────────
class LanPlayer {
  final String id;
  final String name;
  double progress; // 0.0 to 1.0
  int wpm;
  bool finished;
  int? rank;
  int wordsTyped;
  bool disconnected;
  bool dnf;
  int? finishElapsedMs;
  int? finishClientTimestampMs;
  int? finishServerTimestampMs;
  int? lastSeenMs;

  LanPlayer({
    required this.id,
    required this.name,
    this.progress = 0.0,
    this.wpm = 0,
    this.wordsTyped = 0,
    this.finished = false,
    this.rank,
    this.disconnected = false,
    this.dnf = false,
    this.finishElapsedMs,
    this.finishClientTimestampMs,
    this.finishServerTimestampMs,
    this.lastSeenMs,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'progress': progress,
    'wpm': wpm,
    'finished': finished,
    'rank': rank,
    'wordsTyped': wordsTyped,
    'disconnected': disconnected,
    'dnf': dnf,
    'finishElapsedMs': finishElapsedMs,
    'finishClientTimestampMs': finishClientTimestampMs,
    'finishServerTimestampMs': finishServerTimestampMs,
    'lastSeenMs': lastSeenMs,
  };

  factory LanPlayer.fromJson(Map<String, dynamic> json) => LanPlayer(
    id: json['id'],
    name: json['name'],
    progress: (json['progress'] as num).toDouble(),
    wpm: json['wpm'] ?? 0,
    finished: json['finished'] ?? false,
    rank: json['rank'],
    wordsTyped: json['wordsTyped'] ?? 0,
    disconnected: json['disconnected'] ?? false,
    dnf: json['dnf'] ?? false,
    finishElapsedMs: json['finishElapsedMs'],
    finishClientTimestampMs: json['finishClientTimestampMs'],
    finishServerTimestampMs: json['finishServerTimestampMs'],
    lastSeenMs: json['lastSeenMs'],
  );
}

enum LanRacePhase { lobby, countdown, racing, results }

extension LanRacePhaseExt on LanRacePhase {
  String get wireName {
    switch (this) {
      case LanRacePhase.lobby:
        return 'LOBBY';
      case LanRacePhase.countdown:
        return 'COUNTDOWN';
      case LanRacePhase.racing:
        return 'RACING';
      case LanRacePhase.results:
        return 'RESULTS';
    }
  }

  static LanRacePhase fromWireName(String value) {
    switch (value) {
      case 'COUNTDOWN':
        return LanRacePhase.countdown;
      case 'RACING':
        return LanRacePhase.racing;
      case 'RESULTS':
        return LanRacePhase.results;
      case 'LOBBY':
      default:
        return LanRacePhase.lobby;
    }
  }
}

// ── LAN Message Types (wire protocol) ────────────────────────────────────
class LanMessage {
  static const String joinRequest = 'join_request';
  static const String joinAck = 'join_ack';
  static const String playerList = 'player_list';
  static const String playerDisconnect = 'player_disconnect';
  static const String startRace = 'start_race';
  static const String progressUpdate = 'progress_update';
  static const String finished = 'finished';
  static const String raceComplete = 'race_complete';
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String phaseUpdate = 'phase_update';
  static const String error = 'error';
}
