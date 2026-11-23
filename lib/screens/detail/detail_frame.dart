import 'package:flutter/widgets.dart';

import '../../components/dithered_gradient.dart';

import '../../components/motion.dart';
import '../../components/page_frame.dart';
import '../../components/smooth_scroll.dart';
import '../../design/tokens.dart';
import 'jump_bar.dart';
import 'detail_back_button.dart';

/// One part of the Detail page: its name in the jump bar, and what it shows.
class DetailPart {
  const DetailPart(this.label, this.child);

  final String label;
  final Widget child;
}

/// The Detail page as one scroll: the [top], then the jump bar, which sticks
/// to the top once it gets there and takes over the back button, then the
/// [parts]. Until the bar is at the top, the back button floats over the top
/// on its own. With no parts there is no bar, only the floating back button.
class DetailFrame extends StatefulWidget {
  const DetailFrame({
    super.key,
    required this.title,
    required this.onBack,
    required this.top,
    this.parts = const [],
    this.malId,
    this.hideCover = false,
    this.status,
    this.footer,
  });

  final String title;
  final VoidCallback onBack;
  final Widget top;
  final List<DetailPart> parts;

  /// The title whose cover shows small in the bar once it is at the top.
  final int? malId;
  final bool hideCover;

  /// The user's status button, in the bar once it is at the top.
  final Widget? status;

  /// A last line after the parts, such as where the data came from.
  final Widget? footer;

  @override
  State<DetailFrame> createState() => _DetailFrameState();
}

class _DetailFrameState extends State<DetailFrame> {
  final _controller = SmoothScrollController();
  final _topKey = GlobalKey();
  final _viewportKey = GlobalKey();
  var _keys = <String, GlobalKey>{};
  var _stuck = false;
  var _active = 0;

  // a part counts as the one in view once its top is this far under the bar
  static const _reach = JumpBar.height + Tokens.space5;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // keyed by name, so a part coming or going never remounts the others
  List<GlobalKey> _keysFor(List<DetailPart> parts) {
    _keys = {
      for (final part in parts) part.label: _keys[part.label] ?? GlobalKey(),
    };
    return _keys.values.toList();
  }

  double? _topOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (box == null || !box.attached || viewport == null) return null;
    return box.localToGlobal(Offset.zero, ancestor: viewport).dy;
  }

  void _onScroll() {
    final topHeight = _topKey.currentContext?.size?.height ?? 0;
    final stuck = _controller.hasClients && _controller.offset >= topHeight;
    var active = 0;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 1) {
      // at the very end the last part is the one in view, short or not
      active = _keys.length - 1;
    } else {
      for (final (i, key) in _keys.values.indexed) {
        final top = _topOf(key);
        if (top != null && top <= _reach) active = i;
      }
    }
    if (stuck != _stuck || active != _active) {
      setState(() {
        _stuck = stuck;
        _active = active;
      });
    }
  }

  void _scrollTo(double offset) {
    final position = _controller.position;
    final to = offset.clamp(0.0, position.maxScrollExtent);
    final duration = chooseMotionDuration(context, Tokens.motionSlide);
    if (duration == Duration.zero) return _controller.jumpTo(to);
    _controller.animateTo(to, duration: duration, curve: Curves.easeInOut);
  }

  void _jump(int index) {
    final top = _topOf(_keys.values.elementAt(index));
    if (top == null) return;
    setState(() => _active = index);
    _scrollTo(_controller.offset + top - JumpBar.height);
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.parts;
    final keys = _keysFor(parts);
    return Stack(
      children: [
        // the console's chassis, fixed behind the page as it scrolls
        const Positioned.fill(
          child: DitheredGradient(
            top: Tokens.chassisTop,
            bottom: Tokens.chassisBottom,
          ),
        ),
        Positioned.fill(
          child: CustomScrollView(
            key: _viewportKey,
            controller: _controller,
            slivers: [
              SliverToBoxAdapter(
                child: KeyedSubtree(key: _topKey, child: widget.top),
              ),
              if (parts.isNotEmpty) ...[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _BarDelegate(
                    JumpBar(
                      title: widget.title,
                      labels: [for (final part in parts) part.label],
                      active: _active.clamp(0, parts.length - 1),
                      stuck: _stuck,
                      onJump: _jump,
                      onBack: widget.onBack,
                      onTop: () => _scrollTo(0),
                      malId: widget.malId,
                      hideCover: widget.hideCover,
                      status: widget.status,
                    ),
                  ),
                ),
                // built whole, not as it scrolls in, so every part has a place
                // the bar can jump to; a page has only a handful of them
                SliverToBoxAdapter(
                  child: Padding(
                    padding: PageFrame.content.copyWith(top: Tokens.space5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, part) in parts.indexed)
                          KeyedSubtree(key: keys[i], child: part.child),
                        ?widget.footer,
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // the back button on its own until the bar at the top takes it
        if (!_stuck)
          Positioned(
            left: PageFrame.edge,
            top: PageFrame.edge,
            child: DetailBackButton(onBack: widget.onBack),
          ),
      ],
    );
  }
}

class _BarDelegate extends SliverPersistentHeaderDelegate {
  _BarDelegate(this.bar);

  final JumpBar bar;

  @override
  double get minExtent => JumpBar.height;

  @override
  double get maxExtent => JumpBar.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => bar;

  @override
  bool shouldRebuild(_BarDelegate old) => true;
}
