import 'package:flutter/widgets.dart';

import '../../components/app_popover.dart';
import '../../components/floating_panel.dart';
import '../../components/one_line_text.dart';
import '../../components/pressable.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';

/// Beside the cover: the title in the Library's language, the other main
/// title and the synonyms on one line with "+N more".
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.name,
    this.otherName,
    this.synonyms = const [],
  });

  final String name;
  final String? otherName;
  final List<String> synonyms;

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
        if (synonyms.isNotEmpty) ...[
          const SizedBox(height: Tokens.space2),
          _Synonyms(synonyms),
        ],
      ],
    );
  }
}

class _Synonyms extends StatelessWidget {
  const _Synonyms(this.synonyms);

  final List<String> synonyms;

  static const _separator = ' · ';

  @override
  Widget build(BuildContext context) {
    final style = AppText.caption(Tokens.inkMuted);
    final moreStyle = style.copyWith(fontWeight: FontWeight.w700);
    return LayoutBuilder(
      builder: (context, constraints) {
        final shown = _fit(synonyms, style, moreStyle, constraints.maxWidth);
        final hidden = synonyms.length - shown;
        return Row(
          children: [
            Flexible(
              child: OneLineText(
                synonyms.take(shown).join(_separator),
                style: style,
              ),
            ),
            if (hidden > 0) ...[
              const SizedBox(width: Tokens.space2),
              AppPopover(
                gap: Tokens.space1,
                builder: (context, handle) => Pressable(
                  onPressed: handle.open,
                  label: 'Show all other names',
                  builder: (context, state) => Text(
                    '+$hidden more',
                    style: moreStyle.copyWith(
                      color: state.hovered || state.focused
                          ? Tokens.ink
                          : Tokens.amber,
                    ),
                  ),
                ),
                popoverBuilder: (context, handle) => FloatingPanel(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Tokens.space5 * 15,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Tokens.space3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final name in synonyms)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: Tokens.space1,
                              ),
                              child: Text(
                                name,
                                style: AppText.paragraph(Tokens.inkSoft),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static double _widthOf(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  // how many names fit on the line, leaving room for "+N more" unless all fit
  static int _fit(
    List<String> names,
    TextStyle style,
    TextStyle moreStyle,
    double width,
  ) {
    if (_widthOf(names.join(_separator), style) <= width) return names.length;
    final room =
        width - _widthOf('+${names.length} more', moreStyle) - Tokens.space2;
    var count = 1;
    while (count < names.length - 1 &&
        _widthOf(names.take(count + 1).join(_separator), style) <= room) {
      count++;
    }
    return count;
  }
}
