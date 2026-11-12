import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../components/status_mark.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import '../../library/row_labels.dart';
import 'row_tap_area.dart';

class LibraryGridCard extends StatelessWidget {
  const LibraryGridCard({
    super.key,
    required this.row,
    required this.showStatus,
    required this.onOpen,
    required this.onContextMenu,
  });

  final LibraryRow row;

  final bool showStatus;
  final VoidCallback onOpen;

  final ValueChanged<Offset> onContextMenu;

  @override
  Widget build(BuildContext context) {
    return RowTapArea(
      onOpen: onOpen,
      onContextMenu: onContextMenu,
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HoverMark(
              on: state.hovered || state.focused,
              child: Stack(
                children: [
                  CoverView(
                    malId: row.malId,
                    width: constraints.maxWidth,
                    loading: row.isLoadingDetails,
                  ),
                  Positioned(
                    left: Tokens.space2,
                    top: Tokens.space2,
                    child: _Chip(row: row, showStatus: showStatus),
                  ),
                ],
              ),
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
    );
  }
}

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
              Text(count, style: AppText.tally(Tokens.ink, size: Tokens.text2)),
          ],
        ),
      ),
    );
  }
}
