import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../library/entry_status.dart';
import '../library/row_labels.dart';
import 'count_display.dart';
import 'season_cap.dart';
import 'status_mark.dart';

/// The strip under a card's cover: the status icon at the left, the count
/// display at the right with a franchise's season cap in front of it. A title
/// not on your list, or a card on a tab of one status, has no icon
/// ([status] null). The count shrinks to fit a narrow card, never cut.
class CardFoot extends StatelessWidget {
  const CardFoot({super.key, required this.count, this.status, this.season});

  final CardCount count;
  final EntryStatus? status;

  /// The franchise season the card stands for (`LibraryRow.seasonNumber`).
  final int? season;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    final season = this.season;
    return SizedBox(
      height: Tokens.cardFootHeight,
      child: Row(
        children: [
          if (status != null) ...[
            Semantics(
              label: status.label,
              excludeSemantics: true,
              child: StatusMark(status, color: Tokens.inkSoft),
            ),
            const SizedBox(width: Tokens.space2),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (season != null) ...[
                      SeasonCap(season),
                      const SizedBox(width: Tokens.space2),
                    ],
                    CountDisplay.of(count),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
