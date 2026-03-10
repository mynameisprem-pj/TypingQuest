import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/game_models.dart';

const int _kPort = 8765;
const Duration _kHeartbeatInterval = Duration(seconds: 2);
const Duration _kHeartbeatTimeout = Duration(seconds: 5);
const Duration _kStartLeadTime = Duration(seconds: 4);

class LanHostService {
  ServerSocket? _server;
  final Map<String, Socket> _clientSockets = {};
  final Map<String, String> _socketToPlayer = {};
  final Map<String, int> _lastPongAtMs = {};
  final Set<String> _raceParticipants = {};

  final Map<String, LanPlayer> players = {};

  Function(List<LanPlayer>)? onPlayersChanged;
  Function(LanRacePhase)? onPhaseChanged;
  Function(List<LanPlayer>)? onRaceComplete;
  Function(String)? onError;

  String? hostIp;
  String? raceText;
  bool isTimedMode = false;
  int timeLimitSeconds = 60;
  int? startAtMs;
  LanRacePhase phase = LanRacePhase.lobby;

  int _heartbeatSeq = 0;
  int _nextPlayerId = 1;

  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  Timer? _raceStartTimer;
  Timer? _raceDeadlineTimer;

  Future<String?> startHosting(String hostName) async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            hostIp = addr.address;
            break;
          }
        }
        if (hostIp != null) break;
      }

      _server = await ServerSocket.bind(InternetAddress.anyIPv4, _kPort);
      _server!.listen(_handleClient);

      players['host'] = LanPlayer(
        id: 'host',
        name: hostName,
        lastSeenMs: _nowMs,
      );
      _notifyPlayersChanged();
      _setPhase(LanRacePhase.lobby);
      _startHeartbeatLoops();
      return hostIp;
    } catch (e) {
      onError?.call('Failed to host: $e');
      return null;
    }
  }

  void _handleClient(Socket client) {
    final socketKey = _socketKey(client);
    _clientSockets[socketKey] = client;

    client
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(
      (line) {
        try {
          final msg = jsonDecode(line) as Map<String, dynamic>;
          _handleMessage(socketKey, msg);
        } catch (_) {}
      },
      onDone: () => _handleSocketClosed(socketKey, 'socket_closed'),
      onError: (_) => _handleSocketClosed(socketKey, 'socket_error'),
      cancelOnError: true,
    );
  }

  void _handleMessage(String socketKey, Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == null) return;

    if (type == LanMessage.joinRequest) {
      _handleJoinRequest(socketKey, msg);
      return;
    }

    final playerId = _socketToPlayer[socketKey];
    if (playerId == null || !players.containsKey(playerId)) return;

    _markSeen(playerId);

    switch (type) {
      case LanMessage.pong:
        _lastPongAtMs[playerId] = _nowMs;
        break;
      case LanMessage.progressUpdate:
        _handleProgressUpdate(playerId, msg);
        break;
      case LanMessage.finished:
        _handleFinished(playerId, msg);
        break;
    }
  }

  void _handleJoinRequest(String socketKey, Map<String, dynamic> msg) {
    final name = (msg['name'] as String?)?.trim();
    final playerName = (name == null || name.isEmpty) ? 'Player' : name;

    if (phase != LanRacePhase.lobby) {
      _sendToSocket(
        socketKey,
        {'type': LanMessage.error, 'message': 'Race already in progress.'},
      );
      return;
    }

    final playerId = 'p${_nextPlayerId++}';
    final now = _nowMs;

    _socketToPlayer[socketKey] = playerId;
    _lastPongAtMs[playerId] = now;

    players[playerId] = LanPlayer(
      id: playerId,
      name: playerName,
      lastSeenMs: now,
    );

    _sendToSocket(socketKey, {
      'type': LanMessage.joinAck,
      'player_id': playerId,
      'server_time_ms': now,
      'phase': phase.wireName,
      'players': _playersJson,
    });

    _broadcast({
      'type': LanMessage.playerList,
      'players': _playersJson,
      'phase': phase.wireName,
    });
    _notifyPlayersChanged();
  }

  void _handleProgressUpdate(String playerId, Map<String, dynamic> msg) {
    if (phase != LanRacePhase.racing && phase != LanRacePhase.countdown) return;
    final p = players[playerId];
    if (p == null || p.finished || p.dnf || p.disconnected) return;

    final progressRaw = msg['progress'];
    final wpmRaw = msg['wpm'];
    final wordsRaw = msg['words_typed'];
    if (progressRaw is! num || wpmRaw is! num || wordsRaw is! num) return;

    final nextProgress = progressRaw.toDouble().clamp(0.0, 1.0);
    final nextWpm = wpmRaw.toInt();
    final nextWords = wordsRaw.toInt();

    final changed = (nextProgress - p.progress).abs() >= 0.005 ||
        (nextWpm - p.wpm).abs() >= 2 ||
        nextWords != p.wordsTyped;
    if (!changed) return;

    p.progress = nextProgress;
    p.wpm = nextWpm;
    p.wordsTyped = nextWords;
    p.lastSeenMs = _nowMs;

    _broadcast({'type': LanMessage.progressUpdate, 'player': p.toJson()});
    _notifyPlayersChanged();
  }

  void _handleFinished(String playerId, Map<String, dynamic> msg) {
    if (phase != LanRacePhase.racing) return;
    final p = players[playerId];
    if (p == null || p.finished || p.dnf) return;

    final finishElapsedMs = (msg['finish_elapsed_ms'] as num?)?.toInt();
    final finishClientTimestampMs =
        (msg['finish_client_timestamp_ms'] as num?)?.toInt();

    p.finished = true;
    p.progress = 1.0;
    p.finishElapsedMs = (finishElapsedMs ?? 0).clamp(0, 1 << 30);
    p.finishClientTimestampMs = finishClientTimestampMs;
    p.finishServerTimestampMs = _nowMs;

    final wpmRaw = msg['wpm'];
    final wordsRaw = msg['words_typed'];
    if (wpmRaw is num) p.wpm = wpmRaw.toInt();
    if (wordsRaw is num) p.wordsTyped = wordsRaw.toInt();

    _broadcast({'type': LanMessage.progressUpdate, 'player': p.toJson()});
    _notifyPlayersChanged();
    _maybeCompleteRace();
  }

  bool startRace(
    String text, {
    bool timedMode = false,
    int timeLimitSecs = 60,
  }) {
    if (phase != LanRacePhase.lobby) return false;

    raceText = text;
    isTimedMode = timedMode;
    timeLimitSeconds = timeLimitSecs;

    _raceParticipants
      ..clear()
      ..addAll(players.values
          .where((p) => !p.disconnected)
          .map((p) => p.id));

    final now = _nowMs;
    startAtMs = now + _kStartLeadTime.inMilliseconds;

    for (final p in players.values) {
      p.progress = 0;
      p.wpm = 0;
      p.wordsTyped = 0;
      p.finished = false;
      p.rank = null;
      p.finishElapsedMs = null;
      p.finishClientTimestampMs = null;
      p.finishServerTimestampMs = null;
      p.dnf = !_raceParticipants.contains(p.id);
    }

    _setPhase(LanRacePhase.countdown);
    _broadcast({
      'type': LanMessage.startRace,
      'text': text,
      'timed_mode': timedMode,
      'time_limit_seconds': timeLimitSecs,
      'start_at_ms': startAtMs,
      'phase': phase.wireName,
    });
    _notifyPlayersChanged();

    _raceStartTimer?.cancel();
    _raceStartTimer = Timer(_kStartLeadTime, () {
      if (phase != LanRacePhase.countdown) return;
      _setPhase(LanRacePhase.racing);
      _broadcast({
        'type': LanMessage.phaseUpdate,
        'phase': phase.wireName,
      });

      if (isTimedMode) {
        _raceDeadlineTimer?.cancel();
        _raceDeadlineTimer = Timer(Duration(seconds: timeLimitSeconds), () {
          if (phase == LanRacePhase.racing) {
            _finalizeRace();
          }
        });
      }
    });

    return true;
  }

  void updateHostProgress(double progress, int wpm, {int wordsTyped = 0}) {
    if (!players.containsKey('host')) return;
    _handleProgressUpdate('host', {
      'type': LanMessage.progressUpdate,
      'progress': progress,
      'wpm': wpm,
      'words_typed': wordsTyped,
    });
  }

  void hostFinished({required int finishElapsedMs, required int finishClientTimestampMs, required int wpm, required int wordsTyped}) {
    _handleFinished('host', {
      'type': LanMessage.finished,
      'finish_elapsed_ms': finishElapsedMs,
      'finish_client_timestamp_ms': finishClientTimestampMs,
      'wpm': wpm,
      'words_typed': wordsTyped,
    });
  }

  void _startHeartbeatLoops() {
    _heartbeatTimer?.cancel();
    _timeoutTimer?.cancel();

    _heartbeatTimer = Timer.periodic(_kHeartbeatInterval, (_) {
      _heartbeatSeq += 1;
      _broadcast({
        'type': LanMessage.ping,
        'seq': _heartbeatSeq,
        'server_time_ms': _nowMs,
      });
    });

    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = _nowMs;
      final timeoutMs = _kHeartbeatTimeout.inMilliseconds;

      for (final p in players.values.where((e) => e.id != 'host').toList()) {
        if (p.disconnected) continue;
        final lastPong = _lastPongAtMs[p.id] ?? 0;
        if (now - lastPong > timeoutMs) {
          _markDisconnected(p.id, reason: 'heartbeat_timeout');
        }
      }
    });
  }

  void _markDisconnected(String playerId, {required String reason}) {
    final p = players[playerId];
    if (p == null || p.disconnected) return;

    p.disconnected = true;
    p.lastSeenMs = _nowMs;

    if (phase == LanRacePhase.lobby) {
      players.remove(playerId);
      _lastPongAtMs.remove(playerId);
      _raceParticipants.remove(playerId);
      _notifyPlayersChanged();
      _broadcast({
        'type': LanMessage.playerList,
        'players': _playersJson,
        'phase': phase.wireName,
      });
      return;
    }

    if (_raceParticipants.contains(playerId) && !p.finished) {
      p.dnf = true;
      p.rank = null;
    }

    _broadcast({
      'type': LanMessage.playerDisconnect,
      'player_id': playerId,
      'reason': reason,
      'player': p.toJson(),
    });
    _notifyPlayersChanged();
    _maybeCompleteRace();
  }

  void _handleSocketClosed(String socketKey, String reason) {
    final socket = _clientSockets.remove(socketKey);
    try {
      socket?.destroy();
    } catch (_) {}

    final playerId = _socketToPlayer.remove(socketKey);
    if (playerId != null) {
      _markDisconnected(playerId, reason: reason);
    }
  }

  void _maybeCompleteRace() {
    if (phase != LanRacePhase.racing) return;
    if (isTimedMode) return;

    final done = _raceParticipants.every((id) {
      final p = players[id];
      if (p == null) return true;
      return p.finished || p.dnf;
    });

    if (done) {
      _finalizeRace();
    }
  }

  void _finalizeRace() {
    if (phase == LanRacePhase.results) return;

    if (isTimedMode) {
      final ranked = _rankTimed(players.values.where((p) => _raceParticipants.contains(p.id)).toList());
      _assignRanks(ranked);
    } else {
      final finishers = players.values
          .where((p) => _raceParticipants.contains(p.id) && p.finished && !p.dnf)
          .toList();
      finishers.sort((a, b) {
        final ea = a.finishElapsedMs ?? 1 << 30;
        final eb = b.finishElapsedMs ?? 1 << 30;
        if (ea != eb) return ea.compareTo(eb);
        final sa = a.finishServerTimestampMs ?? 1 << 30;
        final sb = b.finishServerTimestampMs ?? 1 << 30;
        if (sa != sb) return sa.compareTo(sb);
        return a.id.compareTo(b.id);
      });
      _assignRanks(finishers);
    }

    _setPhase(LanRacePhase.results);
    final resultPlayers = players.values
        .where((p) => _raceParticipants.contains(p.id))
        .toList();

    _broadcast({
      'type': LanMessage.raceComplete,
      'phase': phase.wireName,
      'players': resultPlayers.map((p) => p.toJson()).toList(),
      'timed_mode': isTimedMode,
      'start_at_ms': startAtMs,
      'server_time_ms': _nowMs,
    });
    _notifyPlayersChanged();
    onRaceComplete?.call(resultPlayers);
  }

  List<LanPlayer> _rankTimed(List<LanPlayer> entries) {
    entries.sort((a, b) {
      if (a.wordsTyped != b.wordsTyped) {
        return b.wordsTyped.compareTo(a.wordsTyped);
      }
      if (a.wpm != b.wpm) {
        return b.wpm.compareTo(a.wpm);
      }
      return a.id.compareTo(b.id);
    });
    return entries;
  }

  void _assignRanks(List<LanPlayer> ranked) {
    var rank = 1;
    for (final p in ranked) {
      p.rank = rank;
      rank += 1;
    }
  }

  void _setPhase(LanRacePhase next) {
    phase = next;
    onPhaseChanged?.call(phase);
  }

  void _sendToSocket(String socketKey, Map<String, dynamic> data) {
    final socket = _clientSockets[socketKey];
    if (socket == null) return;
    try {
      socket.write('${jsonEncode(data)}\n');
    } catch (_) {}
  }

  void _broadcast(Map<String, dynamic> data) {
    final msg = '${jsonEncode(data)}\n';
    for (final socket in _clientSockets.values.toList()) {
      try {
        socket.write(msg);
      } catch (_) {}
    }
  }

  void _markSeen(String playerId) {
    final now = _nowMs;
    _lastPongAtMs[playerId] = now;
    final player = players[playerId];
    if (player != null) {
      player.lastSeenMs = now;
    }
  }

  void _notifyPlayersChanged() {
    onPlayersChanged?.call(players.values.toList());
  }

  List<Map<String, dynamic>> get _playersJson =>
      players.values.map((p) => p.toJson()).toList();

  int get _nowMs => DateTime.now().millisecondsSinceEpoch;

  String _socketKey(Socket socket) =>
      '${socket.remoteAddress.address}:${socket.remotePort}';

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _timeoutTimer?.cancel();
    _raceStartTimer?.cancel();
    _raceDeadlineTimer?.cancel();

    for (final socket in _clientSockets.values.toList()) {
      try {
        await socket.close();
      } catch (_) {}
    }

    _clientSockets.clear();
    _socketToPlayer.clear();
    _lastPongAtMs.clear();
    _raceParticipants.clear();
    players.clear();

    try {
      await _server?.close();
    } catch (_) {}
  }
}

class LanClientService {
  Socket? _socket;
  final Map<String, LanPlayer> _players = {};

  Function(List<LanPlayer>)? onPlayersChanged;
  Function(String text, bool timedMode, int timeLimitSeconds, int startAtMs)?
      onGameStart;
  Function(LanRacePhase)? onPhaseChanged;
  Function(List<LanPlayer>)? onRaceComplete;
  Function(String playerId)? onPlayerDisconnected;
  Function(String)? onError;

  String? playerId;
  LanRacePhase phase = LanRacePhase.lobby;

  int _lastProgressSentAtMs = 0;
  double _lastSentProgress = 0;
  int _lastSentWpm = 0;
  int _lastSentWords = 0;

  Future<bool> connect(String hostIp, String playerName) async {
    try {
      _socket = await Socket.connect(
        hostIp,
        _kPort,
        timeout: const Duration(seconds: 5),
      );

      _socket!
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen(
        (line) {
          try {
            final msg = jsonDecode(line) as Map<String, dynamic>;
            _handleMessage(msg);
          } catch (_) {}
        },
        onDone: () => onError?.call('Disconnected from host.'),
        onError: (_) => onError?.call('Connection error.'),
        cancelOnError: true,
      );

      _send({'type': LanMessage.joinRequest, 'name': playerName});
      return true;
    } catch (_) {
      onError?.call('Could not connect to $hostIp.');
      return false;
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == null) return;

    switch (type) {
      case LanMessage.joinAck:
        playerId = msg['player_id'] as String?;
        final phaseName = msg['phase'] as String?;
        if (phaseName != null) {
          phase = LanRacePhaseExt.fromWireName(phaseName);
          onPhaseChanged?.call(phase);
        }
        _replacePlayers(msg['players']);
        break;

      case LanMessage.playerList:
        final phaseName = msg['phase'] as String?;
        if (phaseName != null) {
          phase = LanRacePhaseExt.fromWireName(phaseName);
          onPhaseChanged?.call(phase);
        }
        _replacePlayers(msg['players']);
        break;

      case LanMessage.startRace:
        final text = msg['text'] as String?;
        final timedMode = msg['timed_mode'] as bool? ?? false;
        final timeLimit = (msg['time_limit_seconds'] as num?)?.toInt() ?? 60;
        final startAt = (msg['start_at_ms'] as num?)?.toInt();
        final phaseName = msg['phase'] as String?;

        if (phaseName != null) {
          phase = LanRacePhaseExt.fromWireName(phaseName);
          onPhaseChanged?.call(phase);
        }

        if (text != null && startAt != null) {
          onGameStart?.call(text, timedMode, timeLimit, startAt);
        }
        break;

      case LanMessage.phaseUpdate:
        final phaseName = msg['phase'] as String?;
        if (phaseName != null) {
          phase = LanRacePhaseExt.fromWireName(phaseName);
          onPhaseChanged?.call(phase);
        }
        break;

      case LanMessage.progressUpdate:
        final payload = msg['player'];
        if (payload is Map<String, dynamic>) {
          final next = LanPlayer.fromJson(payload);
          _players[next.id] = next;
          _notifyPlayers();
        }
        break;

      case LanMessage.playerDisconnect:
        final disconnectedId = msg['player_id'] as String?;
        final playerPayload = msg['player'];

        if (playerPayload is Map<String, dynamic>) {
          final next = LanPlayer.fromJson(playerPayload);
          _players[next.id] = next;
        }

        if (disconnectedId != null) {
          onPlayerDisconnected?.call(disconnectedId);
        }
        _notifyPlayers();
        break;

      case LanMessage.raceComplete:
        phase = LanRacePhase.results;
        onPhaseChanged?.call(phase);
        _replacePlayers(msg['players']);
        onRaceComplete?.call(_players.values.toList());
        break;

      case LanMessage.ping:
        _send({
          'type': LanMessage.pong,
          'seq': msg['seq'],
          'client_time_ms': DateTime.now().millisecondsSinceEpoch,
        });
        break;

      case LanMessage.error:
        final message = msg['message'] as String? ?? 'Server error.';
        onError?.call(message);
        break;
    }
  }

  void sendProgress(double progress, int wpm, {int wordsTyped = 0, bool force = false}) {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (!force) {
      final enoughTimePassed = now - _lastProgressSentAtMs >= 250;
      final meaningfulDelta =
          (progress - _lastSentProgress).abs() >= 0.01 ||
          (wpm - _lastSentWpm).abs() >= 2 ||
          wordsTyped != _lastSentWords;
      if (!enoughTimePassed || !meaningfulDelta) return;
    }

    _lastProgressSentAtMs = now;
    _lastSentProgress = progress;
    _lastSentWpm = wpm;
    _lastSentWords = wordsTyped;

    _send({
      'type': LanMessage.progressUpdate,
      'progress': progress.clamp(0.0, 1.0),
      'wpm': wpm,
      'words_typed': wordsTyped,
      'client_time_ms': now,
    });
  }

  void sendFinished({
    required int finishClientTimestampMs,
    required int finishElapsedMs,
    required int wpm,
    required int wordsTyped,
  }) {
    _send({
      'type': LanMessage.finished,
      'finish_client_timestamp_ms': finishClientTimestampMs,
      'finish_elapsed_ms': finishElapsedMs,
      'wpm': wpm,
      'words_typed': wordsTyped,
    });
  }

  void _replacePlayers(dynamic payload) {
    _players.clear();
    if (payload is List) {
      for (final item in payload) {
        if (item is Map<String, dynamic>) {
          final p = LanPlayer.fromJson(item);
          _players[p.id] = p;
        }
      }
    }
    _notifyPlayers();
  }

  void _notifyPlayers() {
    onPlayersChanged?.call(_players.values.toList());
  }

  void _send(Map<String, dynamic> data) {
    try {
      _socket?.write('${jsonEncode(data)}\n');
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    _players.clear();
  }
}
