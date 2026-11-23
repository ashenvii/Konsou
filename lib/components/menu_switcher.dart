import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'app_menu.dart';
import 'cap_centered_text.dart';
import 'hover_mark.dart';
import 'hover_popover.dart';
import 'menu_chevron.dart';
import 'pressable.dart';
import 'raised_key.dart';

/// A word (and an optional count) with a pop chevron that opens an
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
    this.gap = Tokens.space1,
    this.raised = false,
  });

  /// Drawn as a raised key, as the sort and the status button are. Off for
  /// the Library's big status heading, which is a word, not a key.
  final bool raised;

  final String current;
  final String? count;
  final List<MenuEntry> entries;
  final String? footnote;
  final TextStyle style;

  /// The space between the word and its menu.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return HoverPopover(
      gap: gap,
      builder: (context, handle) => Pressable(
        onPressed: handle.open,
        expanded: handle.isOpen,
        builder: (context, state) {
          final lit = state.hovered || state.focused || handle.isOpen;
          final content = Container(
            height: Tokens.controlHeight,
            padding: EdgeInsets.symmetric(
              horizontal: raised ? Tokens.space3 : Tokens.space2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CapCenteredText(current, style: style),
                if (count != null) ...[
                  const SizedBox(width: Tokens.space2),
                  CapCenteredText(
                    count!,
                    style: style.copyWith(
                      fontWeight: FontWeight.w400,
                      color: lit ? Tokens.inkSoft : Tokens.inkMuted,
                    ),
                  ),
                ],
                MenuChevron(color: Tokens.pop, open: handle.isOpen),
              ],
            ),
          );
          if (raised) {
            return RaisedKey(lit: lit, sunk: state.pressed, child: content);
          }
          return HoverMark(on: lit, child: content);
        },
      ),
      popoverBuilder: (context, handle) => AppMenu(
        entries: [for (final entry in entries) entry.thenRun(handle.close)],
        footnote: footnote,
      ),
    );
  }
}
