import 'package:flutter/widgets.dart';

import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/info_labels.dart';
import '../../detail/watch_order.dart';
import '../../library/entry_status.dart';
import '../../library/row_labels.dart';
import '../library/row_tap_area.dart';

/// "3 of 5 on your list · 59 of 87 episodes watched".
String watchOrderSummary(WatchOrder order) {
  final total = order.episodesTotal;
  return '${order.onList} of ${order.rows.length} on your list'
      '${total > 0 ? ' · ${order.episodesWatched} of $total episodes watched' : ''}';
}

class WatchOrderSummary extends StatelessWidget {
  const WatchOrderSummary(this.order, {super.key});

  final WatchOrder order;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Tokens.space3),
    child: Text(watchOrderSummary(order), style: AppText.label(Tokens.inkSoft)),
  );
}

/// One title of the franchise: type tag, title, year, episodes, then the
/// user's status and progress, or the reason there is none.
class WatchOrderRowView extends StatelessWidget {
  const WatchOrderRowView({
    super.key,
    required this.row,
    required this.onOpen,
    required this.onContextMenu,
  });

  final WatchOrderRow row;
  final VoidCallback onOpen;
  final ValueChanged<Offset> onContextMenu;

  static const _tagWidth = Tokens.space5 * 3;
  static const _yearWidth = Tokens.space5 * 2;
  static const _episodesWidth = Tokens.space5 * 3;
  static const _statusWidth = Tokens.space5 * 7;

  static const rowHeight = Tokens.controlHeight + Tokens.space3;

  @override
  Widget build(BuildContext context) {
    return RowTapArea(
      onOpen: onOpen,
      onContextMenu: onContextMenu,
      builder: (context, state) => HoverMark(
        on: state.hovered || state.focused,
        child: Container(
          height: rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
          child: Row(
            children: [
              SizedBox(
                width: _tagWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TypeTag(row.mediaType, isExtra: row.isExtra),
                ),
              ),
              Expanded(
                child: OneLineText(
                  row.name.isEmpty ? 'Loading details' : row.name,
                  style: AppText.label(
                    row.name.isEmpty ? Tokens.inkMuted : Tokens.ink,
                    bold: row.isOpenTitle,
                  ),
                ),
              ),
              SizedBox(
                width: _yearWidth,
                child: OneLineText(
                  _year(row.startDate),
                  align: TextAlign.right,
                  style: AppText.tally(Tokens.inkSoft, size: Tokens.text1),
                ),
              ),
              SizedBox(
                width: _episodesWidth,
                child: OneLineText(
                  row.episodes == null ? '' : '${row.episodes} ep',
                  align: TextAlign.right,
                  style: AppText.tally(Tokens.inkSoft, size: Tokens.text1),
                ),
              ),
              const SizedBox(width: Tokens.space4),
              SizedBox(width: _statusWidth, child: _Status(row)),
            ],
          ),
        ),
      ),
    );
  }

  static String _year(String? date) =>
      date != null && date.length >= 4 ? date.substring(0, 4) : '';
}

class _Status extends StatelessWidget {
  const _Status(this.row);

  final WatchOrderRow row;

  @override
  Widget build(BuildContext context) {
    final String text;
    var color = Tokens.inkSoft;
    if (row.isLoadingDetails) {
      // with no name yet the title already says it
      text = row.name.isEmpty ? '' : 'Loading details';
      color = Tokens.inkMuted;
    } else if (row.isNotAired) {
      text = 'Not aired yet · ${dateWords(row.startDate) ?? 'TBA'}';
      color = Tokens.inkMuted;
    } else if (row.status == null) {
      text = '';
    } else {
      // the counter itself: a rewatch shows how far the rewatch is
      final progress = episodeProgress(row.episodesWatched, row.episodes);
      text = [
        row.status!.label,
        if (progress.isNotEmpty && row.status != EntryStatus.completed)
          progress,
      ].join(' · ');
    }
    return OneLineText(text, style: AppText.caption(color));
  }
}

/// The small type label: green for TV and seasons, amber for the rest.
class TypeTag extends StatelessWidget {
  const TypeTag(this.mediaType, {super.key, required this.isExtra});

  final String? mediaType;
  final bool isExtra;

  @override
  Widget build(BuildContext context) {
    final label = _label(mediaType);
    final story = mediaType == 'tv' && !isExtra;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.space2,
        vertical: Tokens.space1,
      ),
      color: Tokens.surface,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AppText.caption(story ? Tokens.mint : Tokens.amber)
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  static String _label(String? type) => switch (type) {
    null || '' => '?',
    final type => typeName(type),
  };
}
