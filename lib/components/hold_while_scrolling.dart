import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// a value that changes mid-scroll waits for the scroll to end; only the
// nearest scroll view counts, so a rail inside the list does not hold it
class HoldWhileScrolling<T> extends StatefulWidget {
  const HoldWhileScrolling({
    super.key,
    required this.value,
    required this.builder,
  });

  final T value;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<HoldWhileScrolling<T>> createState() => _HoldWhileScrollingState<T>();
}

class _HoldWhileScrollingState<T> extends State<HoldWhileScrolling<T>> {
  late T _shown = widget.value;
  var _scrolling = false;

  @override
  void didUpdateWidget(HoldWhileScrolling<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_scrolling) _shown = widget.value;
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) _scrolling = true;
    if (notification is ScrollEndNotification) {
      _scrolling = false;
      if (_shown != widget.value) _catchUp();
    }
    return false;
  }

  void _catchUp() {
    // the end can be reported mid-layout, where a rebuild is not allowed
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _catchUp());
      return;
    }
    if (mounted && !_scrolling) setState(() => _shown = widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.builder(context, _shown),
    );
  }
}
