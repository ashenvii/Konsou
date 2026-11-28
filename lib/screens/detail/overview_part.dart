import 'package:flutter/widgets.dart';

import '../../components/measure_text.dart';
import '../../components/pressable.dart';
import '../../components/skeleton_lines.dart';
import '../../design/text_styles.dart';
import '../../components/fact_row.dart';
import '../../components/hairline.dart';
import '../../design/tokens.dart';
import '../../detail/info_labels.dart';
import '../../detail/title_details.dart';
import 'detail_block.dart';
import 'detail_heading.dart';
import 'detail_section.dart';
import 'readable_width.dart';

/// What MAL says about the title: the synopsis and the background in a
/// column of readable width, and beside it when the window is wide a box of
/// facts in named groups with the title's other names. The synopsis shows
/// whole while it ends beside the facts; past them, it is cut with More.
class OverviewPart extends StatefulWidget {
  const OverviewPart({
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

  static const _factsWidth = Tokens.space5 * 14;

  // The text may shrink to this before the facts drop below it.
  static const _minTextWidth = Tokens.space5 * 15;

  static const _gap = Tokens.space5 + Tokens.space4;

  @override
  State<OverviewPart> createState() => _OverviewPartState();
}

class _OverviewPartState extends State<OverviewPart> {
  final _factsKey = GlobalKey();

  // the facts box's height once laid out; null until then, and when the
  // window is narrow and it sits under the text instead
  double? _factsHeight;

  // the More line and the gap over it take room beside the facts too
  double _around(TextScaler scaler) =>
      scaler.scale(Tokens.text2) + Tokens.space2;

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = _factsKey.currentContext?.size?.height;
      if (height != _factsHeight) setState(() => _factsHeight = height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final synopsis = details.synopsis;
    final background = details.background;
    final scaler = MediaQuery.textScalerOf(context);
    final lineHeight = scaler.scale(Tokens.text2) * Tokens.lineHeightWrapped;
    final factsHeight = _factsHeight;
    // as many lines as end beside the facts, never under four
    final lines = factsHeight == null
        ? _Clamped.fewest
        : ((factsHeight - _around(scaler)) / lineHeight).floor().clamp(
            _Clamped.fewest,
            1 << 20,
          );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.hidden)
          Text(
            'Synopsis hidden in Streamer mode',
            style: AppText.paragraph(Tokens.inkMuted),
          )
        else if (synopsis != null)
          _Clamped(synopsis, lines: lines)
        else if (widget.fetching)
          const SkeletonLines(title: 1, line: 0.7),
        if (background != null) ...[
          const SizedBox(height: Tokens.space5 + Tokens.space2),
          DetailBlock(
            title: 'Background',
            last: true,
            child: Text(background, style: AppText.paragraph(Tokens.inkMuted)),
          ),
        ],
      ],
    );
    final facts = KeyedSubtree(key: _factsKey, child: _Facts(details));
    return DetailSection(
      title: 'Overview',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >=
              OverviewPart._minTextWidth +
                  OverviewPart._gap +
                  OverviewPart._factsWidth;
          if (wide) {
            _measure();
          } else if (_factsHeight != null) {
            // under the text the box is no measure for it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _factsHeight = null);
            });
          }
          if (!wide) {
            return ReadableWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  text,
                  const SizedBox(height: Tokens.space5),
                  facts,
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ReadableWidth(child: text)),
              const SizedBox(width: OverviewPart._gap),
              SizedBox(width: OverviewPart._factsWidth, child: facts),
            ],
          );
        },
      ),
    );
  }
}

/// The title's facts in a quiet box, as a wiki's infobox groups them: when
/// it airs, where it comes from, and what else it is called.
class _Facts extends StatelessWidget {
  const _Facts(this.details);

  final TitleDetails details;

  @override
  Widget build(BuildContext context) {
    final names = details.otherNames;
    final groups = <(String, Widget)>[
      for (final (name, rows) in groupInfoRows(details))
        (
          name,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (label, value) in rows) FactRow(label, value: value),
            ],
          ),
        ),
      if (names.isNotEmpty)
        (
          'Also known as',
          Text(names.join('\n'), style: AppText.paragraph(Tokens.inkSoft)),
        ),
    ];
    if (groups.isEmpty) return const SizedBox.shrink();
    return ColoredBox(
      color: Tokens.raised,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.space5,
          vertical: Tokens.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (name, child)) in groups.indexed) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Tokens.space4),
                  child: Hairline(color: Tokens.surface),
                ),
              DetailHeading(name),
              const SizedBox(height: Tokens.space2),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// Running text cut to [lines], with More to open the rest and Less to cut
/// it again. Text that fits shows whole, with neither.
class _Clamped extends StatefulWidget {
  const _Clamped(this.text, {required this.lines});

  final String text;
  final int lines;

  static const fewest = 4;

  @override
  State<_Clamped> createState() => _ClampedState();
}

class _ClampedState extends State<_Clamped> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final style = AppText.paragraph(Tokens.inkSoft);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cut = measureText(
          widget.text,
          style,
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: widget.lines,
          maxWidth: constraints.maxWidth,
        ).cut;
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
                    state.hovered || state.focused ? Tokens.ink : Tokens.pop,
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
