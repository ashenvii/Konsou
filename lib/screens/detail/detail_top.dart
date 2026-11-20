import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/cover_image.dart';
import '../../components/fading_portal.dart';
import '../../components/page_frame.dart';
import '../../components/picture_overlay.dart';
import '../../components/pressable.dart';
import '../../design/tokens.dart';

/// The top of the Detail page, cinematic: the cover as key art across the
/// right, fading left and down into the page, and in front of it on plain
/// ground the [header], then the [meta] line, the [scores] and the user's
/// [controls], each a step down from the title. A click on the art opens the
/// cover full size. The back button floats above.
class DetailTop extends StatelessWidget {
  const DetailTop({
    super.key,
    required this.malId,
    required this.header,
    this.meta,
    this.scores,
    this.controls,
    this.hidden = false,
    this.loading = false,
  });

  final int? malId;
  final Widget header;
  final Widget? meta;
  final Widget? scores;
  final Widget? controls;

  /// Streamer mode on an adult title: no art.
  final bool hidden;

  /// The title's details are not in yet, so there is no cover to look for.
  final bool loading;

  /// Where the title's first line starts, from the top of the page: below the
  /// back button floating over it, with room for the art to breathe.
  static const titleTop =
      Tokens.controlHeight + 2 * PageFrame.edge + Tokens.space5;

  // the art takes at most this share of the width, and never more than
  // Tokens.keyArtMaxWidth: MAL's covers are small and turn soft past it
  static const _artShare = 0.6;

  // the gaps between the parts, from the one scale
  static const _metaGap = Tokens.space4;
  static const _scoresGap = Tokens.space5 + Tokens.space4;
  static const _controlsGap = Tokens.space5;

  @override
  Widget build(BuildContext context) {
    final malId = this.malId;
    final art = !(hidden || loading || malId == null);
    return LayoutBuilder(
      builder: (context, constraints) {
        final artWidth = math.min(
          constraints.maxWidth * _artShare,
          Tokens.keyArtMaxWidth,
        );
        return Stack(
          children: [
            if (art)
              Positioned(
                top: 0,
                right: 0,
                // the art and its fade stop short of the foot, so the edge
                // is ground against ground while the page scrolls
                bottom: Tokens.space3,
                width: artWidth,
                child: _KeyArt(malId: malId, width: artWidth),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PageFrame.edge,
                titleTop,
                PageFrame.edge,
                Tokens.space5 + Tokens.space4,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Tokens.detailTextWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      if (meta != null) ...[
                        const SizedBox(height: _metaGap),
                        meta!,
                      ],
                      if (scores != null) ...[
                        const SizedBox(height: _scoresGap),
                        scores!,
                      ],
                      if (controls != null) ...[
                        const SizedBox(height: _controlsGap),
                        controls!,
                      ],
                    ],
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

/// The cover drawn as key art: as wide as [width], its upper part showing,
/// fading into the ground at its left and its foot. A click opens it full
/// size in a [CoverViewer].
class _KeyArt extends StatefulWidget {
  const _KeyArt({required this.malId, required this.width});

  final int malId;
  final double width;

  @override
  State<_KeyArt> createState() => _KeyArtState();
}

class _KeyArtState extends State<_KeyArt> with FadingPortalOwner<_KeyArt> {
  @override
  Widget build(BuildContext context) {
    return FadingPortal(
      controller: portal,
      visible: portalOpen,
      overlay: (context) =>
          CoverViewer(malId: widget.malId, onClose: closePortal),
      child: Pressable(
        label: 'Open the cover full size',
        onPressed: openPortal,
        builder: (context, state) => Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: OverflowBox(
                alignment: const Alignment(0, -0.4),
                maxHeight: double.infinity,
                child: CoverView(malId: widget.malId, width: widget.width),
              ),
            ),
            // into the ground on the left, where the text reads
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Tokens.ground,
                    Tokens.ground.withValues(alpha: 0.7),
                    Tokens.ground.withValues(alpha: 0.15),
                    Tokens.ground.withValues(alpha: 0.35),
                  ],
                  stops: const [0, 0.3, 0.75, 1],
                ),
              ),
            ),
            // and into the ground at the foot
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Tokens.ground.withValues(alpha: 0), Tokens.ground],
                  stops: const [0.55, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A cover full size over the dimmed page, as large as the page allows. A
/// click anywhere or Escape closes it.
class CoverViewer extends StatelessWidget {
  const CoverViewer({super.key, required this.malId, required this.onClose});

  final int malId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PictureOverlay(
      onClose: onClose,
      builder: (context, room) => Center(
        child: CoverView(
          malId: malId,
          width: math.min(
            room.maxWidth,
            room.maxHeight / CoverImage.heightFor(1),
          ),
        ),
      ),
    );
  }
}
