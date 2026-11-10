import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/app_checkbox.dart';
import '../../components/one_line_text.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/score_star.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import '../../library/row_labels.dart';
import 'row_tap_area.dart';

/// One entry (or one franchise standing for its current season) in the
/// Library's list view. Left to right: the box that completes it, the cover,
/// the title with its small line, then the status word (only on the All tab),
/// progress, score and the menu. In a narrow row the status word moves into
/// the small line.
class LibraryListRow extends StatelessWidget {
  const LibraryListRow({
    super.key,
    required this.row,
    required this.showStatus,
    required this.onOpen,
    required this.onCheck,
    required this.onContextMenu,
    required this.menu,
  });

  final LibraryRow row;

  /// On for the All tab; every row of another tab has the same status.
  final bool showStatus;
  final VoidCallback onOpen;

  /// The box was pressed: true to complete, false to put it back.
  final ValueChanged<bool> onCheck;

  /// A right click or a long press, with the position in window coordinates.
  final ValueChanged<Offset> onContextMenu;

  /// The button at the end that opens the menu; the screen builds it.
  final Widget menu;

  // Columns on the right keep their widths so the rows line up.
  static const _statusWidth = Tokens.space5 * 5;
  static const _progressWidth = Tokens.space5 * 3;
  static const _scoreWidth = Tokens.space5 * 2;

  /// Below this width the status word has no column of its own.
  static const _narrow = Tokens.gridCardMinWidth * 3;

  @override
  Widget build(BuildContext context) {
    final completed = row.status == EntryStatus.completed.value;
    final status = EntryStatus.parse(row.status).label;
    return RowTapArea(
      onOpen: onOpen,
      onContextMenu: onContextMenu,
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < _narrow;
          final line = [
            typeYearLine(row),
            seasonsText(row),
            if (showStatus && narrow) status,
          ].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
          return Container(
            height: Tokens.listRowHeight,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
            color: state.hovered || state.focused ? Tokens.surface : null,
            child: Row(
              children: [
                AppCheckbox(
                  value: completed ? CheckValue.checked : CheckValue.empty,
                  onChanged: (value) => onCheck(value == CheckValue.checked),
                ),
                const SizedBox(width: Tokens.space3),
                CoverView(malId: row.malId, width: Tokens.listCoverWidth),
                const SizedBox(width: Tokens.space3),
                Expanded(
                  child: _Titles(row: row, line: line),
                ),
                if (showStatus && !narrow)
                  SizedBox(
                    width: _statusWidth,
                    child: OneLineText(
                      status,
                      style: AppText.caption(Tokens.inkSoft),
                    ),
                  ),
                SizedBox(
                  width: _progressWidth,
                  child: OneLineText(
                    progressText(row),
                    align: TextAlign.right,
                    style: AppText.figure(Tokens.inkSoft),
                  ),
                ),
                SizedBox(width: _scoreWidth, child: _Score(row.score)),
                menu,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.row, required this.line});

  final LibraryRow row;
  final String line;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OneLineText(
          titleText(row),
          style: AppText.label(row.name.isEmpty ? Tokens.inkMuted : Tokens.ink),
        ),
        const SizedBox(height: Tokens.space2),
        Row(
          children: [
            Flexible(
              child: OneLineText(line, style: AppText.caption(Tokens.inkMuted)),
            ),
            if (row.isNotLinked) ...[
              const SizedBox(width: Tokens.space2),
              Flexible(
                child: OneLineText(
                  'Not linked',
                  style: AppText.caption(Tokens.inkSoft),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  const _Score(this.score);

  final int? score;

  @override
  Widget build(BuildContext context) {
    final score = this.score;
    if (score == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ScoreStar(size: Tokens.iconSize, color: Tokens.amber),
        const SizedBox(width: Tokens.space1),
        Text('$score', style: AppText.figure(Tokens.ink)),
      ],
    );
  }
}
