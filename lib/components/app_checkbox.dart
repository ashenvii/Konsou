import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'motion.dart';
import 'pressable.dart';

enum CheckValue { empty, checked, excluded }

/// A well that lights. Empty is a sunk well with a ring, checked is lit pop
/// with a dark check, excluded is the empty well with a red minus. With
/// [allowExclude] off it only switches between empty and checked.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowExclude = false,
    this.onHover,
    this.zone,
  });

  final CheckValue value;
  final ValueChanged<CheckValue>? onChanged;
  final bool allowExclude;

  /// Tells a row around the box when the pointer is on it, so the row can
  /// give up its own hover mark and the two never both light.
  final ValueChanged<bool>? onHover;

  /// The area that takes the tap, with the box centred in it. Without it only
  /// the box does (and a touch screen widens that to the touch target).
  final Size? zone;

  CheckValue get _next => switch (value) {
    CheckValue.empty => CheckValue.checked,
    CheckValue.checked => allowExclude ? CheckValue.excluded : CheckValue.empty,
    CheckValue.excluded => CheckValue.empty,
  };

  @override
  Widget build(BuildContext context) {
    // Excluded is not "unchecked": say it, since only a red minus shows it.
    return Semantics(
      value: value == CheckValue.excluded ? 'excluded' : null,
      child: MouseRegion(
        onEnter: (_) => onHover?.call(true),
        onExit: (_) => onHover?.call(false),
        child: Pressable(
          onPressed: onChanged == null ? null : () => onChanged!(_next),
          checked: value == CheckValue.checked,
          builder: (context, state) {
            final box = _Box(
              value: value,
              hovered: state.hovered,
              pressed: state.pressed,
            );
            final zone = this.zone;
            if (zone == null) return box;
            return SizedBox.fromSize(
              size: zone,
              child: Center(child: box),
            );
          },
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.value,
    required this.hovered,
    required this.pressed,
  });

  final CheckValue value;
  final bool hovered;
  final bool pressed;

  // where the top shade of a sunk well ends, as a share of its height
  static const _shadeRest = 0.2;
  static const _shadePressed = 0.4;

  @override
  Widget build(BuildContext context) {
    final checked = value == CheckValue.checked;
    // an unchecked box under the pointer, or pressed, gets a pop ring
    final lit = !checked && (hovered || pressed);
    final clear = Tokens.keyShadow.withValues(alpha: 0);
    final footStart = 1 - Tokens.displayInset / Tokens.checkboxSize;
    return AnimatedContainer(
      duration: chooseMotionDuration(context, Tokens.motionSegment),
      width: Tokens.checkboxSize,
      height: Tokens.checkboxSize,
      decoration: BoxDecoration(
        color: checked ? Tokens.pop : Tokens.wellFill,
        borderRadius: Tokens.wellCorners,
        boxShadow: [
          if (checked)
            BoxShadow(
              color: Tokens.pop.withValues(alpha: 0.55),
              blurRadius: Tokens.lampGlow,
            )
          else
            BoxShadow(
              color: lit ? Tokens.pop : Tokens.checkboxEdge,
              spreadRadius: lit ? Tokens.hoverEdge : Tokens.checkboxRing,
            ),
        ],
      ),
      // a sunk well is shaded at the top, a lit one at the foot
      foregroundDecoration: BoxDecoration(
        borderRadius: Tokens.wellCorners,
        gradient: checked
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, footStart, footStart, 1],
                colors: [
                  clear,
                  clear,
                  Tokens.keyShadow.withValues(alpha: 0.28),
                  Tokens.keyShadow.withValues(alpha: 0.28),
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, pressed ? _shadePressed : _shadeRest],
                colors: [Tokens.keyShadow, clear],
              ),
      ),
      child: CustomPaint(painter: _MarkPainter(value)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.value);

  final CheckValue value;

  @override
  void paint(Canvas canvas, Size size) {
    if (value == CheckValue.empty) return;
    final checked = value == CheckValue.checked;
    final mark = Paint()
      ..color = checked ? Tokens.onPop : Tokens.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = Tokens.checkboxMark
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    // drawn for a box of checkboxSize; this scales it with the box
    final u = size.width / Tokens.checkboxSize;
    if (checked) {
      final path = Path()
        ..moveTo(5 * u, 12.5 * u)
        ..lineTo(9.5 * u, 17 * u)
        ..lineTo(19 * u, 7 * u);
      canvas.drawPath(path, mark);
    } else {
      final y = size.height / 2;
      canvas.drawLine(Offset(6 * u, y), Offset(size.width - 6 * u, y), mark);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.value != value;
}
