import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../components/link_row.dart';
import '../../components/one_line_text.dart';
import '../../components/tag.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import '../../library/count_format.dart';
import 'detail_section.dart';
import 'readable_width.dart';

/// The manga the title comes from or leads to, each with how it relates and
/// opening its MAL page in the browser.
class MangaPart extends ConsumerWidget {
  const MangaPart({super.key, required this.titles});

  final List<LinkedTitle> titles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailSection(
      title: 'Manga',
      count: formatCountOf(titles.length, 'title'),
      child: ReadableWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final title in titles)
              _MangaRow(
                title: title,
                onPressed: () => ref.read(openLinkProvider)(
                  Uri.https('myanimelist.net', '/manga/${title.malId}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MangaRow extends StatelessWidget {
  const _MangaRow({required this.title, required this.onPressed});

  final LinkedTitle title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final note = title.note;
    return LinkRow(
      label: 'Open ${title.name} on MyAnimeList',
      onPressed: onPressed,
      children: (lit) => [
        const AppIcon(
          AppIcons.library,
          size: Tokens.iconSize,
          color: Tokens.inkMuted,
        ),
        const SizedBox(width: Tokens.space3),
        Expanded(
          child: OneLineText(title.name, style: AppText.label(Tokens.ink)),
        ),
        if (note != null) ...[const SizedBox(width: Tokens.space3), Tag(note)],
        const SizedBox(width: Tokens.space3),
        AppIcon(
          AppIcons.external,
          size: Tokens.iconSize,
          color: lit ? Tokens.pop : Tokens.inkMuted,
        ),
      ],
    );
  }
}
