import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

enum WindowGlyph { minimize, maximize, restore, close }

/// One of the three window buttons. Icons use only horizontal, vertical and
/// 45 degree lines. Hover brightens the icon, and the close icon turns red.
class WindowButton extends StatefulWidget {
  const WindowButton({super.key, required this.glyph, required this.onPressed});

  final WindowGlyph glyph;
  final VoidCallback onPressed;

  @override
  State<WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<WindowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isClose = widget.glyph == WindowGlyph.close;
    final color = !_hover
        ? Tokens.inkMuted
        : (isClose ? Tokens.red : Tokens.ink);
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: SizedBox(
          width: Tokens.windowButtonWidth,
          height: Tokens.barHeight,
          child: Center(
            child: CustomPaint(
              size: const Size.square(Tokens.windowIconSize),
              painter: _GlyphPainter(widget.glyph, color),
            ),
          ),
        ),
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
      ..isAntiAlias = false;
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
        final diag = Paint()
          ..color = color
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset.zero, Offset(s, s), diag);
        canvas.drawLine(Offset(s, 0), Offset(0, s), diag);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
