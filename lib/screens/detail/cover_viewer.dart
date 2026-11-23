import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../app/providers.dart';
import '../../components/cover_image.dart';
import '../../components/picture_overlay.dart';

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
