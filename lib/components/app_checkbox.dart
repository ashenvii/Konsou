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
  });

  final CheckValue value;
  final ValueChanged<CheckValue>? onChanged;
  final bool allowExclude;

  CheckValue get _next => switch (value) {
    CheckValue.empty => CheckValue.checked,
    CheckValue.checked => allowExclude ? CheckValue.excluded : CheckValue.empty,
    CheckValue.excluded => CheckValue.empty,
  };

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onChanged == null ? null : () => onChanged!(_next),
      checked: value == CheckValue.checked,
      builder: (context, state) => SizedBox.square(
        dimension: Tokens.checkboxSize,
        child: CustomPaint(painter: _BoxPainter(value)),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.value);

  final CheckValue value;

  @override
  void paint(Canvas canvas, Size size) {
    const w = Tokens.checkboxBorder;
    final checked = value == CheckValue.checked;
    final edge = Paint()
      ..color = checked ? Tokens.amber : Tokens.inkMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..isAntiAlias = false;
    if (checked) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Tokens.amber);
    }
    canvas.drawRect(
      Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w),
      edge,
    );

    final mark = Paint()
      ..color = checked ? Tokens.ground : Tokens.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    switch (value) {
      case CheckValue.empty:
        break;
      case CheckValue.checked:
        // Two 45 degree strokes.
        final path = Path()
          ..moveTo(5, 10)
          ..lineTo(8, 13)
          ..lineTo(15, 6);
        canvas.drawPath(path, mark);
      case CheckValue.excluded:
        final y = size.height / 2;
        canvas.drawLine(Offset(5, y), Offset(size.width - 5, y), mark);
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.value != value;
}
