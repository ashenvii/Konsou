import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'app_menu.dart';
import 'hover_mark.dart';
import 'hover_popover.dart';
import 'menu_chevron.dart';
import 'pressable.dart';

/// A word (and an optional count) with an amber chevron that opens an
/// [AppMenu] on hover or click. The Library's status heading and its sort
/// button are both this, so they open, close and light up the same way.
class MenuSwitcher extends StatelessWidget {
  const MenuSwitcher({
    super.key,
    required this.current,
    required this.entries,
    required this.style,
    this.count,
    this.footnote,
  });

  final String current;
  final String? count;
  final List<MenuEntry> entries;
  final String? footnote;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return HoverPopover(
      gap: Tokens.space1,
      builder: (context, handle) => Pressable(
        onPressed: handle.open,
        selected: handle.isOpen,
        builder: (context, state) {
          final lit = state.hovered || state.focused || handle.isOpen;
          return HoverMark(
            on: lit,
            child: Container(
              height: Tokens.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: Tokens.space2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(current, maxLines: 1, softWrap: false, style: style),
                  if (count != null) ...[
                    const SizedBox(width: Tokens.space2),
                    Text(
                      count!,
                      maxLines: 1,
                      softWrap: false,
                      style: style.copyWith(
                        fontWeight: FontWeight.w400,
                        color: lit ? Tokens.inkSoft : Tokens.inkMuted,
                      ),
                    ),
                  ],
                  MenuChevron(color: Tokens.amber, open: handle.isOpen),
                ],
              ),
            ),
          );
        },
      ),
      popoverBuilder: (context, handle) => AppMenu(
        entries: [
          for (final entry in entries)
            MenuEntry(
              label: entry.label,
              selected: entry.selected,
              count: entry.count,
              dividerAbove: entry.dividerAbove,
              onPressed: () {
                entry.onPressed?.call();
                handle.close();
              },
            ),
        ],
        footnote: footnote,
      ),
    );
  }
}
