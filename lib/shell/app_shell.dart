import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'window_buttons.dart';
import 'window_config.dart';
import 'window_memory.dart';

/// The frame around every screen: top bar (also the title bar), left rail and
/// the content area, which shows [child]. Layout comes from
/// notes/design/screens/shell.md.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child, this.rail, this.beforeClose});

  final Widget child;

  /// The left rail, on Windows. Phones get their own frame later.
  final Widget? rail;

  /// Runs when Close is pressed, before the window quits.
  final Future<void> Function()? beforeClose;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WindowListener {
  // The maximized flag comes from the window events only. Asking the window
  // during the startup restore gives a wrong answer and wipes the saved state.
  bool _maximized = false;
  bool _restoring = true;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    if (!Platform.isWindows) return;
    windowManager.addListener(this);
    WindowMemory.load().then((saved) {
      if (!mounted) return;
      setState(() => _maximized = saved?.maximized ?? false);
      // First run: remember the real starting size right away, so a later
      // restore from maximized has something to return to.
      if (saved == null) _save();
    });
    // Ignore the resize and move events caused by restoring the window.
    Future<void>.delayed(WindowConfig.restoreSettle, () => _restoring = false);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (Platform.isWindows) windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _close() async {
    // Save a change made in the last moments before quitting.
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      try {
        await _save();
      } catch (_) {
        // Losing the last window position must never stop the app closing.
      }
    }
    try {
      await widget.beforeClose?.call();
    } catch (_) {
      // a failed shutdown step must never stop the app closing
    }
    await windowManager.close();
  }

  @override
  void onWindowMaximize() {
    setState(() => _maximized = true);
    _scheduleSave();
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _maximized = false);
    _scheduleSave();
  }

  @override
  void onWindowResized() => _scheduleSave();

  @override
  void onWindowMoved() => _scheduleSave();

  void _scheduleSave() {
    if (_restoring) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(WindowConfig.saveDelay, _save);
  }

  Future<void> _save() async {
    final old = await WindowMemory.load();
    if (_maximized) {
      // Keep the last normal size and position, only flip the flag.
      await WindowMemory(
        size: old?.size ?? WindowConfig.startSize,
        position: old?.position ?? WindowConfig.startPosition,
        maximized: true,
      ).save();
      return;
    }
    await WindowMemory(
      size: await windowManager.getSize(),
      position: await windowManager.getPosition(),
      maximized: false,
    ).save();
  }

  Future<void> _toggleMaximize() async {
    if (_maximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The own title bar and window controls exist on Windows only.
    if (!Platform.isWindows) {
      // Keep clear of a phone's status bar, notch and gesture bar.
      return ColoredBox(
        color: Tokens.ground,
        child: SafeArea(child: widget.child),
      );
    }
    return DragToResizeArea(
      resizeEdgeSize: Tokens.resizeEdge,
      child: ColoredBox(
        color: Tokens.ground,
        child: Column(
          children: [
            _TopBar(
              maximized: _maximized,
              onMinimize: windowManager.minimize,
              onToggleMaximize: _toggleMaximize,
              onClose: _close,
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(width: Tokens.railWidth, child: widget.rail),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.maximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
  });

  final bool maximized;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Tokens.barHeight,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: onToggleMaximize,
                child: Row(
                  children: [
                    // the mascot is centred over the rail's icons and the
                    // wordmark starts at the rail's edge
                    const SizedBox(
                      width: Tokens.railWidth,
                      child: Center(
                        child: AppIcon(
                          AppIcons.nekomimi,
                          size: Tokens.railIconSize,
                          color: Tokens.mint,
                          lineColor: Tokens.ground,
                        ),
                      ),
                    ),
                    const Text(
                      WindowConfig.title,
                      style: TextStyle(
                        fontFamily: Tokens.sans,
                        fontWeight: FontWeight.w700,
                        fontSize: Tokens.text4,
                        color: Tokens.ink,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Search',
                      style: TextStyle(
                        fontFamily: Tokens.sans,
                        fontSize: Tokens.text3,
                        color: Tokens.inkMuted,
                      ),
                    ),
                    const SizedBox(width: Tokens.space2),
                    const Text(
                      'Ctrl K',
                      style: TextStyle(
                        fontFamily: Tokens.mono,
                        fontSize: Tokens.text2,
                        color: Tokens.inkMuted,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          WindowButton(glyph: WindowGlyph.minimize, onPressed: onMinimize),
          WindowButton(
            glyph: maximized ? WindowGlyph.restore : WindowGlyph.maximize,
            onPressed: onToggleMaximize,
          ),
          WindowButton(glyph: WindowGlyph.close, onPressed: onClose),
        ],
      ),
    );
  }
}
