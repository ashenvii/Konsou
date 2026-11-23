import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/cover_well.dart';
import '../../components/one_line_text.dart';
import '../../components/status_lamp.dart';
import '../../components/status_mark.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
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
            CoverWell(
              lit: state.hovered || state.focused,
              child: Stack(
                children: [
                  CoverView(
                    malId: row.malId,
                    width: constraints.maxWidth - CoverWell.inset,
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
              formatTitle(row.name),
              style: AppText.label(
                row.name.isEmpty ? Tokens.inkMuted : Tokens.ink,
                bold: true,
              ),
            ),
            const SizedBox(height: Tokens.space1),
            OneLineText(
              formatTypeYear(row.mediaType, row.startDate),
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
    final count = formatChipCount(row);
    if (!showStatus && count.isEmpty) return const SizedBox.shrink();
    final status = row.status;
    final finished = row.allSeasonsDone;
    // a small dark display on the cover: the lamp, the status mark where the
    // tab mixes statuses, and the count in LED digits
    return DecoratedBox(
      key: const Key('card-chip'),
      decoration: const BoxDecoration(
        color: Tokens.wellFill,
        borderRadius: Tokens.keyCorners,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.space2,
          vertical: Tokens.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusLamp(status, finished: finished),
            if (showStatus) ...[
              const SizedBox(width: Tokens.space1),
              StatusMark(status, green: finished),
            ],
            if (count.isNotEmpty) ...[
              const SizedBox(width: Tokens.space1),
              Text(count, style: AppText.tally(Tokens.ink, size: Tokens.text1)),
            ],
          ],
        ),
      ),
    );
  }
}
