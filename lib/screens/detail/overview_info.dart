import 'package:flutter/widgets.dart';

import '../../components/panel.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/info_labels.dart';
import '../../detail/title_details.dart';

/// The Overview's facts about the title, one label and value per row.
class OverviewInfo extends StatelessWidget {
  const OverviewInfo(this.details, {super.key});

  final TitleDetails details;

  static const _labelWidth = Tokens.space5 * 5;

  @override
  Widget build(BuildContext context) {
    final rows = infoRows(details);
    if (rows.isEmpty) return const SizedBox.shrink();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Tokens.space1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _labelWidth,
                    child: Text(
                      label,
                      style: AppText.paragraph(Tokens.inkSoft),
                    ),
                  ),
                  Expanded(
                    child: Text(value, style: AppText.paragraph(Tokens.ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
