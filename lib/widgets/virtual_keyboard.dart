import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Finger assignment for each key ────────────────────────────────────────
enum Finger { leftPinky, leftRing, leftMiddle, leftIndex, thumb, rightIndex, rightMiddle, rightRing, rightPinky }

extension FingerColor on Finger {
  Color get color {
    switch (this) {
      case Finger.leftPinky:   return AppTheme.fingerPinky;
      case Finger.leftRing:    return AppTheme.fingerRing;
      case Finger.leftMiddle:  return AppTheme.fingerMiddle;
      case Finger.leftIndex:   return AppTheme.fingerIndex;
      case Finger.thumb:       return AppTheme.fingerThumb;
      case Finger.rightIndex:  return AppTheme.fingerIndex;
      case Finger.rightMiddle: return AppTheme.fingerMiddle;
      case Finger.rightRing:   return AppTheme.fingerRing;
      case Finger.rightPinky:  return AppTheme.fingerPinky;
    }
  }
}

extension FingerTeaching on Finger {
  String get label {
    switch (this) {
      case Finger.leftPinky: return 'Left pinky';
      case Finger.leftRing: return 'Left ring';
      case Finger.leftMiddle: return 'Left middle';
      case Finger.leftIndex: return 'Left index';
      case Finger.thumb: return 'Thumb';
      case Finger.rightIndex: return 'Right index';
      case Finger.rightMiddle: return 'Right middle';
      case Finger.rightRing: return 'Right ring';
      case Finger.rightPinky: return 'Right pinky';
    }
  }

  String get homeKey {
    switch (this) {
      case Finger.leftPinky: return 'A';
      case Finger.leftRing: return 'S';
      case Finger.leftMiddle: return 'D';
      case Finger.leftIndex: return 'F';
      case Finger.thumb: return 'Space';
      case Finger.rightIndex: return 'J';
      case Finger.rightMiddle: return 'K';
      case Finger.rightRing: return 'L';
      case Finger.rightPinky: return ';';
    }
  }
}

// ── Key definitions ───────────────────────────────────────────────────────
class KeyDef {
  final String label;
  final String value; // lowercase value
  final Finger finger;
  final double widthFactor; // relative to normal key width

  const KeyDef(this.label, this.value, this.finger, {this.widthFactor = 1.0});
}

// ── Keyboard layout ───────────────────────────────────────────────────────
const List<List<KeyDef>> _kRows = [
  // Number row
  [
    KeyDef('`', '`', Finger.leftPinky),
    KeyDef('1', '1', Finger.leftPinky),
    KeyDef('2', '2', Finger.leftRing),
    KeyDef('3', '3', Finger.leftMiddle),
    KeyDef('4', '4', Finger.leftIndex),
    KeyDef('5', '5', Finger.leftIndex),
    KeyDef('6', '6', Finger.rightIndex),
    KeyDef('7', '7', Finger.rightIndex),
    KeyDef('8', '8', Finger.rightMiddle),
    KeyDef('9', '9', Finger.rightRing),
    KeyDef('0', '0', Finger.rightPinky),
    KeyDef('-', '-', Finger.rightPinky),
    KeyDef('=', '=', Finger.rightPinky),
    KeyDef('⌫', 'backspace', Finger.rightPinky, widthFactor: 1.8),
  ],
  // QWERTY row
  [
    KeyDef('Tab', 'tab', Finger.leftPinky, widthFactor: 1.4),
    KeyDef('Q', 'q', Finger.leftPinky),
    KeyDef('W', 'w', Finger.leftRing),
    KeyDef('E', 'e', Finger.leftMiddle),
    KeyDef('R', 'r', Finger.leftIndex),
    KeyDef('T', 't', Finger.leftIndex),
    KeyDef('Y', 'y', Finger.rightIndex),
    KeyDef('U', 'u', Finger.rightIndex),
    KeyDef('I', 'i', Finger.rightMiddle),
    KeyDef('O', 'o', Finger.rightRing),
    KeyDef('P', 'p', Finger.rightPinky),
    KeyDef('[', '[', Finger.rightPinky),
    KeyDef(']', ']', Finger.rightPinky),
    KeyDef('\\', '\\', Finger.rightPinky, widthFactor: 1.4),
  ],
  // Home row
  [
    KeyDef('Caps', 'caps', Finger.leftPinky, widthFactor: 1.7),
    KeyDef('A', 'a', Finger.leftPinky),
    KeyDef('S', 's', Finger.leftRing),
    KeyDef('D', 'd', Finger.leftMiddle),
    KeyDef('F', 'f', Finger.leftIndex),
    KeyDef('G', 'g', Finger.leftIndex),
    KeyDef('H', 'h', Finger.rightIndex),
    KeyDef('J', 'j', Finger.rightIndex),
    KeyDef('K', 'k', Finger.rightMiddle),
    KeyDef('L', 'l', Finger.rightRing),
    KeyDef(';', ';', Finger.rightPinky),
    KeyDef("'", "'", Finger.rightPinky),
    KeyDef('Enter', 'enter', Finger.rightPinky, widthFactor: 2.2),
  ],
  // Bottom row
  [
    KeyDef('Shift', 'shift', Finger.leftPinky, widthFactor: 2.4),
    KeyDef('Z', 'z', Finger.leftPinky),
    KeyDef('X', 'x', Finger.leftRing),
    KeyDef('C', 'c', Finger.leftMiddle),
    KeyDef('V', 'v', Finger.leftIndex),
    KeyDef('B', 'b', Finger.leftIndex),
    KeyDef('N', 'n', Finger.rightIndex),
    KeyDef('M', 'm', Finger.rightIndex),
    KeyDef(',', ',', Finger.rightMiddle),
    KeyDef('.', '.', Finger.rightRing),
    KeyDef('/', '/', Finger.rightPinky),
    KeyDef('Shift', 'rshift', Finger.rightPinky, widthFactor: 2.9),
  ],
];

// ── Virtual Keyboard Widget ───────────────────────────────────────────────
class VirtualKeyboard extends StatelessWidget {
  /// The character that should be highlighted as "press this next"
  final String? highlightChar;

  /// Whether last keypress was wrong (shows red on highlighted key)
  final bool wasWrong;

  /// Show finger color coding
  final bool showFingerColors;

  /// Show hand placement guide and active finger hint
  final bool showHandGuide;

  const VirtualKeyboard({
    super.key,
    this.highlightChar,
    this.wasWrong = false,
    this.showFingerColors = true,
    this.showHandGuide = false,
  });

  String _normalize(String? c) {
    if (c == null) return '';
    return c.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final target = _normalize(highlightChar);
    final targetFinger = _fingerForKey(target);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Finger legend
          if (showFingerColors) _buildLegend(),
          if (showHandGuide) ...[
            const SizedBox(height: 6),
            _buildHandGuide(target, targetFinger),
          ],
          const SizedBox(height: 6),
          // Keyboard rows
          ..._kRows.map((row) => _buildRow(row, target)),
          // Space bar
          _buildSpaceBar(target),
        ],
      ),
    );
  }

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

  Widget _buildLegend() {
    final items = [
      ('Pinky', AppTheme.fingerPinky),
      ('Ring', AppTheme.fingerRing),
      ('Middle', AppTheme.fingerMiddle),
      ('Index', AppTheme.fingerIndex),
      ('Thumb', AppTheme.fingerThumb),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: item.$2, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(item.$1, style: AppTheme.body(10, color: AppTheme.textSecondary)),
        ]),
      )).toList(),
    );
  }

  Widget _buildHandGuide(String target, Finger? targetFinger) {
    final leftHand = [Finger.leftPinky, Finger.leftRing, Finger.leftMiddle, Finger.leftIndex];
    final rightHand = [Finger.rightIndex, Finger.rightMiddle, Finger.rightRing, Finger.rightPinky];

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
              ...leftHand.map((finger) => _buildFingerDot(finger, targetFinger == finger)),
              const SizedBox(width: 22),
              _buildFingerDot(Finger.thumb, targetFinger == Finger.thumb),
              const SizedBox(width: 22),
              ...rightHand.map((finger) => _buildFingerDot(finger, targetFinger == finger)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFingerDot(Finger finger, bool active) {
    final color = finger.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: active ? 22 : 18,
        height: active ? 22 : 18,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: active ? color : color.withValues(alpha: 0.5), width: active ? 2 : 1),
          boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8)] : null,
        ),
      ),
    );
  }

  Widget _buildRow(List<KeyDef> keys, String target) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys.map((key) => _buildKey(key, target)).toList(),
      ),
    );
  }

  Widget _buildKey(KeyDef key, String target) {
    final isTarget = target.isNotEmpty && key.value == target;
    final baseColor = showFingerColors ? key.finger.color.withValues(alpha: 0.15) : AppTheme.card;
    final borderColor = showFingerColors ? key.finger.color.withValues(alpha: 0.4) : AppTheme.cardBorder;

    Color bg;
    Color border;
    Color textColor;

    if (isTarget) {
      if (wasWrong) {
        bg = AppTheme.error.withValues(alpha: 0.3);
        border = AppTheme.error;
        textColor = AppTheme.error;
      } else {
        bg = AppTheme.primary.withValues(alpha: 0.25);
        border = AppTheme.primary;
        textColor = AppTheme.primary;
      }
    } else {
      bg = baseColor;
      border = borderColor;
      textColor = AppTheme.textSecondary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 36 * key.widthFactor,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border, width: isTarget ? 1.5 : 1),
        boxShadow: isTarget ? [BoxShadow(color: border.withValues(alpha: 0.4), blurRadius: 6)] : null,
      ),
      child: Center(
        child: Text(
          key.label,
          style: AppTheme.mono(isTarget ? 12 : 10, color: textColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSpaceBar(String target) {
    final isTarget = target == ' ';
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 320,
        height: 34,
        decoration: BoxDecoration(
          color: isTarget
              ? AppTheme.fingerThumb.withValues(alpha: wasWrong ? 0.1 : 0.25)
              : AppTheme.fingerThumb.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isTarget ? (wasWrong ? AppTheme.error : AppTheme.primary) : AppTheme.fingerThumb.withValues(alpha: 0.3),
            width: isTarget ? 1.5 : 1,
          ),
          boxShadow: isTarget ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 6)] : null,
        ),
        child: Center(
          child: Text('SPACE', style: AppTheme.mono(10, color: isTarget ? AppTheme.primary : AppTheme.textMuted)),
        ),
      ),
    );
  }
}
