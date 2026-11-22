import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Width of the noise tile. The pattern repeats sideways, which a one-step
/// noise never shows.
const ditherTileWidth = 64;

/// A top to bottom gradient as 8-bit pixels with the rounding left to chance:
/// each pixel lands on the level above or below its true value, with the
/// odds the value asks for. The rows average to the exact gradient and no
/// band has a hard edge. The engine's own gradient rounds every pixel the
/// same way, which on a ramp this dark and this long shows as steps.
Uint8List ditheredRows(Color top, Color bottom, int height, {int seed = 1}) {
  final pixels = Uint8List(ditherTileWidth * height * 4);
  var state = seed * 2654435761 + 1;
  double next() {
    // xorshift, kept to 32 bits
    state ^= (state << 13) & 0xFFFFFFFF;
    state ^= state >> 17;
    state ^= (state << 5) & 0xFFFFFFFF;
    state &= 0xFFFFFFFF;
    return state / 4294967296;
  }

  final from = [top.r * 255, top.g * 255, top.b * 255];
  final to = [bottom.r * 255, bottom.g * 255, bottom.b * 255];
  var at = 0;
  for (var y = 0; y < height; y++) {
    final t = height == 1 ? 0.0 : y / (height - 1);
    final level = [for (var c = 0; c < 3; c++) from[c] + (to[c] - from[c]) * t];
    for (var x = 0; x < ditherTileWidth; x++) {
      for (var c = 0; c < 3; c++) {
        pixels[at++] = (level[c] + next()).floor().clamp(0, 255);
      }
      pixels[at++] = 255;
    }
  }
  return pixels;
}

/// Paints a top to bottom gradient dithered at the screen's own pixels, so
/// a long, dark ramp has no visible steps. Until the first noise is ready it
/// shows the plain gradient.
class DitheredGradient extends StatefulWidget {
  const DitheredGradient({
    super.key,
    required this.top,
    required this.bottom,
    this.child,
  });

  final Color top;
  final Color bottom;
  final Widget? child;

  @override
  State<DitheredGradient> createState() => _DitheredGradientState();
}

class _DitheredGradientState extends State<DitheredGradient> {
  ui.Image? _image;
  int _rows = 0;
  int _asked = 0;

  void _build(int rows) {
    if (rows == _rows || rows == _asked || rows < 1) return;
    _asked = rows;
    final colors = (widget.top, widget.bottom);
    ui.decodeImageFromPixels(
      ditheredRows(colors.$1, colors.$2, rows),
      ditherTileWidth,
      rows,
      ui.PixelFormat.rgba8888,
      (image) {
        if (!mounted || widget.top != colors.$1 || widget.bottom != colors.$2) {
          image.dispose();
          return;
        }
        final old = _image;
        setState(() {
          _image = image;
          _rows = rows;
        });
        old?.dispose();
      },
    );
  }

  @override
  void didUpdateWidget(DitheredGradient old) {
    super.didUpdateWidget(old);
    if (old.top != widget.top || old.bottom != widget.bottom) {
      _rows = 0;
      _asked = 0;
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final rows = (height * scale).round();
        // one frame later, so nothing is started from inside a layout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _build(rows);
        });
        return CustomPaint(
          painter: _GradientPainter(
            top: widget.top,
            bottom: widget.bottom,
            image: _image,
            scale: scale,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _GradientPainter extends CustomPainter {
  _GradientPainter({
    required this.top,
    required this.bottom,
    required this.image,
    required this.scale,
  });

  final Color top;
  final Color bottom;
  final ui.Image? image;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final noise = image;
    if (noise == null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
            top,
            bottom,
          ]),
      );
      return;
    }
    // the tile is in screen pixels: draw it at one image pixel to one pixel,
    // with no smoothing, and stretch it only if the height has just changed
    final matrix = Matrix4.identity()
      ..scaleByDouble(1 / scale, size.height / noise.height, 1, 1);
    canvas.drawRect(
      rect,
      Paint()
        ..filterQuality = FilterQuality.none
        ..shader = ImageShader(
          noise,
          TileMode.repeated,
          TileMode.clamp,
          matrix.storage,
          filterQuality: FilterQuality.none,
        ),
    );
  }

  @override
  bool shouldRepaint(_GradientPainter old) =>
      old.image != image ||
      old.top != top ||
      old.bottom != bottom ||
      old.scale != scale;
}
