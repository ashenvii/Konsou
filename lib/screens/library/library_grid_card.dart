import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/one_line_text.dart';
import '../../components/pressable.dart';
import '../../components/status_mark.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import '../../library/row_labels.dart';

/// One entry (or franchise) as a cover card in the Library's grid view. The
/// card is as wide as the grid gives it and the cover fills that width.
class LibraryGridCard extends StatelessWidget {
  const LibraryGridCard({
    super.key,
    required this.row,
    required this.showStatus,
    required this.onOpen,
    required this.onContextMenu,
  });

  final LibraryRow row;

  /// On for the All tab: the chip then starts with the status mark.
  final bool showStatus;
  final VoidCallback onOpen;

  /// A right click, with the pointer position in window coordinates.
  final ValueChanged<Offset> onContextMenu;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onOpen,
      builder: (context, state) => GestureDetector(
        onSecondaryTapDown: (details) => onContextMenu(details.globalPosition),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CoverView(malId: row.malId, width: constraints.maxWidth),
                  Positioned(
                    left: Tokens.space2,
                    top: Tokens.space2,
                    child: _Chip(row: row, showStatus: showStatus),
                  ),
                ],
              ),
              const SizedBox(height: Tokens.space2),
              OneLineText(
                titleText(row),
                style: AppText.label(
                  row.name.isEmpty ? Tokens.inkMuted : Tokens.ink,
                  bold: true,
                ),
              ),
              const SizedBox(height: Tokens.space1),
              OneLineText(
                typeYearLine(row),
                style: AppText.caption(Tokens.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The black chip over the cover's corner: the status mark on the All tab, and
/// the count. Nothing is drawn when there is neither.
class _Chip extends StatelessWidget {
  const _Chip({required this.row, required this.showStatus});

  final LibraryRow row;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final count = chipCount(row);
    if (!showStatus && count.isEmpty) return const SizedBox.shrink();
    // A franchise is green only when every season is done.
    final finished = !row.isFranchise || row.seasonsDone == row.seasonsTotal;
    return ColoredBox(
      key: const Key('card-chip'),
      color: Tokens.ground,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.space2,
          vertical: Tokens.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showStatus)
              StatusMark(EntryStatus.parse(row.status), green: finished),
            if (showStatus && count.isNotEmpty)
              const SizedBox(width: Tokens.space1),
            if (count.isNotEmpty)
              Text(count, style: AppText.figure(Tokens.ink)),
          ],
        ),
      ),
    );
  }
}
