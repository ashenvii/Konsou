import 'package:flutter/widgets.dart';

import '../../app/detail_providers.dart';
import '../../components/fact_row.dart';
import '../../components/held_lines.dart';
import '../../components/mal_score_line.dart';
import '../../components/skeleton_lines.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/info_labels.dart';
import '../../detail/title_details.dart';
import '../../library/row_labels.dart';

/// The details at the top of a title's quick panel, one height for every
/// title: the name (room for two lines), other names (one), the synopsis
/// (three), then one line each of MAL's score, Aired, Length, Genres and your
/// progress. Names, Aired, Length and the score come with the short fetch;
/// the synopsis and genres wait for the full one, as skeletons while it runs
/// and as one muted line when it cannot. A title with no MAL page says so in
/// the score's place and the synopsis's.
class CardDetails extends StatelessWidget {
  const CardDetails({
    super.key,
    required this.name,
    required this.details,
    required this.fetch,
    required this.malScore,
    required this.progress,
    this.scorePending = false,
    this.notLinked = false,
    this.trailingRoom = 0,
  });

  /// The card's name, until the details give theirs.
  final String name;
  final TitleDetails? details;
  final DetailFetch fetch;
  final double? malScore;

  /// Your progress in words (`formatPanelProgress`).
  final String progress;

  /// Details saved, but MAL's score not asked for yet: a skeleton, not "?".
  final bool scorePending;

  /// No MAL page found for the title yet.
  final bool notLinked;

  /// Room kept at the right of the name and other names, for a key in the
  /// panel's corner.
  final double trailingRoom;

  static const offlineNote = "Synopsis comes when you're online.";
  static const notLinkedNote = 'Not linked to a MyAnimeList page yet';

  /// Narrower than Detail's, so a fact's value fits one line in the panel.
  static const labelWidth = Tokens.space5 * 3;

  @override
  Widget build(BuildContext context) {
    final details = this.details;
    final full = details?.isFull ?? false;
    final waiting = !notLinked && !full && fetch == DetailFetch.running;
    final cannot = !notLinked && !full && !waiting;
    final otherNames = details?.otherNames ?? const <String>[];
    // the days do not fit the panel's one line
    final aired = details == null ? null : formatAired(details, days: false);
    final length = details == null ? null : formatDuration(details);
    final genres = details?.genres ?? const <String>[];
    final synopsis = details?.synopsis;
    final paragraph = AppText.paragraph(Tokens.inkSoft);
    final shownName = switch (details?.name) {
      final name? when name.isNotEmpty => name,
      _ => name,
    };
    Widget fact(String label, {String value = '', Widget? child}) => FactRow(
      label,
      value: value,
      oneLine: true,
      labelWidth: labelWidth,
      child: child,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: trailingRoom),
          child: HeldLines(shownName, lines: 2, style: AppText.heading.wrapped),
        ),
        const SizedBox(height: Tokens.space1),
        Padding(
          padding: EdgeInsets.only(right: trailingRoom),
          child: HeldLines(
            joinParts(otherNames),
            lines: 1,
            // a line of 1 cut the tops of the letters off
            style: AppText.caption(Tokens.inkMuted).wrapped,
          ),
        ),
        const SizedBox(height: Tokens.space4),
        HeldLines(
          switch ((notLinked, cannot)) {
            (true, _) => notLinkedNote,
            (_, true) => offlineNote,
            _ => synopsis ?? '',
          },
          lines: 3,
          style: notLinked || cannot
              ? AppText.paragraph(Tokens.inkMuted)
              : paragraph,
          loading: waiting,
        ),
        const SizedBox(height: Tokens.space3),
        fact(
          'MAL',
          child: notLinked
              ? Text(
                  'Not linked',
                  maxLines: 1,
                  style: AppText.paragraph(Tokens.inkMuted),
                )
              : scorePending
              ? const SkeletonLine()
              : MalScoreLine(score: malScore, size: Tokens.text2),
        ),
        fact('Aired', value: aired ?? ''),
        fact('Length', value: length ?? ''),
        if (waiting)
          fact('Genres', child: const SkeletonLine())
        else
          fact('Genres', value: genres.join(', ')),
        fact('Progress', value: progress),
      ],
    );
  }
}
