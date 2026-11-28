import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../components/page_frame.dart';
import '../../components/smooth_scroll.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../library/letters.dart';
import '../../library/library_row.dart';
import '../../library/library_view.dart';
import 'grid_layout.dart';

const _stripGutter = LetteredRows.stripGutter;

/// Library rows under letter headings, with the A to Z strip and its jumps.
class LetteredRows extends ConsumerStatefulWidget {
  const LetteredRows({
    super.key,
    required this.rows,
    required this.layout,
    required this.itemBuilder,
    this.topInset = 0,
    this.pinned = 0,
  });

  /// Room the letter strip takes at the right of the rows.
  static const stripGutter = Tokens.space5 + Tokens.space2;

  final List<LibraryRow> rows;
  final LibraryLayout layout;
  final Widget Function(BuildContext context, LibraryRow row) itemBuilder;

  /// Room above the first heading for the page's top, which folds to
  /// [pinned] high as the rows scroll under it.
  final double topInset;
  final double pinned;

  @override
  ConsumerState<LetteredRows> createState() => _LetteredRowsState();
}

class _LetteredRowsState extends ConsumerState<LetteredRows> {
  final _controller = SmoothScrollController();

  var _offsets = <String, double>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jump(String letter) {
    if (_offsets.isEmpty || !_controller.hasClients) return;
    final from = letterHeadings.indexOf(letter);
    final target = letterHeadings
        .skip(from < 0 ? 0 : from)
        .firstWhere(_offsets.containsKey, orElse: () => _offsets.keys.last);
    // the letter lands just under the folded top
    _controller.jumpTo(
      min(
        _offsets[target]! + widget.topInset - widget.pinned,
        _controller.position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(libraryLetterJumpProvider, (_, request) {
      if (request != null) _jump(request.letter);
    });
    final groups = groupByLetter(widget.rows);
    final grid = widget.layout == LibraryLayout.grid;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = GridLayout.forWidth(
          constraints.maxWidth - PageFrame.content.horizontal - _stripGutter,
          textScaler: MediaQuery.textScalerOf(context),
        );
        // each group is its heading, its rows, then a gap
        double extent(int count) {
          final lines = grid ? (count / layout.columns).ceil() : count;
          final lineHeight = grid ? layout.cardHeight : Tokens.listRowHeight;
          final between = grid ? GridLayout.rowGap * (lines - 1) : 0;
          return Tokens.controlHeight +
              lines * lineHeight +
              between +
              GridLayout.rowGap;
        }

        var at = 0.0;
        _offsets = {};
        for (final group in groups) {
          _offsets[group.letter] = at;
          at += extent(group.rows.length);
        }
        return Stack(
          children: [
            CustomScrollView(
              controller: _controller,
              // rows a screen either side are built, so they load ahead
              scrollCacheExtent: const ScrollCacheExtent.viewport(1),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: widget.topInset)),
                for (final group in groups)
                  SliverPadding(
                    // room on the right for the letter strip
                    padding: EdgeInsets.only(
                      left: PageFrame.content.left,
                      right: PageFrame.content.right + _stripGutter,
                    ),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(child: _Heading(group.letter)),
                        if (grid)
                          SliverGrid.builder(
                            gridDelegate: layout.delegate,
                            itemCount: group.rows.length,
                            itemBuilder: (context, index) =>
                                widget.itemBuilder(context, group.rows[index]),
                          )
                        else
                          SliverFixedExtentList.builder(
                            itemExtent: Tokens.listRowHeight,
                            itemCount: group.rows.length,
                            itemBuilder: (context, index) =>
                                widget.itemBuilder(context, group.rows[index]),
                          ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: GridLayout.rowGap),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Positioned(
              top: widget.topInset,
              bottom: Tokens.space2,
              // left of the scrollbar, which sits against the window edge
              right: Tokens.scrollbarWidth + Tokens.space1,
              child: Align(
                alignment: Alignment.centerRight,
                // a short window shrinks the strip instead of overflowing
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _Strip(
                    present: {for (final group in groups) group.letter},
                    onLetter: _jump,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Tokens.controlHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          letter,
          semanticsLabel: formatLetterLabel(letter),
          style: AppText.heading,
        ),
      ),
    );
  }
}

class _Strip extends StatefulWidget {
  const _Strip({required this.present, required this.onLetter});

  final Set<String> present;
  final ValueChanged<String> onLetter;

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  ({String letter, double centre})? _probe;

  void _point(PointerEvent event, {required bool scroll}) {
    final height = (context.findRenderObject()! as RenderBox).size.height;
    final slot = height / letterHeadings.length;
    final index = (event.localPosition.dy / slot).floor().clamp(
      0,
      letterHeadings.length - 1,
    );
    final letter = letterHeadings[index];
    setState(() => _probe = (letter: letter, centre: (index + 0.5) * slot));
    if (scroll) widget.onLetter(letter);
  }

  @override
  Widget build(BuildContext context) {
    final probe = _probe;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _point(event, scroll: true),
      onPointerMove: (event) => _point(event, scroll: true),
      onPointerHover: (event) => _point(event, scroll: false),
      onPointerUp: (_) => setState(() => _probe = null),
      onPointerCancel: (_) => setState(() => _probe = null),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onExit: (_) => setState(() => _probe = null),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final letter in letterHeadings)
                  Semantics(
                    button: true,
                    label: formatLetterLabel(letter),
                    excludeSemantics: true,
                    onTap: widget.present.contains(letter)
                        ? () => widget.onLetter(letter)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Tokens.space2,
                        vertical: Tokens.space1,
                      ),
                      child: Text(
                        letter,
                        style: AppText.caption(
                          probe?.letter == letter
                              ? Tokens.pop
                              : (widget.present.contains(letter)
                                    ? Tokens.inkSoft
                                    : Tokens.inkMuted),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (probe != null)
              Positioned(
                left: 0,
                top: probe.centre,
                child: FractionalTranslation(
                  // fully to the left of the strip, centred on the pointer
                  translation: const Offset(-1, -0.5),
                  child: _Bubble(probe.letter),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Tokens.space2),
      child: ColoredBox(
        color: Tokens.pop,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.space4,
            vertical: Tokens.space2,
          ),
          child: Text(
            letter,
            style: AppText.heading.copyWith(color: Tokens.onPop),
          ),
        ),
      ),
    );
  }
}
