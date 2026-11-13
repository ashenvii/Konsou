import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/app_checkbox.dart';
import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/score_star.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import '../../library/row_labels.dart';
import 'row_tap_area.dart';

class LibraryListRow extends StatefulWidget {
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

  final bool showStatus;
  final VoidCallback onOpen;

  final ValueChanged<bool> onCheck;

  final ValueChanged<Offset> onContextMenu;

  final Widget menu;

  // columns on the right keep their widths so the rows line up.
  static const _statusWidth = Tokens.space5 * 5;
  static const _progressWidth = Tokens.space5 * 3;
  static const _scoreWidth = Tokens.space5 * 2;

  static const _narrow = Tokens.gridCardMinWidth * 3;

  @override
  State<LibraryListRow> createState() => _LibraryListRowState();
}

class _LibraryListRowState extends State<LibraryListRow> {
  // the pointer is on the checkbox: it takes the hover mark, the row gives it up
  bool _overBox = false;

  static const _statusWidth = LibraryListRow._statusWidth;
  static const _progressWidth = LibraryListRow._progressWidth;
  static const _scoreWidth = LibraryListRow._scoreWidth;
  static const _narrow = LibraryListRow._narrow;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final showStatus = widget.showStatus;
    final completed = row.status == EntryStatus.completed.value;
    final status = EntryStatus.parse(row.status).label;
    return RowTapArea(
      onOpen: widget.onOpen,
      onContextMenu: widget.onContextMenu,
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < _narrow;
          final line = [
            typeYearLine(row),
            seasonsText(row),
            if (showStatus && narrow) status,
          ].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
          return HoverMark(
            on: (state.hovered || state.focused) && !_overBox,
            child: Container(
              height: Tokens.listRowHeight,
              padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
              child: Row(
                children: [
                  AppCheckbox(
                    value: completed ? CheckValue.checked : CheckValue.empty,
                    onChanged: (value) =>
                        widget.onCheck(value == CheckValue.checked),
                    onHover: (over) => setState(() => _overBox = over),
                  ),
                  const SizedBox(width: Tokens.space3),
                  CoverView(
                    malId: row.malId,
                    width: Tokens.listCoverWidth,
                    loading: row.isLoadingDetails,
                  ),
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
                      style: AppText.tally(Tokens.inkSoft, size: Tokens.text2),
                    ),
                  ),
                  SizedBox(width: _scoreWidth, child: _Score(row.score)),
                  widget.menu,
                ],
              ),
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
    const muted = Tokens.inkMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OneLineText(
          titleText(row),
          style: AppText.label(row.name.isEmpty ? muted : Tokens.ink),
        ),
        const SizedBox(height: Tokens.space2),
        Row(
          children: [
            Flexible(child: OneLineText(line, style: AppText.caption(muted))),
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
        Text('$score', style: AppText.tally(Tokens.ink, size: Tokens.text2)),
      ],
    );
  }
}
