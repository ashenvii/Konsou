import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'app_menu.dart';
import 'menu_switcher.dart';

class HeadingSwitcher extends StatelessWidget {
  const HeadingSwitcher({
    super.key,
    required this.title,
    required this.current,
    required this.count,
    required this.entries,
    this.footnote,
  });

  final String title;
  final String current;
  final String? count;
  final List<MenuEntry> entries;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final base = AppText.heading.copyWith(
      fontFeatures: AppText.tally(Tokens.ink).fontFeatures,
    );
    return SizedBox(
      height: Tokens.controlHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            softWrap: false,
            style: base.copyWith(
              fontWeight: FontWeight.w400,
              color: Tokens.inkMuted,
            ),
          ),
          const SizedBox(width: Tokens.space2),
          MenuSwitcher(
            current: current,
            count: count,
            entries: entries,
            footnote: footnote,
            style: base,
          ),
        ],
      ),
    );
  }
}
