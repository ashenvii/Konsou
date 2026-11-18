import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/cover_view.dart';
import '../../components/app_button.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../components/pressable.dart';
import '../../components/status_menu_entries.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/watch_order.dart';
import 'detail_block.dart';
import 'watch_order_strip.dart';

/// The title to watch after this one, under the user's controls: its cover,
/// type, name, year and episodes, and why it is next. A click opens it; a
/// title not on the list has an Add that opens the status menu.
class NextUpRow extends ConsumerWidget {
  const NextUpRow({super.key, required this.row, required this.onOpen});

  final WatchOrderRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DetailHeading('Next up'),
        const SizedBox(height: Tokens.space2),
        Pressable(
          label: 'Open ${row.name}',
          onPressed: onOpen,
          builder: (context, state) => HoverMark(
            on: state.hovered || state.focused,
            child: Container(
              color: Tokens.surface,
              padding: const EdgeInsets.all(Tokens.space2),
              child: Row(
                children: [
                  CoverView(malId: row.malId, width: Tokens.listCoverWidth),
                  const SizedBox(width: Tokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OneLineText(
                          row.name,
                          style: AppText.label(Tokens.ink, bold: true),
                        ),
                        const SizedBox(height: Tokens.space1),
                        OneLineText(
                          watchOrderMeta(row),
                          style: AppText.caption(Tokens.inkMuted),
                        ),
                        const SizedBox(height: Tokens.space1),
                        OneLineText(
                          nextUpReason(row),
                          style: AppText.caption(Tokens.amber),
                        ),
                      ],
                    ),
                  ),
                  if (row.entryId == null) ...[
                    const SizedBox(width: Tokens.space3),
                    AppPopover(
                      gap: Tokens.space1,
                      builder: (context, handle) => AppButton(
                        label: 'Add',
                        kind: ButtonKind.secondary,
                        opensMenu: true,
                        menuOpen: handle.isOpen,
                        onPressed: handle.open,
                      ),
                      popoverBuilder: (context, handle) => AppMenu(
                        entries: statusMenuEntries(
                          onPick: (status) {
                            setOrAdd(ref, row, status);
                            handle.close();
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
