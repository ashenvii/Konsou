import 'package:flutter/widgets.dart';

import '../../components/app_button.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/entry_progress.dart';
import '../../components/icon_square_button.dart';
import '../../components/menu_switcher.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';
import '../../library/entry_status.dart';
import 'episode_count.dart';

/// The user's own controls for a title, under its name on the Detail page.
/// On the list: the status menu button, the progress with minus and plus
/// side by side at its right, and centred under the progress the count and
/// its pencil. Off the list: a pop "Add to list" that opens the same
/// menu. [statusOnly] keeps just the status button, for the jump bar.
class EntryControls extends StatelessWidget {
  const EntryControls({
    super.key,
    required this.statusEntries,
    this.status,
    this.watched = 0,
    this.total,
    this.onMinus,
    this.onPlus,
    this.onStep,
    this.episodeLimit,
    this.statusOnly = false,
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

  /// The episodes that have aired, asked when a number is typed.
  final ValueGetter<int?>? episodeLimit;
  final bool statusOnly;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null) return _add();
    final switcher = MenuSwitcher(
      current: status.label,
      entries: statusEntries,
      style: AppText.label(Tokens.ink, bold: true),
      gap: Tokens.space1,
      raised: true,
    );
    if (statusOnly) return switcher;
    final total = this.total;
    final known = total != null && total > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        switcher,
        const SizedBox(width: Tokens.space4),
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: Tokens.controlHeight,
                child: Center(
                  child: known
                      ? EntryProgress(
                          watched: watched,
                          total: total,
                          onStep: onStep,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              // the count reads with the bar it counts, so it sits right under
              // its middle, with the pencil beside it
              const SizedBox(height: Tokens.space2),
              EpisodeCount(
                watched: watched,
                total: total,
                onSet: onStep,
                limit: episodeLimit,
              ),
            ],
          ),
        ),
        const SizedBox(width: Tokens.space3),
        IconSquareButton(
          icon: AppIcons.minus,
          label: 'One episode less',
          onPressed: onMinus,
        ),
        const SizedBox(width: Tokens.space1),
        IconSquareButton(
          icon: AppIcons.plus,
          label: 'One episode more',
          onPressed: onPlus,
        ),
      ],
    );
  }

  Widget _add() => Align(
    alignment: Alignment.centerLeft,
    widthFactor: 1,
    child: AppPopover(
      gap: Tokens.space1,
      builder: (context, handle) => AppButton(
        label: 'Add to list',
        opensMenu: true,
        menuOpen: handle.isOpen,
        onPressed: handle.open,
      ),
      popoverBuilder: (context, handle) => AppMenu(
        entries: [
          for (final entry in statusEntries) entry.thenRun(handle.close),
        ],
      ),
    ),
  );
}
