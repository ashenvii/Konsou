import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'app_menu.dart';
import 'cap_centered_text.dart';
import 'menu_switcher.dart';

/// A page heading with its count that opens a menu to switch the view.
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
    // the page's name carries the size; the menu word is one step lower
    final menu = base.copyWith(
      fontSize: Tokens.text2,
      letterSpacing: Tokens.text2 * Tokens.labelTracking,
    );
    return SizedBox(
      height: Tokens.controlHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // capitals centred like the menu word, so both share one line
          CapCenteredText(
            title,
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
            style: menu,
          ),
        ],
      ),
    );
  }
}
