import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../app/hero_view.dart';
import '../../components/cover_image.dart';
import '../../components/page_frame.dart';
import '../../design/tokens.dart';

/// The top of the Detail page: a wide picture darkened toward the ground, with
/// the bordered cover standing low on it at the left. [header] sits beside the
/// cover, ending at the band's lower edge; below that edge come the [facts].
class DetailHero extends StatelessWidget {
  const DetailHero({
    super.key,
    required this.malId,
    required this.header,
    this.facts,
    this.hidden = false,
    this.loading = false,
  });

  final int? malId;
  final Widget header;
  final Widget? facts;

  /// Streamer mode on an adult title: the band and the cover stay blank.
  final bool hidden;

  /// The title's details are not in yet, so there is no picture to look for.
  final bool loading;

  static double get coverHeight =>
      CoverImage.heightFor(Tokens.detailCoverWidth);

  // the cover stands low: only this much of it is on the band
  static const _coverOnBand = Tokens.space4 * 6;

  static double get _coverTop => Tokens.heroHeight - _coverOnBand;

  // the header ends this far above the band's lower edge
  static const _headerGap = Tokens.space4;

  // a title of one line, the other name and one line of synonyms
  static const _headerHeight =
      Tokens.text3 * Tokens.lineHeightWrapped +
      Tokens.space1 +
      Tokens.text2 +
      Tokens.space2 +
      Tokens.text1;

  static double get height =>
      _coverTop + coverHeight + 2 * Tokens.detailCoverBorder;

  /// Where the title's first line starts, measured from the top of the hero.
  /// The header sits on the band's lower edge, so a longer title starts higher.
  static double get titleTop => Tokens.heroHeight - _headerGap - _headerHeight;

  /// Where that line ends, measured from the top of the hero.
  static double get titleBottom =>
      titleTop + Tokens.text3 * Tokens.lineHeightWrapped;

  @override
  Widget build(BuildContext context) {
    const bordered = Tokens.detailCoverWidth + 2 * Tokens.detailCoverBorder;
    const beside = PageFrame.edge + bordered + Tokens.space4;
    final blank = hidden || loading || malId == null;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: Tokens.heroHeight,
            child: LayoutBuilder(
              builder: (context, constraints) => ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // stops short of the bottom edge: where the picture and
                    // the clip both land between pixels, a lighter line of
                    // it showed through while scrolling
                    const Positioned.fill(
                      bottom: 2,
                      child: ColoredBox(color: Tokens.surface),
                    ),
                    if (!blank)
                      HeroView(malId: malId!, width: constraints.maxWidth),
                    // a light veil over the blur, the frost
                    ColoredBox(color: Tokens.ink.withValues(alpha: 0.04)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Tokens.ground.withValues(alpha: 0.2),
                            Tokens.ground.withValues(alpha: 0.45),
                            Tokens.ground,
                          ],
                          stops: const [0, 0.55, 1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: PageFrame.edge,
            top: _coverTop,
            child: Container(
              padding: const EdgeInsets.all(Tokens.detailCoverBorder),
              color: Tokens.ground,
              child: blank
                  ? CoverImage(
                      width: Tokens.detailCoverWidth,
                      loading: loading && !hidden,
                    )
                  : CoverView(malId: malId, width: Tokens.detailCoverWidth),
            ),
          ),
          Positioned(
            left: beside,
            right: PageFrame.edge,
            bottom: height - Tokens.heroHeight + _headerGap,
            child: header,
          ),
          // below the band's edge
          if (facts != null)
            Positioned(
              left: beside,
              right: PageFrame.edge,
              top: Tokens.heroHeight + Tokens.space4,
              child: facts!,
            ),
        ],
      ),
    );
  }
}
