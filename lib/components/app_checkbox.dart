import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'pressable.dart';

enum CheckValue { empty, checked, excluded }

/// Empty, checked (amber with a check) or excluded (a red minus). With
/// [allowExclude] off it only switches between empty and checked.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowExclude = false,
    this.onHover,
  });

  final CheckValue value;
  final ValueChanged<CheckValue>? onChanged;
  final bool allowExclude;

  /// Tells a row around the box when the pointer is on it, so the row can
  /// give up its own hover mark and the two never both light.
  final ValueChanged<bool>? onHover;

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
          builder: (context, state) => SizedBox.square(
            dimension: Tokens.checkboxSize,
            child: CustomPaint(painter: _BoxPainter(value, state.hovered)),
          ),
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.value, this.hovered);

  final CheckValue value;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    const w = Tokens.checkboxBorder;
    final checked = value == CheckValue.checked;
    // an empty box under the pointer fills mint; the click turns it amber
    final lit = hovered && value == CheckValue.empty;
    final edge = Paint()
      ..color = checked
          ? Tokens.amber
          : lit
          ? Tokens.mint
          : Tokens.inkMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..isAntiAlias = false;
    if (checked || lit) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = checked ? Tokens.amber : Tokens.mint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w),
      edge,
    );

    final mark = Paint()
      ..color = checked ? Tokens.ground : Tokens.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    // The mark was drawn for a box of checkboxSize; this scales it with the box.
    final u = size.width / Tokens.checkboxSize;
    switch (value) {
      case CheckValue.empty:
        break;
      case CheckValue.checked:
        // Two 45 degree strokes.
        final path = Path()
          ..moveTo(5 * u, 10 * u)
          ..lineTo(8 * u, 13 * u)
          ..lineTo(15 * u, 6 * u);
        canvas.drawPath(path, mark);
      case CheckValue.excluded:
        final y = size.height / 2;
        canvas.drawLine(Offset(5 * u, y), Offset(size.width - 5 * u, y), mark);
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) =>
      old.value != value || old.hovered != hovered;
}
