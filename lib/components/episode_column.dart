import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../library/entry_status.dart';
import 'count_style.dart';
import 'one_line_text.dart';
import 'status_lamp.dart';
import 'status_mark.dart';
import 'value_column.dart';

/// A row's episode column: the count over the lamp and the status word. On a
/// tab of one status the lamp stands alone, since the tab names it; in a
/// [narrow] row the word becomes the status mark. A title not on your list
/// ([status] null) has the count over nothing.
class EpisodeColumn extends StatelessWidget {
  const EpisodeColumn({
    super.key,
    required this.count,
    this.status,
    this.finished = true,
    this.showStatus = true,
    this.narrow = false,
  });

  /// Wide enough for "12 / 24 seasons" at the value size.
  static const width = Tokens.space5 * 6;

  /// A row narrower than three grid cards is [narrow].
  static const narrowBelow = Tokens.gridCardMinWidth * 3;

  final String count;
  final EntryStatus? status;

  /// Off for a Completed franchise with a season left, so it does not light.
  final bool finished;

  /// A tab that mixes statuses.
  final bool showStatus;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return ValueColumn(
      width: width,
      value: OneLineText(
        count,
        style: chooseCountStyle(status, size: Tokens.text2),
      ),
      label: status == null
          ? null
          : Row(
              children: [
                StatusLamp(status, finished: finished),
                if (showStatus) ...[
                  const SizedBox(width: Tokens.space1),
                  if (narrow)
                    StatusMark(status, green: finished)
                  else
                    Flexible(
                      child: OneLineText(
                        status.label,
                        style: AppText.caption(Tokens.inkMuted),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
