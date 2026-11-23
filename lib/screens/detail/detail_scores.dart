import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import 'score_figure.dart';

/// The page's second voice after the title: the MAL score and [mine], the
/// user's own, large, then a quiet line of facts, rank, popularity, the share
/// who finish it and the episodes, the episode count in pop. Wraps on a
/// narrow window. With none of these it draws nothing.
class DetailScores extends StatelessWidget {
  const DetailScores({super.key, required this.details, this.mine});

  final TitleDetails details;
  final Widget? mine;

  static bool hasAny(TitleDetails details) =>
      details.score != null ||
      details.rank != null ||
      details.popularity != null ||
      (details.episodes ?? 0) > 0 ||
      details.completedShare != null;

  @override
  Widget build(BuildContext context) {
    if (!hasAny(details) && mine == null) return const SizedBox.shrink();
    final share = details.completedShare;
    final episodes = details.episodes;
    final facts = [
      if (details.rank != null) _Fact('#${details.rank}', 'rank'),
      if (details.popularity != null)
        _Fact('#${details.popularity}', 'popular'),
      if (share != null && share > 0)
        _Fact('${(share * 100).round()}%', 'finish it'),
      if (episodes != null && episodes > 0)
        _Fact('$episodes', 'episodes', lit: true),
    ];
    return Wrap(
      spacing: Tokens.space5 + Tokens.space4,
      runSpacing: Tokens.space4,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        ScoreFigure(
          value: details.score?.toStringAsFixed(2),
          empty: 'Not scored yet',
          label: 'MAL score',
          starColor: Tokens.star,
        ),
        ?mine,
        if (facts.isNotEmpty)
          Wrap(
            spacing: Tokens.space5,
            runSpacing: Tokens.space2,
            children: facts,
          ),
      ],
    );
  }
}

/// A fact in the quiet line: its number a step brighter than its word.
class _Fact extends StatelessWidget {
  const _Fact(this.value, this.label, {this.lit = false});

  final String value;
  final String label;

  /// The one fact that stands out, the episode count.
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: AppText.label(lit ? Tokens.pop : Tokens.inkSoft, bold: true),
          ),
          TextSpan(text: ' $label', style: AppText.caption(Tokens.inkMuted)),
        ],
      ),
    );
  }
}
