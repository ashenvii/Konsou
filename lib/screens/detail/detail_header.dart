import 'package:flutter/widgets.dart';

import '../../components/one_line_text.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';

/// The title, the one big bright line of the page, in the Library's
/// language, and the other main title under it in soft ink. The rest of its
/// names are in the info column.
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.name, this.otherName});

  final String name;
  final String? otherName;

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
          style: AppText.label(
            Tokens.ink,
            bold: true,
            size: Tokens.text5,
          ).wrapped,
        ),
        if (otherName != null) ...[
          const SizedBox(height: Tokens.space1),
          OneLineText(otherName!, style: AppText.label(Tokens.inkSoft)),
        ],
      ],
    );
  }
}
