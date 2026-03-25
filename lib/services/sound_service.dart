import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generates and plays simple WAV tones with no external assets.
///
/// All tones are synthesised ONCE at [init] time and stored as [Uint8List]
/// fields. This means [playKeyClick] (called on every keystroke) never blocks
/// the UI thread with audio maths — it only hands pre-built bytes to the
/// audio player.
class SoundService {
  static final SoundService _i = SoundService._();
  factory SoundService() => _i;
  SoundService._();

  // ── Audio players (separate so sounds can overlap) ────────────────────
  final AudioPlayer _keyPlayer     = AudioPlayer();
  final AudioPlayer _errorPlayer   = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _levelPlayer   = AudioPlayer();

  bool _enabled = true;
  bool get enabled => _enabled;

  // Cached SharedPreferences — obtained once in init(), reused in setEnabled().
  SharedPreferences? _prefs;

  // ── Pre-built tone buffers (set in init, never regenerated) ───────────
  late final Uint8List _keyClickWav;
  late final Uint8List _errorWav;
  late final Uint8List _streakWav;
  late final Uint8List _achievementWav;
  // Level complete is 3 notes; pre-build all three.
  late final Uint8List _levelNoteC;
  late final Uint8List _levelNoteE;
  late final Uint8List _levelNoteG;

  // ── Init ──────────────────────────────────────────────────────────────
  Future<void> init() async {
    _prefs  = await SharedPreferences.getInstance();
    _enabled = _prefs!.getBool('sound_enabled') ?? true;

    // Low latency for key clicks.
    await _keyPlayer.setReleaseMode(ReleaseMode.stop);
    await _errorPlayer.setReleaseMode(ReleaseMode.stop);
    await _successPlayer.setReleaseMode(ReleaseMode.stop);
    await _levelPlayer.setReleaseMode(ReleaseMode.stop);

    // Synthesise all tones once here so playX() methods never block.
    _keyClickWav   = _makeTone(freq: 800,  durationMs: 30,  volume: 0.12, waveform: 'click', fadeOutFraction: 0.5);
    _errorWav      = _makeTone(freq: 180,  durationMs: 100, volume: 0.30, waveform: 'buzz',  fadeOutFraction: 0.4);
    _streakWav     = _makeTone(freq: 1200, durationMs: 80,  volume: 0.20, waveform: 'sine',  fadeOutFraction: 0.5);
    _achievementWav= _makeTone(freq: 1047, durationMs: 250, volume: 0.30, waveform: 'sine',  fadeOutFraction: 0.4);
    _levelNoteC    = _makeTone(freq: 523,  durationMs: 120, volume: 0.35, fadeOutFraction: 0.3);
    _levelNoteE    = _makeTone(freq: 659,  durationMs: 120, volume: 0.35, fadeOutFraction: 0.3);
    _levelNoteG    = _makeTone(freq: 784,  durationMs: 220, volume: 0.35, fadeOutFraction: 0.5);
  }

  // ── Settings ──────────────────────────────────────────────────────────
  Future<void> setEnabled(bool val) async {
    _enabled = val;
    // Reuse the cached prefs instance — no second getInstance() call.
    await _prefs?.setBool('sound_enabled', val);
  }

  // ── Public play API ───────────────────────────────────────────────────

  Future<void> playKeyClick() async {
    if (!_enabled) return;
    try {
      await _keyPlayer.play(BytesSource(_keyClickWav), volume: 0.4);
    } catch (_) {}
  }

  Future<void> playError() async {
    if (!_enabled) return;
    try {
      await _errorPlayer.play(BytesSource(_errorWav), volume: 0.6);
    } catch (_) {}
  }

  Future<void> playStreak() async {
    if (!_enabled) return;
    try {
      await _successPlayer.play(BytesSource(_streakWav), volume: 0.5);
    } catch (_) {}
  }

  Future<void> playLevelComplete() async {
    if (!_enabled) return;
    try {
      // Ascending arpeggio — C · E · G played sequentially.
      await _levelPlayer.play(BytesSource(_levelNoteC), volume: 0.7);
      await Future.delayed(const Duration(milliseconds: 120));
      await _levelPlayer.play(BytesSource(_levelNoteE), volume: 0.7);
      await Future.delayed(const Duration(milliseconds: 120));
      await _levelPlayer.play(BytesSource(_levelNoteG), volume: 0.7);
    } catch (_) {}
  }

  Future<void> playAchievement() async {
    if (!_enabled) return;
    try {
      await _successPlayer.play(BytesSource(_achievementWav), volume: 0.7);
    } catch (_) {}
  }

  // ── Dispose ───────────────────────────────────────────────────────────
  Future<void> dispose() async {
    await _keyPlayer.dispose();
    await _errorPlayer.dispose();
    await _successPlayer.dispose();
    await _levelPlayer.dispose();
  }

  // ── PCM tone generator (called only from init) ────────────────────────
  Uint8List _makeTone({
    required double freq,
    required double durationMs,
    required double volume,          // 0.0 – 1.0
    double fadeOutFraction = 0.3,
    String waveform = 'sine',        // 'sine' | 'click' | 'buzz'
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final samples    = Int16List(numSamples);
    final maxAmp     = (32767 * volume).round();
    final fadeStart  = (numSamples * (1 - fadeOutFraction)).round();

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      double sample;

      if (waveform == 'click') {
        sample = math.sin(2 * math.pi * freq * t) * math.exp(-t * 50);
      } else if (waveform == 'buzz') {
        sample = math.sin(2 * math.pi * freq * t) > 0 ? 1.0 : -1.0;
      } else {
        sample = math.sin(2 * math.pi * freq * t);
      }

      double env = 1.0;
      if (i > fadeStart) {
        env = 1.0 - (i - fadeStart) / (numSamples - fadeStart);
      }

      samples[i] = (sample * maxAmp * env).round().clamp(-32768, 32767);
    }

    return _wavBytes(samples, sampleRate);
  }

  Uint8List _wavBytes(Int16List samples, int sampleRate) {
    final dataLength = samples.length * 2;
    final buffer     = ByteData(44 + dataLength);

    // RIFF header
    buffer.setUint8(0, 0x52); buffer.setUint8(1, 0x49);
    buffer.setUint8(2, 0x46); buffer.setUint8(3, 0x46);
    buffer.setUint32(4, 36 + dataLength, Endian.little);
    buffer.setUint8(8, 0x57); buffer.setUint8(9, 0x41);
    buffer.setUint8(10, 0x56); buffer.setUint8(11, 0x45);

    // fmt chunk
    buffer.setUint8(12, 0x66); buffer.setUint8(13, 0x6D);
    buffer.setUint8(14, 0x74); buffer.setUint8(15, 0x20);
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1,          Endian.little); // PCM
    buffer.setUint16(22, 1,          Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2,          Endian.little);
    buffer.setUint16(34, 16,         Endian.little);

    // data chunk
    buffer.setUint8(36, 0x64); buffer.setUint8(37, 0x61);
    buffer.setUint8(38, 0x74); buffer.setUint8(39, 0x61);
    buffer.setUint32(40, dataLength, Endian.little);
    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}