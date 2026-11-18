import 'package:flutter/widgets.dart';

import '../../components/pressable.dart';
import '../../components/skeleton.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import 'detail_block.dart';
import 'overview_info.dart';

/// What MAL says about the title: the synopsis, four lines and then More,
/// and the background in a column of readable width, with the information
/// and the title's other names beside it when the window is wide.
class OverviewSection extends StatelessWidget {
  const OverviewSection({
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

  // The text may shrink to this before the info column drops below it. The
  // smallest window leaves 880 for the page, so on desktop it always fits.
  static const _minTextWidth = Tokens.space5 * 15;

  static const _synopsisLines = 4;

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
          DetailBlock(
            title: 'Synopsis',
            child: _Clamped(synopsis, lines: _synopsisLines),
          )
        else if (fetching)
          const DetailBlock(
            title: 'Synopsis',
            child: SkeletonLines(title: 1, line: 0.7),
          ),
        if (background != null)
          DetailBlock(
            title: 'Background',
            child: Text(background, style: AppText.paragraph(Tokens.ink)),
          ),
      ],
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailBlock(title: 'Information', child: OverviewInfo(details)),
        if (names.isNotEmpty)
          DetailBlock(
            title: 'Other names',
            child: Text(
              names.join('\n'),
              style: AppText.paragraph(Tokens.inkSoft),
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= _minTextWidth + Tokens.space5 + _infoWidth;
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
            // the text keeps its readable width; the info column stays
            // against the right edge
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Tokens.detailTextWidth,
                  ),
                  child: text,
                ),
              ),
            ),
            const SizedBox(width: Tokens.space5),
            SizedBox(width: _infoWidth, child: info),
          ],
        );
      },
    );
  }
}

/// Running text cut to [lines], with More to open the rest and Less to cut it
/// again. Text that fits shows whole, with neither.
class _Clamped extends StatefulWidget {
  const _Clamped(this.text, {required this.lines});

  final String text;
  final int lines;

  @override
  State<_Clamped> createState() => _ClampedState();
}

class _ClampedState extends State<_Clamped> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final style = AppText.paragraph(Tokens.ink);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.lines,
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final cut = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: cut && !_open ? widget.lines : null,
              overflow: cut && !_open ? TextOverflow.ellipsis : null,
            ),
            if (cut) ...[
              const SizedBox(height: Tokens.space2),
              Pressable(
                label: _open ? 'Show less' : 'Show the whole synopsis',
                onPressed: () => setState(() => _open = !_open),
                builder: (context, state) => Text(
                  _open ? 'Less' : 'More',
                  style: AppText.label(
                    state.hovered || state.focused ? Tokens.ink : Tokens.amber,
                    bold: true,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
