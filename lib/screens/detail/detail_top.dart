import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/close_on_escape.dart';
import '../../components/cover_image.dart';
import '../../components/fading_portal.dart';
import '../../components/page_frame.dart';
import '../../components/pressable.dart';
import '../../design/tokens.dart';
import 'back_bar.dart';

/// The top of the Detail page on the plain ground: the cover at the left,
/// sharp, and beside it the [header], the user's [controls], the [facts] and
/// what to watch [next], top to bottom. Clicking the cover opens it full size.
/// The back button floats in the space above.
class DetailTop extends StatelessWidget {
  const DetailTop({
    super.key,
    required this.malId,
    required this.header,
    this.controls,
    this.facts,
    this.next,
    this.hidden = false,
    this.loading = false,
  });

  final int? malId;
  final Widget header;
  final Widget? controls;
  final Widget? facts;
  final Widget? next;

  /// Streamer mode on an adult title: the cover stays blank.
  final bool hidden;

  /// The title's details are not in yet, so there is no cover to look for.
  final bool loading;

  /// Where the title's first line starts, from the top of the page: below the
  /// back button's row.
  static const titleTop = BackBar.height;

  @override
  Widget build(BuildContext context) {
    final malId = this.malId;
    final blank = hidden || loading || malId == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PageFrame.edge,
        titleTop,
        PageFrame.edge,
        Tokens.space5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          blank
              ? CoverImage(
                  width: Tokens.detailCoverWidth,
                  loading: loading && !hidden,
                )
              : _OpenableCover(malId: malId),
          const SizedBox(width: Tokens.space5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                for (final part in [?controls, ?facts, ?next]) ...[
                  const SizedBox(height: Tokens.space4),
                  part,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The cover, which opens full size in a [CoverViewer] on a click.
class _OpenableCover extends StatefulWidget {
  const _OpenableCover({required this.malId});

  final int malId;

  @override
  State<_OpenableCover> createState() => _OpenableCoverState();
}

class _OpenableCoverState extends State<_OpenableCover>
    with FadingPortalOwner<_OpenableCover> {
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
        builder: (context, state) =>
            CoverView(malId: widget.malId, width: Tokens.detailCoverWidth),
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
    return CloseOnEscape(
      onClose: onClose,
      child: Focus(
        autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          onSecondaryTap: onClose,
          child: ColoredBox(
            color: Tokens.ground.withValues(alpha: 0.72),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final room = constraints.deflate(
                  const EdgeInsets.all(Tokens.space5),
                );
                final width = math.min(
                  room.maxWidth,
                  room.maxHeight / CoverImage.heightFor(1),
                );
                return Center(
                  child: CoverView(malId: malId, width: width),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
