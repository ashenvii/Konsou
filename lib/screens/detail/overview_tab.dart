import 'package:flutter/widgets.dart';

import '../../components/skeleton.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import 'detail_block.dart';
import 'overview_info.dart';

/// The Overview tab: synopsis, background and other names in a column of
/// readable width, with the info block beside it when the window is wide.
class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.details,
    required this.hidden,
    required this.fetching,
  });

  final TitleDetails details;

  /// Streamer mode on an adult title: the synopsis is not shown.
  final bool hidden;

  /// The full details are on their way, so a missing part may still come.
  final bool fetching;

  static const _infoWidth = Tokens.space5 * 14;

  // The text may shrink to this before the info block drops below it. The
  // smallest window leaves 864 for the page, so on desktop it always fits.
  static const _minTextWidth = Tokens.space5 * 15;

  @override
  Widget build(BuildContext context) {
    final names = [?details.otherName, ...details.otherNames];
    final synopsis = details.synopsis;
    final background = details.background;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hidden)
          DetailBlock(
            title: 'Synopsis',
            child: Text(
              'Hidden in Streamer mode',
              style: AppText.paragraph(Tokens.inkMuted),
            ),
          )
        else if (synopsis != null)
          DetailBlock(title: 'Synopsis', child: _Prose(synopsis))
        else if (fetching)
          const DetailBlock(
            title: 'Synopsis',
            child: SkeletonLines(title: 1, line: 0.7),
          ),
        if (background != null)
          DetailBlock(title: 'Background', child: _Prose(background)),
        if (names.isNotEmpty)
          DetailBlock(title: 'Other names', child: _Prose(names.join('\n'))),
      ],
    );
    final info = DetailBlock(
      title: 'Information',
      child: OverviewInfo(details),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >=
                _minTextWidth + Tokens.space5 + _infoWidth;
            if (!wide) {
              return Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Tokens.detailTextWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [text, info],
                  ),
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // the text takes whatever is left between the rail and the
                // info block, which stays against the right edge
                Expanded(child: text),
                const SizedBox(width: Tokens.space5),
                SizedBox(width: _infoWidth, child: info),
              ],
            );
          },
        ),
        Text('Data from MyAnimeList', style: AppText.caption(Tokens.inkMuted)),
      ],
    );
  }
}

class _Prose extends StatelessWidget {
  const _Prose(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.paragraph(Tokens.ink));
}
