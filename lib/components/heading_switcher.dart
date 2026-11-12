import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'app_menu.dart';
import 'hover_mark.dart';
import 'hover_popover.dart';
import 'menu_chevron.dart';
import 'pressable.dart';

class HeadingSwitcher extends StatelessWidget {
  const HeadingSwitcher({
    super.key,
    required this.title,
    required this.current,
    required this.count,
    required this.entries,
    this.footnote,
  });

  final String title;
  final String current;
  final String? count;
  final List<MenuEntry> entries;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final base = AppText.heading.copyWith(
      fontFeatures: AppText.tally(Tokens.ink).fontFeatures,
    );
    return SizedBox(
      height: Tokens.controlHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            softWrap: false,
            style: base.copyWith(
              fontWeight: FontWeight.w400,
              color: Tokens.inkMuted,
            ),
          ),
          const SizedBox(width: Tokens.space2),
          HoverPopover(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.space2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          current,
                          maxLines: 1,
                          softWrap: false,
                          style: base,
                        ),
                        if (count != null) ...[
                          const SizedBox(width: Tokens.space2),
                          Text(
                            count!,
                            maxLines: 1,
                            softWrap: false,
                            style: base.copyWith(
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
          ),
        ],
      ),
    );
  }
}
