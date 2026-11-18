import 'package:flutter/widgets.dart';

import '../../components/one_line_text.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';

/// Beside the cover: the title in the Library's language and the other main
/// title. The rest of its names are in the info column.
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.name, this.otherName});

  final String name;
  final String? otherName;

  /// One line of the title, so the back bar knows when the title has
  /// scrolled under it.
  static const titleLine = Tokens.text3 * Tokens.lineHeightWrapped;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.heading.copyWith(height: Tokens.lineHeightWrapped),
        ),
        if (otherName != null) ...[
          const SizedBox(height: Tokens.space1),
          OneLineText(otherName!, style: AppText.label(Tokens.inkSoft)),
        ],
      ],
    );
  }
}
