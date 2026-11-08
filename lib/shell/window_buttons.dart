import 'package:flutter/widgets.dart';

import '../components/pressable.dart';
import '../design/tokens.dart';

enum WindowGlyph { minimize, maximize, restore, close }

/// One of the three window buttons. Icons use only horizontal, vertical and
/// 45 degree lines. Hover brightens the icon, and the close icon turns red.
/// Built on [Pressable], so the keyboard reaches it and it has a spoken name.
class WindowButton extends StatelessWidget {
  const WindowButton({super.key, required this.glyph, required this.onPressed});

  final WindowGlyph glyph;
  final VoidCallback onPressed;

  String get _label => switch (glyph) {
    WindowGlyph.minimize => 'Minimize',
    WindowGlyph.maximize => 'Maximize',
    WindowGlyph.restore => 'Restore',
    WindowGlyph.close => 'Close',
  };

  @override
  Widget build(BuildContext context) {
    final isClose = glyph == WindowGlyph.close;
    return Semantics(
      label: _label,
      child: Pressable(
        onPressed: onPressed,
        cursor: SystemMouseCursors.basic,
        builder: (context, state) {
          final color = !state.hovered
              ? Tokens.inkMuted
              : (isClose ? Tokens.red : Tokens.ink);
          return SizedBox(
            width: Tokens.windowButtonWidth,
            height: Tokens.barHeight,
            child: Center(
              child: CustomPaint(
                size: const Size.square(Tokens.windowIconSize),
                painter: _GlyphPainter(glyph, color),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final WindowGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      // Square lines stay sharp; only the close cross is diagonal.
      ..isAntiAlias = glyph == WindowGlyph.close;
    switch (glyph) {
      case WindowGlyph.minimize:
        canvas.drawLine(Offset(0, s / 2), Offset(s, s / 2), line);
      case WindowGlyph.maximize:
        canvas.drawRect(Rect.fromLTWH(0.5, 0.5, s - 1, s - 1), line);
      case WindowGlyph.restore:
        canvas.drawRect(Rect.fromLTWH(0.5, 2.5, s - 3, s - 3), line);
        canvas.drawLine(const Offset(2.5, 0.5), Offset(s - 0.5, 0.5), line);
        canvas.drawLine(Offset(s - 0.5, 0.5), Offset(s - 0.5, s - 2.5), line);
      case WindowGlyph.close:
        canvas.drawLine(Offset.zero, Offset(s, s), line);
        canvas.drawLine(Offset(s, 0), Offset(0, s), line);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
