import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../library/entry_status.dart';
import '../library/row_labels.dart';
import 'count_display.dart';
import 'one_line_text.dart';
import 'value_column.dart';

/// A Quick search row's episode column: the count display over the status
/// word. A title not on your list ([status] null) has the count alone.
class EpisodeColumn extends StatelessWidget {
  const EpisodeColumn({super.key, required this.count, this.status});

  /// Wide enough for "12 / 24 seasons" at the value size.
  static const width = Tokens.space5 * 6;

  /// A row narrower than three grid cards is narrow.
  static const narrowBelow = Tokens.gridCardMinWidth * 3;

  final CardCount count;
  final EntryStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return ValueColumn(
      width: width,
      value: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(fit: BoxFit.scaleDown, child: CountDisplay.of(count)),
      ),
      label: status == null
          ? null
          : OneLineText(status.label, style: AppText.caption(Tokens.inkSoft)),
    );
  }
}
