import 'package:flutter/widgets.dart';

import '../../components/app_button.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/entry_progress.dart';
import '../../components/icon_square_button.dart';
import '../../components/menu_switcher.dart';
import '../../components/page_frame.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';
import '../../library/entry_status.dart';

/// The bar fixed at the bottom of the Detail page. On the list it holds the
/// status menu button, minus and plus around the progress, and the count. Off
/// the list it holds an amber "Add to list" that opens the same menu.
class EntryBar extends StatelessWidget {
  const EntryBar({
    super.key,
    required this.statusEntries,
    this.status,
    this.watched = 0,
    this.total,
    this.onMinus,
    this.onPlus,
    this.onStep,
  });

  /// The status menu: the Library's, with its locks.
  final List<MenuEntry> statusEntries;

  /// Null when the title is not on the list.
  final EntryStatus? status;
  final int watched;

  /// Null when MAL does not know the total.
  final int? total;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final ValueChanged<int>? onStep;

  // a menu opens above the bar, clear of its top edge, never over it
  static const _menuGap =
      (Tokens.entryBarHeight - Tokens.controlHeight) / 2 + Tokens.space1;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return Container(
      height: Tokens.entryBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: PageFrame.edge),
      color: Tokens.surface,
      child: status == null ? _add() : _onList(status),
    );
  }

  Widget _add() => Align(
    alignment: Alignment.centerLeft,
    child: AppPopover(
      gap: _menuGap,
      builder: (context, handle) => AppButton(
        label: 'Add to list',
        opensMenu: true,
        menuOpen: handle.isOpen,
        onPressed: handle.open,
      ),
      popoverBuilder: (context, handle) => _menu(handle),
    ),
  );

  Widget _menu(PopoverHandle handle) => AppMenu(
    entries: [
      for (final entry in statusEntries)
        MenuEntry(
          label: entry.label,
          selected: entry.selected,
          dividerAbove: entry.dividerAbove,
          onPressed: entry.onPressed == null
              ? null
              : () {
                  entry.onPressed!();
                  handle.close();
                },
        ),
    ],
  );

  Widget _onList(EntryStatus status) {
    final total = this.total;
    final known = total != null && total > 0;
    return Row(
      children: [
        MenuSwitcher(
          current: status.label,
          entries: statusEntries,
          style: AppText.label(Tokens.ink, bold: true),
          gap: _menuGap,
        ),
        const SizedBox(width: Tokens.space4),
        IconSquareButton(
          icon: AppIcons.minus,
          label: 'One episode less',
          onPressed: onMinus,
        ),
        const SizedBox(width: Tokens.space3),
        Expanded(
          child: known
              ? EntryProgress(watched: watched, total: total, onStep: onStep)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: Tokens.space3),
        IconSquareButton(
          icon: AppIcons.plus,
          label: 'One episode more',
          onPressed: onPlus,
        ),
        const SizedBox(width: Tokens.space4),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: Tokens.space5 * 3),
          child: Text(
            known ? '$watched / $total' : '$watched / ?',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.right,
            style: AppText.tally(Tokens.ink),
          ),
        ),
      ],
    );
  }
}
