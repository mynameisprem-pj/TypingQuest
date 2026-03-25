import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Finger assignment for each key ────────────────────────────────────────
enum Finger {
  leftPinky,
  leftRing,
  leftMiddle,
  leftIndex,
  thumb,
  rightIndex,
  rightMiddle,
  rightRing,
  rightPinky,
}

extension FingerColor on Finger {
  Color get color {
    switch (this) {
      case Finger.leftPinky:    return AppTheme.fingerPinky;
      case Finger.leftRing:     return AppTheme.fingerRing;
      case Finger.leftMiddle:   return AppTheme.fingerMiddle;
      case Finger.leftIndex:    return AppTheme.fingerIndex;
      case Finger.thumb:        return AppTheme.fingerThumb;
      case Finger.rightIndex:   return AppTheme.fingerIndex;
      case Finger.rightMiddle:  return AppTheme.fingerMiddle;
      case Finger.rightRing:    return AppTheme.fingerRing;
      case Finger.rightPinky:   return AppTheme.fingerPinky;
    }
  }
}

extension FingerTeaching on Finger {
  String get label {
    switch (this) {
      case Finger.leftPinky:    return 'Left pinky';
      case Finger.leftRing:     return 'Left ring';
      case Finger.leftMiddle:   return 'Left middle';
      case Finger.leftIndex:    return 'Left index';
      case Finger.thumb:        return 'Thumb';
      case Finger.rightIndex:   return 'Right index';
      case Finger.rightMiddle:  return 'Right middle';
      case Finger.rightRing:    return 'Right ring';
      case Finger.rightPinky:   return 'Right pinky';
    }
  }

  String get homeKey {
    switch (this) {
      case Finger.leftPinky:    return 'A';
      case Finger.leftRing:     return 'S';
      case Finger.leftMiddle:   return 'D';
      case Finger.leftIndex:    return 'F';
      case Finger.thumb:        return 'Space';
      case Finger.rightIndex:   return 'J';
      case Finger.rightMiddle:  return 'K';
      case Finger.rightRing:    return 'L';
      case Finger.rightPinky:   return ';';
    }
  }
}

// ── Key definitions ───────────────────────────────────────────────────────
class KeyDef {
  final String label;
  final String value;       // lowercase value
  final Finger finger;
  final double widthFactor; // relative to normal key width

  const KeyDef(this.label, this.value, this.finger, {this.widthFactor = 1.0});
}

// ── Keyboard layout ───────────────────────────────────────────────────────
const List<List<KeyDef>> _kRows = [
  // Number row
  [
    KeyDef('`',    '`',         Finger.leftPinky),
    KeyDef('1',    '1',         Finger.leftPinky),
    KeyDef('2',    '2',         Finger.leftRing),
    KeyDef('3',    '3',         Finger.leftMiddle),
    KeyDef('4',    '4',         Finger.leftIndex),
    KeyDef('5',    '5',         Finger.leftIndex),
    KeyDef('6',    '6',         Finger.rightIndex),
    KeyDef('7',    '7',         Finger.rightIndex),
    KeyDef('8',    '8',         Finger.rightMiddle),
    KeyDef('9',    '9',         Finger.rightRing),
    KeyDef('0',    '0',         Finger.rightPinky),
    KeyDef('-',    '-',         Finger.rightPinky),
    KeyDef('=',    '=',         Finger.rightPinky),
    KeyDef('⌫',   'backspace', Finger.rightPinky, widthFactor: 1.8),
  ],
  // QWERTY row
  [
    KeyDef('Tab',  'tab',       Finger.leftPinky,  widthFactor: 1.4),
    KeyDef('Q',    'q',         Finger.leftPinky),
    KeyDef('W',    'w',         Finger.leftRing),
    KeyDef('E',    'e',         Finger.leftMiddle),
    KeyDef('R',    'r',         Finger.leftIndex),
    KeyDef('T',    't',         Finger.leftIndex),
    KeyDef('Y',    'y',         Finger.rightIndex),
    KeyDef('U',    'u',         Finger.rightIndex),
    KeyDef('I',    'i',         Finger.rightMiddle),
    KeyDef('O',    'o',         Finger.rightRing),
    KeyDef('P',    'p',         Finger.rightPinky),
    KeyDef('[',    '[',         Finger.rightPinky),
    KeyDef(']',    ']',         Finger.rightPinky),
    KeyDef('\\',   '\\',        Finger.rightPinky, widthFactor: 1.4),
  ],
  // Home row
  [
    KeyDef('Caps', 'caps',      Finger.leftPinky,  widthFactor: 1.7),
    KeyDef('A',    'a',         Finger.leftPinky),
    KeyDef('S',    's',         Finger.leftRing),
    KeyDef('D',    'd',         Finger.leftMiddle),
    KeyDef('F',    'f',         Finger.leftIndex),
    KeyDef('G',    'g',         Finger.leftIndex),
    KeyDef('H',    'h',         Finger.rightIndex),
    KeyDef('J',    'j',         Finger.rightIndex),
    KeyDef('K',    'k',         Finger.rightMiddle),
    KeyDef('L',    'l',         Finger.rightRing),
    KeyDef(';',    ';',         Finger.rightPinky),
    KeyDef("'",    "'",         Finger.rightPinky),
    KeyDef('Enter','enter',     Finger.rightPinky, widthFactor: 2.2),
  ],
  // Bottom row
  [
    KeyDef('Shift','shift',     Finger.leftPinky,  widthFactor: 2.4),
    KeyDef('Z',    'z',         Finger.leftPinky),
    KeyDef('X',    'x',         Finger.leftRing),
    KeyDef('C',    'c',         Finger.leftMiddle),
    KeyDef('V',    'v',         Finger.leftIndex),
    KeyDef('B',    'b',         Finger.leftIndex),
    KeyDef('N',    'n',         Finger.rightIndex),
    KeyDef('M',    'm',         Finger.rightIndex),
    KeyDef(',',    ',',         Finger.rightMiddle),
    KeyDef('.',    '.',         Finger.rightRing),
    KeyDef('/',    '/',         Finger.rightPinky),
    KeyDef('Shift','rshift',    Finger.rightPinky, widthFactor: 2.9),
  ],
];

// ── Platform guard ─────────────────────────────────────────────────────────
// The virtual keyboard guide is only meaningful to physical-keyboard users.
// Touch-only devices (Android / iOS) cannot play the game and should not see
// this widget. Desktop and Web always show it.
bool get _isTouchOnlyPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
     defaultTargetPlatform == TargetPlatform.iOS);

// ── Virtual Keyboard Widget ───────────────────────────────────────────────
class VirtualKeyboard extends StatelessWidget {
  /// The character that should be highlighted as "press this next".
  final String? highlightChar;

  /// Whether the last keypress was wrong (shows red on highlighted key).
  final bool wasWrong;

  /// Show finger colour coding on all keys.
  final bool showFingerColors;

  /// Show hand placement guide and active finger hint.
  final bool showHandGuide;

  const VirtualKeyboard({
    super.key,
    this.highlightChar,
    this.wasWrong = false,
    this.showFingerColors = true,
    this.showHandGuide = false,
  });

  String _normalize(String? c) => c == null ? '' : c.toLowerCase();

  @override
  Widget build(BuildContext context) {
    // Do not render on touch-only platforms — physical keyboard is required.
    if (_isTouchOnlyPlatform) return const SizedBox.shrink();

    final target       = _normalize(highlightChar);
    final targetFinger = _fingerForKey(target);

    // RepaintBoundary isolates this widget's repaints from the rest of the
    // game UI, avoiding unnecessary parent redraws on low-end hardware.
    return IgnorePointer(
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.cardBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFingerColors) _buildLegend(),
              if (showHandGuide) ...[
                const SizedBox(height: 6),
                _buildHandGuide(target, targetFinger),
              ],
              const SizedBox(height: 6),
              ..._kRows.map((row) => _buildRow(row, target)),
              _buildSpaceBar(target),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Finger? _fingerForKey(String keyValue) {
    if (keyValue.isEmpty) return null;
    if (keyValue == ' ') return Finger.thumb;
    for (final row in _kRows) {
      for (final key in row) {
        if (key.value == keyValue) return key.finger;
      }
    }
    return null;
  }

  String _targetLabel(String target) {
    if (target == ' ') return 'SPACE';
    if (target.isEmpty) return '';
    return target.toUpperCase();
  }

  // ── Legend ────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    const items = [
      ('Pinky',  AppTheme.fingerPinky),
      ('Ring',   AppTheme.fingerRing),
      ('Middle', AppTheme.fingerMiddle),
      ('Index',  AppTheme.fingerIndex),
      ('Thumb',  AppTheme.fingerThumb),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: item.$2, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(item.$1, style: AppTheme.body(10, color: AppTheme.textSecondary)),
                ]),
              ))
          .toList(),
    );
  }

  // ── Hand guide ────────────────────────────────────────────────────────────

  Widget _buildHandGuide(String target, Finger? targetFinger) {
    const leftHand  = [Finger.leftPinky, Finger.leftRing, Finger.leftMiddle, Finger.leftIndex];
    const rightHand = [Finger.rightIndex, Finger.rightMiddle, Finger.rightRing, Finger.rightPinky];

    final instruction = targetFinger == null
        ? 'Home row: left hand A S D F, right hand J K L ;, thumbs on space.'
        : '${targetFinger.label} on ${targetFinger.homeKey} -> press ${_targetLabel(target)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Text(instruction, style: AppTheme.body(11, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...leftHand.map((f) => _buildFingerDot(f, targetFinger == f)),
              const SizedBox(width: 22),
              _buildFingerDot(Finger.thumb, targetFinger == Finger.thumb),
              const SizedBox(width: 22),
              ...rightHand.map((f) => _buildFingerDot(f, targetFinger == f)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFingerDot(Finger finger, bool active) {
    final color = finger.color;
    // AnimatedContainer is fine here — there are only ~9 finger dots total.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width:  active ? 22 : 18,
        height: active ? 22 : 18,
        decoration: BoxDecoration(
          color:  active ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.35),
          shape:  BoxShape.circle,
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.5),
            width: active ? 2 : 1,
          ),
          // Glow only on the active finger; shadow is expensive, skip it elsewhere.
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.40), blurRadius: 6)]
              : null,
        ),
      ),
    );
  }

  // ── Keyboard rows ─────────────────────────────────────────────────────────

  Widget _buildRow(List<KeyDef> keys, String target) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        // Build each key; non-target keys are plain Containers (no animation).
        children: keys.map((key) => _buildKey(key, target)).toList(),
      ),
    );
  }

  Widget _buildKey(KeyDef key, String target) {
    final isTarget = target.isNotEmpty && key.value == target;

    // ── Target key — animated so the highlight pops in smoothly ──────────
    if (isTarget) {
      final Color bg, border, textColor;
      if (wasWrong) {
        bg        = const Color(0x4DFF6B6B); // error 30 %
        border    = AppTheme.error;
        textColor = AppTheme.error;
      } else {
        bg        = const Color(0x405C7CFA); // primary 25 %
        border    = AppTheme.primary;
        textColor = AppTheme.primary;
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width:  36 * key.widthFactor,
        height: 34,
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(5),
          border:       Border.all(color: border, width: 1.5),
          // Single, lightweight shadow only on the highlighted key.
          boxShadow: [BoxShadow(color: border.withValues(alpha: 0.35), blurRadius: 5)],
        ),
        child: Center(
          child: Text(
            key.label,
            style:     AppTheme.mono(12, color: textColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ── Normal key — plain Container, zero animation overhead ─────────────
    final Color baseColor  = showFingerColors
        ? key.finger.color.withValues(alpha: 0.15)
        : AppTheme.card;
    final Color borderColor = showFingerColors
        ? key.finger.color.withValues(alpha: 0.40)
        : AppTheme.cardBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width:  36 * key.widthFactor,
      height: 34,
      decoration: BoxDecoration(
        color:        baseColor,
        borderRadius: BorderRadius.circular(5),
        border:       Border.all(color: borderColor),
        // No shadow on idle keys — saves a lot of paint work across 60+ keys.
      ),
      child: Center(
        child: Text(
          key.label,
          style:     AppTheme.mono(10, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ── Space bar ─────────────────────────────────────────────────────────────

  Widget _buildSpaceBar(String target) {
    final isTarget = target == ' ';

    if (isTarget) {
      final borderColor = wasWrong ? AppTheme.error : AppTheme.primary;
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 320,
          height: 34,
          decoration: BoxDecoration(
            color: wasWrong
                ? AppTheme.fingerThumb.withValues(alpha: 0.10)
                : AppTheme.fingerThumb.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 5)],
          ),
          child: Center(
            child: Text(
              'SPACE',
              style: AppTheme.mono(10, color: AppTheme.primary),
            ),
          ),
        ),
      );
    }

    // Idle space bar — plain Container, no animation.
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Container(
        width: 320,
        height: 34,
        decoration: BoxDecoration(
          color:        AppTheme.fingerThumb.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(5),
          border:       Border.all(color: AppTheme.fingerThumb.withValues(alpha: 0.30)),
        ),
        child: Center(
          child: Text(
            'SPACE',
            style: AppTheme.mono(10, color: AppTheme.textMuted),
          ),
        ),
      ),
    );
  }
}
