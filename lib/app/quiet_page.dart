import 'package:flutter/widgets.dart';

/// A page that appears at once and has no barrier under it. Flutter puts a
/// barrier under every route and answers a click that reaches it with the
/// system alert sound, which on Windows is the error ding: any click on a
/// bare part of a page played it.
class QuietPage extends Page<void> {
  const QuietPage({super.key, required this.child});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _QuietRoute(this);
}

class _QuietRoute extends PageRoute<void> {
  _QuietRoute(QuietPage page) : super(settings: page);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildModalBarrier() => const SizedBox.shrink();

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => (settings as QuietPage).child;
}
