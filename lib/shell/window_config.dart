import 'dart:ui';

/// Window sizes and timings. Not design tokens: they describe the window, not
/// the look.
abstract final class WindowConfig {
  static const Size startSize = Size(1280, 800);

  static const Size minSize = Size(960, 600);
  static const Offset startPosition = Offset(80, 80);
  static const String title = 'Konsou';
  static const Duration saveDelay = Duration(milliseconds: 300);
  static const Duration restoreSettle = Duration(milliseconds: 1500);
}
