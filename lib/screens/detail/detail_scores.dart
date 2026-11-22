import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import '../../icons/score_star.dart';

/// The page's second voice after the title: the MAL score and [mine], the
/// user's own, large, then a quiet line of facts, rank, popularity, the share
/// who finish it and the episodes, the episode count in cyan. Wraps on a
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
        _Fact('$episodes', 'episodes', cyan: true),
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
  const _Fact(this.value, this.label, {this.cyan = false});

  final String value;
  final String label;

  /// The one fact that stands out, the episode count.
  final bool cyan;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: AppText.label(
              cyan ? Tokens.pop : Tokens.inkSoft,
              bold: true,
            ),
          ),
          TextSpan(text: ' $label', style: AppText.caption(Tokens.inkMuted)),
        ],
      ),
    );
  }
}

/// A score as the Detail page shows one: a star and the number large
/// and bright, over its [label] in muted ink. With no [value] the star is
/// grey and [empty] stands in; a score the user can set says so instead,
/// with a small star and a cyan [empty] such as "Rate", so it never weighs
/// as much as a real score. [lit] brightens it under the pointer.
class ScoreFigure extends StatelessWidget {
  const ScoreFigure({
    super.key,
    required this.value,
    required this.empty,
    required this.label,
    this.lit = false,
    this.settable = false,
    this.starColor = Tokens.pop,
  });

  final String? value;
  final String empty;
  final String label;
  final bool lit;
  final bool settable;

  /// The star's colour: the user's own score uses pop, MyAnimeList's the
  /// ordinary star gold.
  final Color starColor;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScoreStar(
              size: value == null && settable ? Tokens.text3 : Tokens.text4,
              color: value == null ? Tokens.inkMuted : starColor,
            ),
            const SizedBox(width: Tokens.space2),
            Text(
              value ?? empty,
              style: switch ((value, settable)) {
                (null, true) => AppText.label(
                  lit ? Tokens.ink : Tokens.pop,
                  bold: true,
                ),
                (null, false) => AppText.caption(Tokens.inkMuted),
                // the user's own score is lit, like an LED display
                _ when settable =>
                  AppText.tally(Tokens.pop, size: Tokens.text5).copyWith(
                    shadows: const [
                      Shadow(color: Tokens.pop, blurRadius: Tokens.ledGlow),
                    ],
                  ),
                _ => AppText.tally(Tokens.ink, size: Tokens.text5),
              },
            ),
          ],
        ),
        const SizedBox(height: Tokens.space2),
        Text(
          label,
          style: AppText.caption(lit ? Tokens.inkSoft : Tokens.inkMuted),
        ),
      ],
    );
  }
}
