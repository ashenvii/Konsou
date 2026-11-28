import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/info_labels.dart';
import '../../detail/title_details.dart';
import '../../library/row_labels.dart';

/// What kind of title it is, under its names: one muted line of type,
/// season and studios, the type and studios a step brighter, then the genres
/// smaller still, parted by slashes.
class DetailMeta extends StatelessWidget {
  const DetailMeta(this.details, {super.key});

  final TitleDetails details;

  static bool hasAny(TitleDetails details) =>
      details.mediaType != null ||
      formatSeason(details) != null ||
      details.studios.isNotEmpty ||
      details.genres.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final type = details.mediaType;
    final season = formatSeason(details);
    final soft = AppText.label(Tokens.inkSoft);
    final muted = AppText.label(Tokens.inkMuted);
    final parts = <TextSpan>[
      if (type != null && type.isNotEmpty)
        TextSpan(text: formatType(type), style: soft),
      if (season != null) TextSpan(text: season, style: muted),
      if (details.studios.isNotEmpty)
        TextSpan(text: details.studios.join(', '), style: soft),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.isNotEmpty)
          Text.rich(
            TextSpan(
              children: [
                for (final (i, part) in parts.indexed) ...[
                  if (i > 0) TextSpan(text: partsDot, style: muted),
                  part,
                ],
              ],
            ),
          ),
        if (details.genres.isNotEmpty) ...[
          const SizedBox(height: Tokens.space2),
          Text(
            details.genres.join('  /  '),
            style: AppText.caption(Tokens.inkMuted),
          ),
        ],
      ],
    );
  }
}
