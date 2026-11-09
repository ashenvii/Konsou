import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'pressable.dart';

/// One row of a menu.
class MenuEntry {
  const MenuEntry({
    required this.label,
    required this.onPressed,
    this.shortcut,
    this.selected = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The key that does the same, shown on the right.
  final String? shortcut;

  /// Marks the current choice with a check.
  final bool selected;

  /// Red, for removing.
  final bool destructive;
}

/// A list of choices on the surface color. Pressing a row runs its action; the
/// popover around it closes itself in the caller's callback.
class AppMenu extends StatelessWidget {
  const AppMenu({super.key, required this.entries});

  final List<MenuEntry> entries;

  /// Wide enough for a status word and its key.
  static const minWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    final marks = entries.any((entry) => entry.selected);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: minWidth),
      child: IntrinsicWidth(
        child: ColoredBox(
          color: Tokens.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in entries) _MenuRow(entry, showMarks: marks),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.entry, {required this.showMarks});

  final MenuEntry entry;
  final bool showMarks;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: entry.onPressed,
      builder: (context, state) {
        final ink = entry.destructive
            ? Tokens.red
            : (state.hovered || state.focused ? Tokens.ink : Tokens.inkSoft);
        return Container(
          height: Tokens.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
          color: state.hovered || state.focused ? Tokens.ground : null,
          child: Row(
            children: [
              if (showMarks)
                SizedBox(
                  width: Tokens.iconSize + Tokens.space2,
                  child: entry.selected
                      ? AppIcon(
                          AppIcons.check,
                          size: Tokens.iconSize,
                          color: ink,
                        )
                      : null,
                ),
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(ink),
                ),
              ),
              if (entry.shortcut != null) ...[
                const SizedBox(width: Tokens.space4),
                Text(
                  entry.shortcut!,
                  style: const TextStyle(
                    fontFamily: Tokens.mono,
                    fontSize: Tokens.text2,
                    color: Tokens.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
