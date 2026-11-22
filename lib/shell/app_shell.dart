import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../components/countdown.dart';
import '../components/cap_centered.dart';
import '../components/key_cap.dart';
import '../components/search_well.dart';
import '../components/pressable.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../icons/icon_def.dart';
import 'maximize_button_link.dart';
import 'window_buttons.dart';
import 'window_config.dart';
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
              child: _TopBar(
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.maximized,
    required this.maximizeButton,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
    this.onSupport,
    this.onSearch,
    this.wordmark,
  });

  final Widget? wordmark;
  final bool maximized;
  final MaximizeButtonState maximizeButton;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback onClose;
  final Future<void> Function()? onSupport;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Tokens.barHeight,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: DragToMoveArea(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: onToggleMaximize,
                    // the window's own menu, as on any title bar
                    onSecondaryTapUp: (_) => windowManager.popUpWindowMenu(),
                    child: Row(
                      children: [
                        // the mascot sits over the rail icons, the wordmark at the rail edge
                        const SizedBox(
                          width: Tokens.railWidth,
                          child: Center(
                            child: AppIcon(
                              AppIcons.nekomimi,
                              size: Tokens.iconSize,
                              color: Tokens.pop,
                              lineColor: Tokens.ground,
                            ),
                          ),
                        ),
                        wordmark ??
                            const Text(
                              WindowConfig.title,
                              style: AppText.heading,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              // the bell does nothing until it is built
              _BarIcon(
                icon: AppIcons.bell,
                label: 'Notifications',
                color: Tokens.inkMuted,
                hoverColor: Tokens.ink,
              ),
              _BarIcon(
                icon: AppIcons.heart,
                label: 'Support',
                color: Tokens.red,
                hoverColor: Tokens.red,
                onPressed: onSupport == null ? null : () => onSupport!(),
              ),
              WindowButton(glyph: WindowGlyph.minimize, onPressed: onMinimize),
              WindowButton(
                glyph: maximized ? WindowGlyph.restore : WindowGlyph.maximize,
                onPressed: onToggleMaximize,
                hovered: maximizeButton != MaximizeButtonState.none,
                pressed: maximizeButton == MaximizeButtonState.pressed,
              ),
              WindowButton(glyph: WindowGlyph.close, onPressed: onClose),
            ],
          ),
          // on top of the drag area, on the window's centre
          Center(child: _QuickSearchButton(onPressed: onSearch)),
        ],
      ),
    );
  }
}

/// A square icon button in the bar, as tall as the bar.
class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.hoverColor,
    this.onPressed,
  });

  final IconDef icon;
  final String label;
  final Color color;
  final Color hoverColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      onPressed: onPressed ?? () {},
      builder: (context, state) => SizedBox(
        width: Tokens.barHeight,
        height: Tokens.barHeight,
        child: Center(
          child: AppIcon(
            icon,
            size: Tokens.iconSize,
            color: state.hovered ? hoverColor : color,
          ),
        ),
      ),
    );
  }
}

/// The search field in the middle of the bar, drawn as a button: icon, the
/// word, and the shortcut as key caps. It opens Quick search.
class _QuickSearchButton extends StatelessWidget {
  const _QuickSearchButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: 'Search',
      onPressed: onPressed ?? () {},
      builder: (context, state) {
        final ink = state.hovered ? Tokens.ink : Tokens.inkMuted;
        // a well sunk into the bar: near black, shaded at its top where the
        // bar overhangs it, a faint lit lip below. The hover is the live edge.
        return SearchWell(
          hovered: state.hovered,
          width: Tokens.quickSearchWidth,
          height: Tokens.quickSearchHeight,
          child: Row(
            children: [
              AppIcon(AppIcons.search, size: Tokens.iconSize, color: ink),
              const SizedBox(width: Tokens.space2),
              Expanded(
                child: CapCentered(
                  style: AppText.label(ink),
                  child: Text(
                    _searchPlaceholder,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(ink),
                  ),
                ),
              ),
              const SizedBox(width: Tokens.space2),
              const KeyCaps('Ctrl+K'),
            ],
          ),
        );
      },
    );
  }
}

// says what the box does: it looks in the user's list first, then everywhere
const _searchPlaceholder = 'quick search';
