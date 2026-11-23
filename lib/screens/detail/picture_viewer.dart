import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../components/cover_image.dart';
import '../../components/picture_overlay.dart';
import '../../components/solid_icon_button.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';
import 'title_picture.dart';

/// The title's pictures full size, one at a time, from [start]: arrows at
/// the sides and the arrow keys move through them, the count shows above.
class PictureViewer extends StatefulWidget {
  const PictureViewer({
    super.key,
    required this.malId,
    required this.pictures,
    required this.start,
    required this.onClose,
  });

  final int malId;
  final List<String> pictures;
  final int start;
  final VoidCallback onClose;

  @override
  State<PictureViewer> createState() => _PictureViewerState();
}

class _PictureViewerState extends State<PictureViewer> {
  late var _index = widget.start;

  int get _count => widget.pictures.length;

  void _step(int by) => setState(() => _index = (_index + by) % _count);

  KeyEventResult _key(KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _step(_count - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final many = _count > 1;
    return PictureOverlay(
      onClose: widget.onClose,
      onKey: _key,
      builder: (context, room) {
        const side = Tokens.controlHeight + Tokens.space4;
        const top = Tokens.text1 + Tokens.space4;
        final width = math.min(
          room.maxWidth - (many ? 2 * side : 0),
          (room.maxHeight - top) / CoverImage.heightFor(1),
        );
        return Stack(
          children: [
            Positioned.fill(
              top: top,
              child: Center(
                child: TitlePicture(
                  key: ValueKey(_index),
                  malId: widget.malId,
                  url: widget.pictures[_index],
                  width: width,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text(
                '${_index + 1} / $_count',
                textAlign: TextAlign.center,
                style: AppText.tally(Tokens.inkSoft, size: Tokens.text1),
              ),
            ),
            if (many) ...[
              Positioned(
                left: 0,
                top: top,
                bottom: 0,
                child: Center(
                  child: SolidIconButton(
                    icon: AppIcons.chevronLeft,
                    label: 'Earlier picture',
                    onPressed: () => _step(_count - 1),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: top,
                bottom: 0,
                child: Center(
                  child: SolidIconButton(
                    icon: AppIcons.chevronRight,
                    label: 'Later picture',
                    onPressed: () => _step(1),
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
