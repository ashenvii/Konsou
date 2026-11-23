import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../app/providers.dart';
import '../../components/cover_image.dart';
import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../components/peek_row.dart';
import '../../components/pressable.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import '../../library/count_format.dart';
import 'detail_section.dart';
import 'section_note.dart';

/// What MAL's users recommend after this title, as covers in a peeking row
/// with how many recommend each. A click opens that title's page.
class RecommendationsPart extends StatelessWidget {
  const RecommendationsPart({
    super.key,
    required this.titles,
    required this.onOpen,
  });

  final List<LinkedTitle> titles;
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
        arrowTop: (width) =>
            (CoverImage.heightFor(width) - Tokens.controlHeight) / 2,
        itemBuilder: (context, i, width) {
          final title = titles[i];
          final note = title.note;
          return Pressable(
            label: 'Open ${title.name}',
            onPressed: () => onOpen(title.malId),
            builder: (context, state) => HoverMark(
              on: state.hovered || state.focused,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoverView(
                    lane: Lane.page,
                    malId: title.malId,
                    width: width,
                    pictureUrl: title.pictureUrl,
                  ),
                  const SizedBox(height: Tokens.space2),
                  Text(
                    title.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      Tokens.ink,
                      bold: true,
                    ).copyWith(height: Tokens.lineHeightWrapped),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: Tokens.space1),
                    OneLineText(note, style: AppText.caption(Tokens.inkMuted)),
                  ],
                  const SizedBox(height: Tokens.space2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
