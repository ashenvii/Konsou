import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icons.dart';
import '../icons/icon_def.dart';
import 'floating_panel.dart';
import 'icon_square_button.dart';
import 'motion.dart';

/// How a peeking row fills its width: [whole] items of [itemWidth], then a
/// sliver of the next, [Tokens.peekShare] of an item wide. When every item
/// fits there is nothing to peek at.
class PeekLayout {
  const PeekLayout({
    required this.whole,
    required this.itemWidth,
    required this.gap,
    required this.count,
  });

  /// Items as wide as possible while [whole] of them and the sliver fill
  /// [width] exactly, and none narrower than [minItem]. The sliver keeps its
  /// share at every width, so it never shrinks to a hairline or grows into a
  /// whole item.
  factory PeekLayout.fit({
    required double width,
    required double minItem,
    required double gap,
    required int count,
  }) {
    final whole = math.max(
      1,
      ((width - Tokens.peekShare * minItem) / (minItem + gap)).floor(),
    );
    final itemWidth = (width - whole * gap) / (whole + Tokens.peekShare);
    return PeekLayout(
      whole: whole,
      // too narrow even for one item and its sliver: the item keeps its least
      itemWidth: itemWidth < minItem ? math.min(minItem, width) : itemWidth,
      gap: gap,
      count: count,
    );
  }

  final int whole;
  final double itemWidth;
  final double gap;
  final int count;

  double get step => itemWidth + gap;

  bool get fitsAll => count <= whole;

  /// The first item can be no later than this, so the last page ends on a
  /// whole item and no sliver shows on the left.
  int get lastFirst => math.max(0, count - whole);

  int clampFirst(int first) => first.clamp(0, lastFirst);

  /// The first item that puts [index] whole on screen, moving as little as
  /// possible from [first].
  int firstShowing(int index, int first) {
    if (index < first) return clampFirst(index);
    if (index >= first + whole) return clampFirst(index - whole + 1);
    return first;
  }
}

/// A row of items that runs sideways. As many whole items as fit, then a
/// sliver of the next on the right only. Arrows show only on a side with
/// more: the right one moves the peeking item to first place, the left one
/// pages back. The wheel and dragging never move it, and tabbing onto an item
/// off screen brings it into view.
class PeekRow extends StatefulWidget {
  const PeekRow({
    super.key,
    required this.count,
    required this.minItemWidth,
    required this.itemBuilder,
    required this.arrowTop,
    this.gap = Tokens.space3,
  });

  final int count;

  /// The narrowest an item may be, measured by the caller from its content.
  final double minItemWidth;
  final Widget Function(BuildContext context, int index, double width)
  itemBuilder;

  /// Where the arrows sit, from the item width, so they centre on the
  /// pictures rather than on the whole item.
  final double Function(double itemWidth) arrowTop;
  final double gap;

  @override
  State<PeekRow> createState() => _PeekRowState();
}

class _PeekRowState extends State<PeekRow> {
  final _controller = ScrollController();

  // the row remembers its first item, not a pixel offset, so a resize keeps
  // the same item first
  var _first = 0;
  PeekLayout? _layout;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int first) {
    final layout = _layout;
    if (layout == null) return;
    final to = layout.clampFirst(first);
    if (to == _first) return;
    setState(() => _first = to);
    final duration = chooseMotionDuration(context, Tokens.motionSlide);
    final offset = to * layout.step;
    if (duration == Duration.zero) {
      _controller.jumpTo(offset);
    } else {
      _controller.animateTo(offset, duration: duration, curve: Curves.easeOut);
    }
  }

  // after a resize the same item stays first, with no slide
  void _settle(PeekLayout layout) {
    final first = layout.clampFirst(_first);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (first != _first) setState(() => _first = first);
      final offset = first * layout.step;
      if (_controller.offset != offset) _controller.jumpTo(offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = PeekLayout.fit(
          width: constraints.maxWidth,
          minItem: widget.minItemWidth,
          gap: widget.gap,
          count: widget.count,
        );
        final before = _layout;
        _layout = layout;
        if (before == null ||
            before.itemWidth != layout.itemWidth ||
            before.count != layout.count) {
          _settle(layout);
        }
        final first = layout.clampFirst(_first);
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.count; i++) ...[
              if (i > 0) SizedBox(width: widget.gap),
              Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: (focused) {
                  if (focused) _go(layout.firstShowing(i, _first));
                },
                child: SizedBox(
                  width: layout.itemWidth,
                  child: widget.itemBuilder(context, i, layout.itemWidth),
                ),
              ),
            ],
            // room after the last item, so the last page ends on whole items
            if (!layout.fitsAll)
              SizedBox(width: widget.gap + Tokens.peekShare * layout.itemWidth),
          ],
        );
        final arrowTop = widget.arrowTop(layout.itemWidth);
        return Stack(
          children: [
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                // only the arrows move it
                physics: const NeverScrollableScrollPhysics(),
                child: row,
              ),
            ),
            if (first > 0)
              Positioned(
                left: 0,
                top: arrowTop,
                child: _Arrow(
                  icon: AppIcons.chevronLeft,
                  label: 'Earlier titles',
                  onPressed: () => _go(_first - layout.whole),
                ),
              ),
            if (first + layout.whole < widget.count)
              Positioned(
                right: 0,
                top: arrowTop,
                child: _Arrow(
                  icon: AppIcons.chevronRight,
                  label: 'Later titles',
                  onPressed: () => _go(_first + layout.whole),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconDef icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingPanel(
      child: IconSquareButton(icon: icon, label: label, onPressed: onPressed),
    );
  }
}
