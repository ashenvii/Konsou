import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../components/countdown.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'window_buttons.dart';
import 'window_config.dart';
import 'window_memory.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    this.rail,
    this.overlay,
    this.beforeClose,
  });

  final Widget child;

  final Widget? rail;

  final Widget Function(double leftInset)? overlay;

  final Future<void> Function()? beforeClose;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WindowListener {
  // trust window events for maximized: asking during restore wipes the save
  bool _maximized = false;
  bool _restoring = true;
  // saving the window's place waits for it to stop moving
  late final Countdown _saveWait = Countdown(onDone: _save);
  late final Countdown _restoreWait = Countdown(
    onDone: () => _restoring = false,
  );

  @override
  void initState() {
    super.initState();
    if (!Platform.isWindows) return;
    windowManager.addListener(this);
    WindowMemory.load().then((saved) {
      if (!mounted) return;
      setState(() => _maximized = saved?.maximized ?? false);
      // first run: save the real size so restoring from maximized has one
      if (saved == null) _save();
    });
    // ignore the resize and move events caused by restoring the window.
    _restoreWait.start(WindowConfig.restoreSettle);
  }

  @override
  void dispose() {
    _saveWait.dispose();
    _restoreWait.dispose();
    if (Platform.isWindows) windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _close() async {
    // save a change made in the last moments before quitting.
    if (_saveWait.running) {
      _saveWait.cancel();
      try {
        await _save();
      } catch (_) {
        // losing the last window position must never stop the app closing.
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
    _saveWait.start(WindowConfig.saveDelay);
  }

  Future<void> _save() async {
    final old = await WindowMemory.load();
    if (_maximized) {
      // keep the last normal size and position, only flip the flag.
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
    // the own title bar and window controls exist on Windows only.
    if (!Platform.isWindows) {
      // keep clear of a phone's status bar, notch and gesture bar.
      return ColoredBox(
        color: Tokens.ground,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (widget.overlay != null)
                Positioned.fill(child: widget.overlay!(0)),
            ],
          ),
        ),
      );
    }
    return DragToResizeArea(
      resizeEdgeSize: Tokens.resizeEdge,
      child: ColoredBox(
        color: Tokens.ground,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(gradient: _barTint),
              child: _TopBar(
                maximized: _maximized,
                onMinimize: windowManager.minimize,
                onToggleMaximize: _toggleMaximize,
                onClose: _close,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(gradient: _railTint),
                          child: SizedBox(
                            width: Tokens.railWidth,
                            child: widget.rail,
                          ),
                        ),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                  Positioned(
                    left: Tokens.railWidth,
                    right: 0,
                    top: 0,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: _barLine),
                    ),
                  ),
                  Positioned(
                    left: Tokens.railWidth,
                    top: 0,
                    bottom: 0,
                    width: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: _railLine),
                    ),
                  ),
                  if (widget.overlay != null)
                    Positioned.fill(child: widget.overlay!(Tokens.railWidth)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// the frame fades into the page so the page is not caged
Color _tint(double alpha) => Tokens.surface.withValues(alpha: alpha);
Color _line(double alpha) => Tokens.line.withValues(alpha: alpha);

final _barTint = LinearGradient(
  colors: [_tint(0.55), _tint(0.22), _tint(0)],
  stops: const [0, 0.12, 0.38],
);

final _railTint = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [_tint(0.55), _tint(0.22), _tint(0), _tint(0), _tint(0.3)],
  stops: const [0, 0.3, 0.55, 0.82, 1],
);

final _barLine = LinearGradient(
  colors: [_line(1), _line(1), _line(0), _line(0), _line(1)],
  stops: const [0, 0.06, 0.35, 0.82, 1],
);

final _railLine = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [_line(1), _line(1), _line(0), _line(0), _line(1)],
  stops: const [0, 0.04, 0.45, 0.85, 1],
);

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
                    // the mascot sits over the rail icons, the wordmark at the rail edge
                    const SizedBox(
                      width: Tokens.railWidth,
                      child: Center(
                        child: AppIcon(
                          AppIcons.nekomimi,
                          size: Tokens.iconSize,
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
