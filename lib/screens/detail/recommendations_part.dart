import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/score_fill.dart';
import '../../app/providers.dart';
import '../../components/peek_row.dart';
import '../../components/pressable.dart';
import '../../design/tokens.dart';
import '../../detail/recommended_titles.dart';
import '../../library/count_format.dart';
import 'detail_section.dart';
import 'section_note.dart';
import 'strip_card.dart';

/// What MAL's users recommend after this title, as strip cards in a peeking
/// row. A title on the list says its state; the rest say how many recommend
/// them. A click opens that title's page.
class RecommendationsPart extends StatelessWidget {
  const RecommendationsPart({
    super.key,
    required this.titles,
    required this.onOpen,
  });

  final List<RecommendedTitle> titles;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Recommendations',
      count: formatCountOf(titles.length, 'title'),
      aside: const SectionNote('By MyAnimeList users'),
      child: PeekRow(
        count: titles.length,
        minItemWidth: Tokens.peekItemMinWidth,
        arrowTop: StripCard.arrowTop,
        itemBuilder: (context, i, width) => _Recommended(
          key: ValueKey(titles[i].title.malId),
          title: titles[i],
          width: width,
          onOpen: () => onOpen(titles[i].title.malId),
        ),
      ),
    );
  }
}

/// One recommendation, fetched while it shows when its details are not in.
class _Recommended extends ConsumerWidget {
  const _Recommended({
    super.key,
    required this.title,
    required this.width,
    required this.onOpen,
  });

  final RecommendedTitle title;
  final double width;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = title.title;
    if (shown.isLoadingDetails) {
      ref.watch(detailOnScreenProvider(shown.malId, lane: Lane.page));
    }
    return ScoreFill(
      malId: shown.malId,
      pending: shown.isScorePending,
      child: Pressable(
        label: 'Open ${shown.name}',
        onPressed: onOpen,
        builder: (context, state) => StripCard(
          title: shown,
          width: width,
          pictureUrl: title.pictureUrl,
          state: shown.status?.label ?? title.note ?? '',
          lit: state.hovered || state.focused,
        ),
      ),
    );
  }
}
