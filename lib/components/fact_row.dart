import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// Children in one line parted by thin lines when they all fit, and wrapped
/// into rows with no lines when they do not. The choice comes from the
/// children's own widths, so longer text or larger type never spills over.
class FactRow extends MultiChildRenderObjectWidget {
  const FactRow({super.key, required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFactRow();
}

class _FactParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderFactRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FactParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FactParentData> {
  // in one line: a gap, the line, a gap between children
  static const _gap = Tokens.space4;
  static const _line = 1.0;

  // wrapped: the space between children and between rows
  static const _wrapGap = Tokens.space5 + Tokens.space2;
  static const _runGap = Tokens.space4;

  var _lines = <double>[];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FactParentData) {
      child.parentData = _FactParentData();
    }
  }

  @override
  void performLayout() {
    final maxWidth = constraints.maxWidth;
    final children = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints(maxWidth: maxWidth), parentUsesSize: true);
      children.add(child);
      child = childAfter(child);
    }
    if (children.isEmpty) {
      _lines = [];
      size = constraints.smallest;
      return;
    }
    final between = 2 * _gap + _line;
    final rowWidth =
        children.fold(0.0, (sum, c) => sum + c.size.width) +
        between * (children.length - 1);
    if (rowWidth <= maxWidth) {
      final height = children.map((c) => c.size.height).reduce(math.max);
      var x = 0.0;
      final lines = <double>[];
      for (final (i, c) in children.indexed) {
        if (i > 0) {
          lines.add(x + _gap);
          x += between;
        }
        (c.parentData! as _FactParentData).offset = Offset(
          x,
          (height - c.size.height) / 2,
        );
        x += c.size.width;
      }
      _lines = lines;
      size = constraints.constrain(Size(rowWidth, height));
      return;
    }
    var x = 0.0;
    var y = 0.0;
    var run = 0.0;
    var widest = 0.0;
    for (final c in children) {
      if (x > 0 && x + c.size.width > maxWidth) {
        y += run + _runGap;
        x = 0;
        run = 0;
      }
      (c.parentData! as _FactParentData).offset = Offset(x, y);
      widest = math.max(widest, x + c.size.width);
      x += c.size.width + _wrapGap;
      run = math.max(run, c.size.height);
    }
    _lines = [];
    size = constraints.constrain(Size(widest, y + run));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    if (_lines.isEmpty) return;
    final paint = Paint()..color = Tokens.line;
    for (final x in _lines) {
      context.canvas.drawRect(
        Rect.fromLTWH(offset.dx + x, offset.dy, _line, size.height),
        paint,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
