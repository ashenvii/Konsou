import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../components/countdown.dart';
import '../design/tokens.dart';
import 'maximize_button_link.dart';
import 'window_config.dart';
import 'title_bar.dart';
import 'window_memory.dart';

/// The console's title bar: a raised strip, lit along its top and cut off from
/// the page by a dark line.
const titleBarFill = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Tokens.barTop, Tokens.barBottom],
  ),
  border: Border(
    top: BorderSide(color: Tokens.edgeLight),
    bottom: BorderSide(color: Tokens.wellFill),
  ),
);

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    this.rail,
    this.overlay,
    this.beforeClose,
    this.onFocus,
    this.openSupport,
    this.onSearch,
    this.wordmark,
  });

  final Widget child;

  final Widget? rail;

  final Widget Function(double leftInset)? overlay;

  final Future<void> Function()? beforeClose;

  /// Runs each time the window comes to the front.
  final VoidCallback? onFocus;

  /// Opens the support page from the heart. Null leaves the heart inert.
  final Future<void> Function()? openSupport;

  /// Opens Quick search from the search well.
  final VoidCallback? onSearch;

  /// The wordmark in the title bar; plain Konsou when null.
  final Widget? wordmark;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WindowListener {
  // trust window events for maximized: asking during restore wipes the save
  bool _maximized = false;
  bool _restoring = true;
  bool _closing = false;
  var _maximizeButton = MaximizeButtonState.none;
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
    listenToMaximizeButton((state) {
      if (mounted) setState(() => _maximizeButton = state);
    });
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
    if (Platform.isWindows) {
      windowManager.removeListener(this);
      listenToMaximizeButton(null);
    }
    super.dispose();
  }

  // alt f4, the taskbar and the window menu close here too
  @override
  void onWindowClose() => _close();

  @override
  void onWindowFocus() => widget.onFocus?.call();

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    // the window goes at once; the last save and sync finish out of sight
    try {
      await windowManager.hide();
    } catch (_) {
      // a window that will not hide still has to close
    }
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
    await windowManager.destroy();
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
      // Windows gives the other three sides an invisible border outside the
      // drawn window, so only the top, which has none, is a strip in here and
      // the scrollbars can sit flush. A maximized window has no edges to drag,
      // and its top right corner has to reach the close button.
      enableResizeEdges: _maximized
          ? const []
          : const [ResizeEdge.top, ResizeEdge.topLeft, ResizeEdge.topRight],
      child: ColoredBox(
        color: Tokens.ground,
        child: Column(
          children: [
            DecoratedBox(
              decoration: titleBarFill,
              child: TitleBar(
                maximized: _maximized,
                maximizeButton: _maximizeButton,
                onMinimize: windowManager.minimize,
                onToggleMaximize: _toggleMaximize,
                onClose: _close,
                onSupport: widget.openSupport,
                onSearch: widget.onSearch,
                wordmark: widget.wordmark,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        // the faceplate: a flat strip on the window's edge
                        ColoredBox(
                          color: Tokens.railFill,
                          child: SizedBox(
                            width: Tokens.railWidth,
                            child: widget.rail,
                          ),
                        ),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                  // the faceplate's edge: a dark cut, then a faint lit lip on
                  // the page side
                  const Positioned(
                    left: Tokens.railWidth - 1,
                    top: 0,
                    bottom: 0,
                    width: 1,
                    child: ColoredBox(color: Tokens.wellFill),
                  ),
                  const Positioned(
                    left: Tokens.railWidth,
                    top: 0,
                    bottom: 0,
                    width: 1,
                    child: ColoredBox(color: Tokens.edgeLight),
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
