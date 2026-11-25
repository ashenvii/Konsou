import 'package:flutter/widgets.dart';

import '../../app/detail_providers.dart';
import '../../components/app_button.dart';
import '../../components/fact_row.dart';
import '../../components/one_line_text.dart';
import '../../components/skeleton.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/info_labels.dart';
import '../../detail/title_details.dart';
import '../../library/entry_status.dart';

/// What a grid card's popover holds, only what the card does not show: the
/// full name, other names, the synopsis in three lines, Aired, Length and
/// Genres, and the status key. Names, Aired and Length come with the short
/// fetch; the synopsis and genres wait for the full one, as skeletons while
/// it runs and as one muted line when it cannot.
class CardDetails extends StatelessWidget {
  const CardDetails({
    super.key,
    required this.name,
    required this.details,
    required this.fetch,
    required this.status,
    required this.onStatusMenu,
  });

  /// The card's name, until the details give theirs.
  final String name;
  final TitleDetails? details;
  final DetailFetch fetch;
  final EntryStatus status;

  /// Opens the status menu at this point on the screen.
  final ValueChanged<Offset> onStatusMenu;

  static const offlineNote = "Synopsis comes when you're online.";

  @override
  Widget build(BuildContext context) {
    final details = this.details;
    final full = details?.isFull ?? false;
    final waiting = !full && fetch == DetailFetch.running;
    final cannot = !full && !waiting;
    final otherNames = details?.otherNames ?? const [];
    final aired = details == null ? null : formatAired(details);
    final length = details == null ? null : formatDuration(details);
    final genres = details?.genres ?? const [];
    final synopsis = details?.synopsis;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(switch (details?.name) {
          final name? when name.isNotEmpty => name,
          _ => name,
        }, style: AppText.heading.copyWith(height: Tokens.lineHeightWrapped)),
        if (otherNames.isNotEmpty) ...[
          const SizedBox(height: Tokens.space1),
          OneLineText(
            otherNames.join(' · '),
            style: AppText.caption(Tokens.inkMuted),
          ),
        ],
        const SizedBox(height: Tokens.space4),
        if (waiting)
          const _SkeletonLines()
        else if (cannot)
          Text(offlineNote, style: AppText.paragraph(Tokens.inkMuted))
        else if (synopsis != null && synopsis.isNotEmpty)
          Text(
            synopsis,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppText.paragraph(Tokens.inkSoft),
          ),
        const SizedBox(height: Tokens.space3),
        if (aired != null) FactRow('Aired', value: aired),
        if (length != null) FactRow('Length', value: length),
        if (waiting)
          const FactRow(
            'Genres',
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.6,
              child: Skeleton(height: Tokens.text2),
            ),
          )
        else if (genres.isNotEmpty)
          FactRow('Genres', value: genres.join(', ')),
        const SizedBox(height: Tokens.space4),
        Builder(
          builder: (context) => AppButton(
            label: status.label,
            kind: ButtonKind.secondary,
            opensMenu: true,
            onPressed: () {
              final box = context.findRenderObject()! as RenderBox;
              onStatusMenu(box.localToGlobal(Offset(0, box.size.height)));
            },
          ),
        ),
      ],
    );
  }
}

/// Three lines of synopsis while the full fetch runs.
class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Skeleton(height: Tokens.text2),
      SizedBox(height: Tokens.space2),
      Skeleton(height: Tokens.text2),
      SizedBox(height: Tokens.space2),
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.6,
        child: Skeleton(height: Tokens.text2),
      ),
    ],
  );
}
