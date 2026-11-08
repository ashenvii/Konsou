import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

/// Window size and position saved between runs.
class WindowMemory {
  const WindowMemory({
    required this.size,
    required this.position,
    required this.maximized,
  });

  final Size size;
  final Offset position;
  final bool maximized;

  static const _w = 'window.width';
  static const _h = 'window.height';
  static const _x = 'window.x';
  static const _y = 'window.y';
  static const _max = 'window.maximized';

  /// Null when nothing usable is saved. A damaged preferences file or a value
  /// of the wrong type also gives null: the window then opens at its default
  /// size, instead of the app failing before it shows anything.
  static Future<WindowMemory?> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final w = p.getDouble(_w);
      final h = p.getDouble(_h);
      final x = p.getDouble(_x);
      final y = p.getDouble(_y);
      if (w == null || h == null || x == null || y == null) return null;
      // Ignore a saved size that cannot be a real window.
      if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return null;
      if (!x.isFinite || !y.isFinite) return null;
      return WindowMemory(
        size: Size(w, h),
        position: Offset(x, y),
        maximized: p.getBool(_max) ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_w, size.width);
    await p.setDouble(_h, size.height);
    await p.setDouble(_x, position.dx);
    await p.setDouble(_y, position.dy);
    await p.setBool(_max, maximized);
  }
}
