import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../components/countdown.dart';
import '../components/hover_mark.dart';
import '../components/key_cap.dart';
import '../components/pressable.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../icons/icon_def.dart';
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
    this.openSupport,
    this.onSearch,
  });

  final Widget child;

  final Widget? rail;

  final Widget Function(double leftInset)? overlay;

  final Future<void> Function()? beforeClose;

  /// Opens the support page from the heart. Null leaves the heart inert.
  final Future<void> Function()? openSupport;

  /// Opens Quick search from the search well.
  final VoidCallback? onSearch;

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
                onSupport: widget.openSupport,
                onSearch: widget.onSearch,
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

// the bar fades into the page the way the rail does, strongest at the left
// edge and gone by the middle, so it is not a flat coloured strip
final _tints = [_tint(0.55), _tint(0.22), _tint(0), _tint(0), _tint(0.3)];
const _tintStops = [0.0, 0.3, 0.55, 0.82, 1.0];
final _lines = [_line(1), _line(1), _line(0), _line(0), _line(1)];

final _barTint = LinearGradient(colors: _tints, stops: _tintStops);

final _railTint = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: _tints,
  stops: _tintStops,
);

final _barLine = LinearGradient(
  colors: _lines,
  stops: const [0, 0.06, 0.35, 0.82, 1],
);

final _railLine = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: _lines,
  stops: const [0, 0.04, 0.45, 0.85, 1],
);

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.maximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
    this.onSupport,
    this.onSearch,
  });

  final bool maximized;
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
                      ],
                    ),
                  ),
                ),
              ),
              // the bell does nothing yet (its layout is not grilled)
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
        // a well dropped into the bar: page ground, dark where the bar
        // overhangs it, a faint lip below. The hover is the app's live edge.
        return HoverMark(
          on: state.hovered,
          child: Container(
            // a fixed size and no alignment: an aligned Container grows to
            // fill the bar and its fill paints over everything beside it
            width: Tokens.quickSearchWidth,
            height: Tokens.quickSearchHeight,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space2),
            decoration: BoxDecoration(
              // darker than the bar around it, so it reads as dropped in
              color: Tokens.wellEdge,
              border: Border(
                top: const BorderSide(
                  color: Tokens.wellEdge,
                  width: Tokens.hoverEdge,
                ),
                bottom: BorderSide(color: Tokens.ink.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                AppIcon(AppIcons.search, size: Tokens.iconSize, color: ink),
                const SizedBox(width: Tokens.space2),
                Expanded(
                  child: Text(
                    _searchPlaceholder,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(ink),
                  ),
                ),
                const SizedBox(width: Tokens.space2),
                const KeyCaps('Ctrl+K'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// says what the box does: it looks in the user's list first, then everywhere
const _searchPlaceholder = 'quick search';
