import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// How every scrolling area in the app scrolls. It replaces the platform's
/// own scrollbar, so there is one scrollbar everywhere: a square muted ink thumb
/// with no track, always in view, kept off the window's resize strip. Phones
/// get no scrollbar, as the platform does.
class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  // phones all scroll the way an iPhone does: the page rubber-bands at its
  // ends and flings on Apple's decay. Desktop stays clamped at its ends
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return const ClampingScrollPhysics();
    }
  }

  // bouncing replaces android's glow and stretch, so none is drawn on top
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (getPlatform(context)) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return child;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return RawScrollbar(
          controller: details.controller,
          thumbVisibility: true,
          interactive: true,
          thickness: Tokens.scrollbarWidth,
          radius: Radius.zero,
          // a long list would make the thumb too small to grab
          minThumbLength: Tokens.touchTarget,
          thumbColor: Tokens.inkMuted,
          child: child,
        );
    }
  }
}
