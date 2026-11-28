import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import '../../icons/score_star.dart';
import '../../library/count_format.dart';
import 'detail_section.dart';
import 'section_note.dart';

/// MAL's numbers behind the top's facts: how many scored it and how many
/// have it on a list, then how those lists split, each status a chip with
/// its count over one thin bar of the whole.
class StatsPart extends StatelessWidget {
  const StatsPart({super.key, required this.details});

  final TitleDetails details;

  static bool hasAny(TitleDetails details) =>
      details.scoredBy != null ||
      details.listUsers != null ||
      details.listCounts != null;

  @override
  Widget build(BuildContext context) {
    final counts = details.listCounts;
    final scoredBy = details.scoredBy;
    final members = details.listUsers;
    final statuses = counts == null
        ? const <(String, int, Color)>[]
        : [
            ('Watching', counts.watching, Tokens.ink),
            ('Completed', counts.completed, Tokens.inkSoft),
            ('On hold', counts.onHold, Tokens.pop),
            ('Dropped', counts.dropped, Tokens.red),
            ('Plan to watch', counts.planned, Tokens.line),
          ];
    final total = statuses.fold(0, (sum, line) => sum + line.$2);
    return DetailSection(
      title: 'Stats',
      aside: const SectionNote('On MyAnimeList'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Tokens.space5 + Tokens.space4,
            runSpacing: Tokens.space4,
            children: [
              if (scoredBy != null)
                _Figure(
                  icon: const ScoreStar(
                    size: Tokens.iconSize,
                    color: Tokens.inkMuted,
                  ),
                  value: formatCount(scoredBy),
                  label: 'scored it',
                ),
              if (members != null)
                _Figure(
                  icon: const AppIcon(
                    AppIcons.people,
                    size: Tokens.iconSize,
                    color: Tokens.inkMuted,
                  ),
                  value: formatCount(members),
                  label: 'have it on a list',
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: Tokens.space5),
            _StatusChips(statuses: statuses, total: total),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.icon, required this.value, required this.label});

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: Tokens.space3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.tally(Tokens.ink, size: Tokens.text3)),
            const SizedBox(height: Tokens.space1),
            Text(label, style: AppText.caption(Tokens.inkMuted)),
          ],
        ),
      ],
    );
  }
}

/// One chip per list status, as many to a row as fit, over a bar that
/// splits the whole by the same colors.
class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.statuses, required this.total});

  final List<(String, int, Color)> statuses;
  final int total;

  static const _gap = Tokens.space1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth;
        final perRow = ((room + _gap) / (Tokens.peekItemMinWidth + _gap))
            .floor()
            .clamp(1, statuses.length);
        final width = (room - (perRow - 1) * _gap) / perRow;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final (label, count, color) in statuses)
                  SizedBox(
                    width: width,
                    child: _Chip(
                      label: label,
                      count: count,
                      share: count / total,
                      color: color,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: _gap),
            SizedBox(
              height: Tokens.space1,
              child: Row(
                children: [
                  for (final (_, count, color) in statuses)
                    if (count > 0)
                      Expanded(
                        flex: count,
                        child: ColoredBox(color: color),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.share,
    required this.color,
  });

  final String label;
  final int count;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = share * 100;
    // a status too small to round to 1% still shows it is there
    final shown = percent > 0 && percent < 1 ? '<1%' : '${percent.round()}%';
    return Container(
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: Tokens.raised,
        border: Border(
          top: BorderSide(color: color, width: Tokens.hoverEdge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption(Tokens.inkMuted)),
          const SizedBox(height: Tokens.space2),
          Text(
            formatCount(count),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: AppText.tally(Tokens.inkSoft),
          ),
          const SizedBox(height: Tokens.space1),
          Text(shown, style: AppText.caption(Tokens.inkMuted)),
        ],
      ),
    );
  }
}
