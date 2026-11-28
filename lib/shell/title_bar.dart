import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../components/cap_centered_text.dart';
import '../components/key_cap.dart';
import '../components/sunk_well.dart';
import '../components/pressable.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../icons/icon_def.dart';
import 'maximize_button_link.dart';
import 'window_buttons.dart';
import 'window_config.dart';

/// The window's title bar: the mascot and wordmark, Quick search in the
/// middle, then the bell, Support and the window buttons.
class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
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
                            Text(WindowConfig.title, style: AppText.heading),
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
        return SunkWell(
          hovered: state.hovered,
          width: Tokens.quickSearchWidth,
          height: Tokens.quickSearchHeight,
          child: Row(
            children: [
              AppIcon(AppIcons.search, size: Tokens.iconSize, color: ink),
              const SizedBox(width: Tokens.space2),
              Expanded(
                child: CapCenteredText(
                  _searchPlaceholder,
                  style: AppText.label(ink),
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
