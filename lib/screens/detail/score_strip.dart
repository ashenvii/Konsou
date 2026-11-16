import 'package:flutter/widgets.dart';

import '../../components/floating_panel.dart';
import '../../components/hover_popover.dart';
import '../../components/pressable.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import '../../icons/icon_def.dart';
import '../../icons/score_star.dart';
import '../../library/count_format.dart';

/// The MAL score, its star beside the number over a "MAL score" footer, then
/// a row of facts, each with its icon, parted by thin lines: rank, popularity,
/// completed share and episodes. Hovering the completed share shows the list
/// counts. On a narrow page the facts wrap into a grid.
class ScoreStrip extends StatelessWidget {
  const ScoreStrip({super.key, required this.details});

  final TitleDetails details;

  static bool hasAnything(TitleDetails details) =>
      details.score != null ||
      details.rank != null ||
      details.popularity != null ||
      (details.episodes ?? 0) > 0 ||
      _counts(details).isNotEmpty;

  static List<(String, String)> _counts(TitleDetails details) {
    final counts = details.listCounts;
    if (counts == null) return const [];
    return [
      ('Watching', formatCount(counts.watching)),
      ('Completed', formatCount(counts.completed)),
      ('On hold', formatCount(counts.onHold)),
      ('Dropped', formatCount(counts.dropped)),
      ('Planned', formatCount(counts.planned)),
    ];
  }

  // Under this width the facts wrap into a grid, with no lines between them.
  static const _rowWidth = Tokens.space4 * 42;

  @override
  Widget build(BuildContext context) {
    final score = details.score;
    final share = details.completedShare;
    final episodes = details.episodes;
    final counts = _counts(details);
    Widget? completed = share != null && share > 0
        ? _Fact(
            icon: AppIcons.done,
            label: 'Completed',
            value: '${(share * 100).round()}%',
          )
        : null;
    if (completed != null && counts.isNotEmpty) {
      final fact = completed;
      // the list counts sit behind the completed share
      completed = HoverPopover(
        gap: Tokens.space1,
        builder: (context, handle) => Pressable(
          label: 'List counts',
          onPressed: handle.open,
          builder: (context, state) => fact,
        ),
        popoverBuilder: (context, handle) =>
            FloatingPanel(child: _Breakdown(counts)),
      );
    }
    final facts = [
      if (details.rank != null)
        _Fact(icon: AppIcons.rank, label: 'Rank', value: '#${details.rank}'),
      if (details.popularity != null)
        _Fact(
          icon: AppIcons.heart,
          label: 'Popularity',
          value: '#${details.popularity}',
        ),
      ?completed,
      if (episodes != null && episodes > 0)
        _Fact(
          icon: AppIcons.play,
          label: 'Episodes',
          value: '$episodes',
          live: true,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _rowWidth) {
          return Wrap(
            spacing: Tokens.space5 + Tokens.space2,
            runSpacing: Tokens.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [_Score(score), ...facts],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Score(score),
            for (final fact in facts)
              Container(
                margin: const EdgeInsets.only(left: Tokens.space4),
                padding: const EdgeInsets.only(left: Tokens.space4),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Tokens.line)),
                ),
                child: fact,
              ),
          ],
        );
      },
    );
  }
}

class _Score extends StatelessWidget {
  const _Score(this.score);

  final double? score;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScoreStar(
              size: Tokens.text5,
              color: score == null ? Tokens.inkMuted : Tokens.amber,
            ),
            const SizedBox(width: Tokens.space2),
            Text(
              score == null ? 'Not scored yet' : score!.toStringAsFixed(2),
              style: score == null
                  ? AppText.caption(Tokens.inkSoft)
                  : AppText.tally(
                      Tokens.ink,
                      size: Tokens.text5,
                    ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: Tokens.space1),
        Text('MAL score', style: AppText.caption(Tokens.inkSoft)),
      ],
    );
  }
}

/// One fact: its icon, then the value over its label. [live] is mint, the
/// colour for live things and counts.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.live = false,
  });

  final IconDef icon;
  final String label;
  final String value;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          icon,
          size: Tokens.iconSize,
          color: live ? Tokens.mint : Tokens.inkMuted,
        ),
        const SizedBox(width: Tokens.space3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppText.tally(
                live ? Tokens.mint : Tokens.ink,
                size: Tokens.text2,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Tokens.space1),
            Text(label, style: AppText.caption(Tokens.inkSoft)),
          ],
        ),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown(this.lines);

  final List<(String, String)> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tokens.space3),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (label, value) in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Tokens.space1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: AppText.caption(Tokens.inkSoft),
                      ),
                    ),
                    const SizedBox(width: Tokens.space5),
                    Text(
                      value,
                      style: AppText.tally(Tokens.ink, size: Tokens.text1),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
