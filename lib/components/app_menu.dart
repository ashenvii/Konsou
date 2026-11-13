import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'floating_panel.dart';
import 'hairline.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'hold_row.dart';
import 'hover_mark.dart';
import 'key_cap.dart';
import 'pressable.dart';

class MenuEntry {
  const MenuEntry({
    required this.label,
    required this.onPressed,
    this.shortcut,
    this.selected = false,
    this.destructive = false,
    this.count,
    this.dividerAbove = false,
    this.hold = false,
    this.holdHint,
  });

  final String label;
  final VoidCallback? onPressed;

  final String? shortcut;

  final bool selected;

  final bool destructive;

  final String? count;

  final bool dividerAbove;

  final bool hold;

  final String? holdHint;
}

class AppMenu extends StatelessWidget {
  const AppMenu({super.key, required this.entries, this.footnote});

  final List<MenuEntry> entries;

  final String? footnote;

  static const holdTime = Duration(seconds: 1);

  static const minWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    final marks = entries.any((entry) => entry.selected);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: minWidth),
      child: IntrinsicWidth(
        // it floats over the page, so it has the raised fill and a hairline
        child: FloatingPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in entries) ...[
                if (entry.dividerAbove) const Hairline(),
                entry.hold
                    ? HoldRow(
                        label: entry.label,
                        holdTime: AppMenu.holdTime,
                        onDone: entry.onPressed,
                        hint: entry.holdHint,
                      )
                    : _MenuRow(entry, showMarks: marks),
              ],
              if (footnote != null) ...[
                const Hairline(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.space3,
                    vertical: Tokens.space2,
                  ),
                  // soft ink: muted ink on the surface fill is under 4.5:1
                  child: Text(
                    footnote!,
                    style: AppText.caption(Tokens.inkSoft),
                  ),
                ),
              ],
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
        final ink = entry.destructive ? Tokens.red : Tokens.ink;
        return HoverMark(
          on: state.hovered || state.focused,
          child: Container(
            height: Tokens.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
            child: Row(
              children: [
                if (showMarks)
                  SizedBox(
                    width: Tokens.iconSize + Tokens.space4,
                    child: entry.selected
                        // the label's capitals sit above the line box's middle
                        ? Padding(
                            padding: const EdgeInsets.only(
                              bottom: Tokens.space4,
                            ),
                            child: AppIcon(
                              AppIcons.check,
                              size: Tokens.iconSize,
                              color: entry.destructive ? ink : Tokens.amber,
                            ),
                          )
                        : null,
                  ),
                Expanded(
                  child: Text(
                    entry.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(ink, bold: entry.selected),
                  ),
                ),
                if (entry.count != null) ...[
                  const SizedBox(width: Tokens.space4),
                  Text(
                    entry.count!,
                    style: AppText.tally(
                      entry.selected ? Tokens.ink : Tokens.inkSoft,
                    ),
                  ),
                ],
                if (entry.shortcut != null) ...[
                  const SizedBox(width: Tokens.space4),
                  KeyCaps(entry.shortcut!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
