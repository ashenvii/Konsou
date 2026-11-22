import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// How every scrolling area in the app scrolls. It replaces the platform's
/// own scrollbar, so there is one scrollbar everywhere: a square teal thumb
/// with no track, always in view, kept off the window's resize strip. Phones
/// get no scrollbar, as the platform does.
class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

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
