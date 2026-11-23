import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/cover_image.dart';
import '../../components/fading_portal.dart';
import '../../components/page_frame.dart';
import '../../components/picture_overlay.dart';
import '../../components/pressable.dart';
import '../../design/tokens.dart';
import '../../detail/title_details.dart';
import '../../mal/request_gate.dart';
import 'hero_ground.dart';

/// The top of the Detail page: the cover as a poster in a well at the left,
/// and beside it the [header], then the [meta] line, the [scores] and the
/// user's [controls], each a step down from the title. Behind it all, a
/// picture of the title under a veil. A click on the poster opens the cover
/// full size. The back button floats above.
class DetailTop extends StatelessWidget {
  const DetailTop({
    super.key,
    required this.malId,
    required this.header,
    this.details,
    this.meta,
    this.scores,
    this.controls,
    this.hidden = false,
    this.loading = false,
  });

  final int? malId;
  final Widget header;

  /// The title's details, for the picture behind; null while they load.
  final TitleDetails? details;
  final Widget? meta;
  final Widget? scores;
  final Widget? controls;

  /// Streamer mode on an adult title: no pictures.
  final bool hidden;

  /// The title's details are not in yet, so the cover may still be found.
  final bool loading;

  /// Where the title's first line starts, from the top of the page: below the
  /// back button floating over it, with room to breathe.
  static const titleTop =
      Tokens.controlHeight + 2 * PageFrame.edge + Tokens.space5;

  // the gaps between the parts, from the one scale
  static const _metaGap = Tokens.space4;
  static const _scoresGap = Tokens.space5 + Tokens.space4;
  static const _controlsGap = Tokens.space5;
  static const _posterGap = Tokens.space5 + Tokens.space4;

  @override
  Widget build(BuildContext context) {
    final malId = this.malId;
    final pictures = !hidden && malId != null;
    final text = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Tokens.detailTextWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          if (meta != null) ...[const SizedBox(height: _metaGap), meta!],
          if (scores != null) ...[const SizedBox(height: _scoresGap), scores!],
          if (controls != null) ...[
            const SizedBox(height: _controlsGap),
            controls!,
          ],
        ],
      ),
    );
    return Stack(
      children: [
        if (pictures)
          Positioned.fill(
            child: HeroGround(malId: malId, details: details),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PageFrame.edge,
            titleTop,
            PageFrame.edge,
            Tokens.space5 + Tokens.space4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pictures) ...[
                _Poster(malId: malId, loading: loading),
                const SizedBox(width: _posterGap),
              ],
              Flexible(child: text),
            ],
          ),
        ),
      ],
    );
  }
}

/// The cover in a sunk well, lifted off the picture behind by a shadow. A
/// click opens it full size in a [CoverViewer].
class _Poster extends StatefulWidget {
  const _Poster({required this.malId, required this.loading});

  final int malId;
  final bool loading;

  @override
  State<_Poster> createState() => _PosterState();
}

class _PosterState extends State<_Poster> with FadingPortalOwner<_Poster> {
  static const _coverWidth = Tokens.detailPosterWidth - 2 * Tokens.wellPad;

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
        builder: (context, state) => Container(
          padding: const EdgeInsets.all(Tokens.wellPad),
          decoration: const BoxDecoration(
            color: Tokens.wellFill,
            borderRadius: Tokens.wellCorners,
            boxShadow: [
              BoxShadow(
                color: Tokens.shadow,
                blurRadius: Tokens.shadowBlur,
                offset: Offset(0, Tokens.shadowDrop),
              ),
              BoxShadow(color: Tokens.edgeLight, offset: Offset(0, 1)),
            ],
          ),
          child: ClipRRect(
            borderRadius: Tokens.coverCorners,
            child: CoverView(
              lane: Lane.page,
              malId: widget.malId,
              width: _coverWidth,
              loading: widget.loading,
            ),
          ),
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
          lane: Lane.page,
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
