import 'package:flutter/widgets.dart';

import '../../components/motion.dart';
import '../../components/smooth_scroll.dart';
import '../../design/tokens.dart';
import 'back_bar.dart';
import 'detail_header.dart';
import 'detail_top.dart';

/// The Detail page's fixed part over its scrolling content: the back bar,
/// which changes once the title has scrolled under it and then carries
/// [status], the user's status button.
class DetailFrame extends StatefulWidget {
  const DetailFrame({
    super.key,
    required this.title,
    required this.onBack,
    required this.children,
    this.status,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> children;
  final Widget? status;

  @override
  State<DetailFrame> createState() => _DetailFrameState();
}

class _DetailFrameState extends State<DetailFrame> {
  final _controller = SmoothScrollController();
  var _fade = 0.0;

  // The bar starts to change as the title's first line reaches it, and has
  // changed once both lines are under it.
  static const _fadeStart = DetailTop.titleTop - BackBar.height;
  static const _fadeSpan = DetailHeader.titleLine;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final fade = ((_controller.offset - _fadeStart) / _fadeSpan).clamp(
      0.0,
      1.0,
    );
    if (fade != _fade) setState(() => _fade = fade);
  }

  void _toTop() {
    final duration = chooseMotionDuration(context, Tokens.motionSlide);
    if (duration == Duration.zero) return _controller.jumpTo(0);
    _controller.animateTo(0, duration: duration, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            controller: _controller,
            padding: const EdgeInsets.only(bottom: Tokens.space5),
            children: widget.children,
          ),
        ),
        // after the content, so its fade falls on the page
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: BackBar(
            title: widget.title,
            scrolled: _fade > 0,
            fade: _fade,
            onBack: widget.onBack,
            onTitle: _toTop,
            status: widget.status,
          ),
        ),
      ],
    );
  }
}
