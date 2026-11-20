import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'app_popover.dart';
import 'floating_panel.dart';
import 'hairline.dart';
import 'hover_mark.dart';
import 'menu_chevron.dart';
import 'pressable.dart';
import 'text_action.dart';
import 'icon_square_button.dart';
import '../icons/app_icons.dart';
import '../library/row_labels.dart';

const _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

/// "14 Nov 2026".
String formatDate(DateTime date) =>
    '${date.day} ${monthName(date.month, short: true)} ${date.year}';

/// A button showing a date that opens a month grid, with a Clear row. Flutter's
/// own date picker is a Material dialog, so it is not used.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.latest,
    this.fill = Tokens.surface,
  });

  final DateTime? value;

  /// The field's color; the ground when it sits on a filled plate.
  final Color fill;
  final ValueChanged<DateTime?> onChanged;

  /// The last day that can be picked. Null allows any day.
  final DateTime? latest;

  @override
  Widget build(BuildContext context) {
    return AppPopover(
      gap: Tokens.space1,
      builder: (context, handle) => Pressable(
        onPressed: handle.open,
        selected: handle.isOpen,
        builder: (context, state) => HoverMark(
          on: state.hovered || state.focused || handle.isOpen,
          child: Container(
            width: Tokens.findFieldWidth,
            height: Tokens.controlHeight,
            padding: const EdgeInsets.only(left: Tokens.space3),
            color: fill,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? 'Not set' : formatDate(value!),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      value == null ? Tokens.inkSoft : Tokens.ink,
                    ),
                  ),
                ),
                MenuChevron(color: Tokens.pop, open: handle.isOpen),
                const SizedBox(width: Tokens.space2),
              ],
            ),
          ),
        ),
      ),
      popoverBuilder: (context, handle) => FloatingPanel(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthGrid(
                selected: value,
                latest: latest,
                onPicked: (date) {
                  onChanged(date);
                  handle.close();
                },
              ),
              const Hairline(),
              Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(
                  child: TextAction(
                    label: 'Clear',
                    onPressed: value == null
                        ? null
                        : () {
                            onChanged(null);
                            handle.close();
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One month of days, Monday first, with arrows to move between months.
class _MonthGrid extends StatefulWidget {
  const _MonthGrid({
    required this.selected,
    required this.onPicked,
    this.latest,
  });

  final DateTime? selected;
  final DateTime? latest;
  final ValueChanged<DateTime> onPicked;

  @override
  State<_MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<_MonthGrid> {
  late DateTime _month = _firstOf(
    widget.selected ?? widget.latest ?? DateTime.now(),
  );

  static DateTime _firstOf(DateTime d) => DateTime(d.year, d.month);

  void _move(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    const cell = Tokens.controlHeight;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    // DateTime.weekday is 1 for Monday
    final lead = _month.weekday - 1;
    final today = DateTime.now();
    final selected = widget.selected;
    final latest = widget.latest;
    final isLastMonth = latest != null && !_month.isBefore(_firstOf(latest));
    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    return Padding(
      padding: const EdgeInsets.all(Tokens.space2),
      child: SizedBox(
        width: cell * 7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconSquareButton(
                  icon: AppIcons.chevronLeft,
                  label: 'Previous month',
                  onPressed: () => _move(-1),
                ),
                Expanded(
                  child: Text(
                    '${monthName(_month.month)} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: AppText.label(Tokens.ink, bold: true),
                  ),
                ),
                IconSquareButton(
                  icon: AppIcons.chevronRight,
                  label: 'Next month',
                  onPressed: isLastMonth ? null : () => _move(1),
                ),
              ],
            ),
            Row(
              children: [
                for (final day in _weekdays)
                  SizedBox(
                    width: cell,
                    height: cell,
                    child: Center(
                      child: Text(day, style: AppText.caption(Tokens.inkSoft)),
                    ),
                  ),
              ],
            ),
            for (var week = 0; week < (lead + days + 6) ~/ 7; week++)
              Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    _cellFor(
                      week * 7 + col - lead + 1,
                      days,
                      today,
                      selected,
                      same,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _cellFor(
    int day,
    int days,
    DateTime today,
    DateTime? selected,
    bool Function(DateTime, DateTime) same,
  ) {
    const cell = Tokens.controlHeight;
    if (day < 1 || day > days) return const SizedBox(width: cell, height: cell);
    final date = DateTime(_month.year, _month.month, day);
    final isSelected = selected != null && same(date, selected);
    final isToday = same(date, today);
    final latest = widget.latest;
    final allowed = latest == null || !date.isAfter(latest);
    return Pressable(
      label: formatDate(date),
      selected: isSelected,
      onPressed: allowed ? () => widget.onPicked(date) : null,
      builder: (context, state) => HoverMark(
        on: state.hovered && !isSelected,
        child: Container(
          width: cell,
          height: cell,
          alignment: Alignment.center,
          color: isSelected ? Tokens.pop : null,
          child: Text(
            '$day',
            style:
                AppText.tally(
                  isSelected
                      ? Tokens.ground
                      : !allowed
                      ? Tokens.inkMuted
                      : (isToday ? Tokens.support : Tokens.ink),
                ).copyWith(
                  fontWeight: isSelected || isToday ? FontWeight.w700 : null,
                ),
          ),
        ),
      ),
    );
  }
}
