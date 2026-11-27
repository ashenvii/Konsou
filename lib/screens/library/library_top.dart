import 'package:flutter/widgets.dart';

import '../../components/page_frame.dart';
import '../../design/tokens.dart';

/// The Library's top: the heading row, and in list view the header bar under
/// it. In grid view it never folds: the rows scroll up under it. In list view
/// it folds with them: the heading slides away and fades, the top takes the
/// chassis fill, and the title in short ([title], "All 3357") fades in at the
/// left of the header bar. [fold] is 0 at the top of the page and 1 once
/// folded.
class LibraryTop extends StatelessWidget {
  const LibraryTop({
    super.key,
    required this.fold,
    required this.heading,
    required this.title,
    this.captions,
    this.covering = false,
  });

  final double fold;

  /// Rows lie under it (the page is scrolled), so its fill is solid even
  /// while it is open, as when Find unfolds it mid-page.
  final bool covering;
  final Widget heading;
  final Widget title;

  /// List view's header bar, given what goes in its lead.
  final Widget Function(Widget lead)? captions;

  static const headingHeight =
      Tokens.space2 + Tokens.controlHeight + Tokens.space4;

  /// How tall it is at the top of the page.
  static double restHeight({required bool list}) =>
      headingHeight + (list ? Tokens.controlHeight : 0);

  /// How tall it stays once folded.
  static double pinnedHeight({required bool list}) =>
      list ? Tokens.controlHeight : headingHeight;

  @override
  Widget build(BuildContext context) {
    final captions = this.captions;
    final list = captions != null;
    final rest = restHeight(list: list);
    final travel = rest - pinnedHeight(list: list);
    final folded = fold > 0.5;
    // the folded parts are only built once folding starts, so at the top of
    // the page there is one sort key and one status switcher
    final shortTitle = fold == 0
        ? const SizedBox.shrink()
        : IgnorePointer(
            ignoring: !folded,
            child: Opacity(opacity: fold, child: title),
          );
    return SizedBox(
      height: rest - travel * fold,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Tokens.chassisTop.withValues(
                    alpha: covering ? 1 : fold,
                  ),
                  border: list
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Tokens.line.withValues(
                              alpha: covering ? 1 : 0,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // the heading leaves with the rows
            Positioned(
              top: -travel * fold,
              left: 0,
              right: 0,
              height: headingHeight,
              child: IgnorePointer(
                ignoring: folded,
                child: Opacity(opacity: 1 - fold, child: heading),
              ),
            ),
            if (list)
              Positioned(
                left: PageFrame.content.left,
                right: PageFrame.content.right,
                bottom: 0,
                height: Tokens.controlHeight,
                child: captions(shortTitle),
              ),
          ],
        ),
      ),
    );
  }
}
