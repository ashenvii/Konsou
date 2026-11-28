import 'package:flutter/widgets.dart';

import '../../components/cover_image.dart';
import '../../components/fading_portal.dart';
import '../../components/page_dim.dart';
import '../../components/peek_row.dart';
import '../../components/pressable.dart';
import '../../design/tokens.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';
import '../../library/count_format.dart';
import 'detail_section.dart';
import 'picture_viewer.dart';
import 'title_picture.dart';

/// MAL's extra pictures of the title in a peeking row. A click opens one full
/// size, with arrows and the arrow keys to move through the rest.
class PicturesPart extends StatefulWidget {
  const PicturesPart({super.key, required this.malId, required this.pictures});

  final int malId;
  final List<String> pictures;

  @override
  State<PicturesPart> createState() => _PicturesPartState();
}

class _PicturesPartState extends State<PicturesPart>
    with FadingPortalOwner<PicturesPart> {
  var _open = 0;

  @override
  Widget build(BuildContext context) {
    final pictures = widget.pictures;
    return FadingPortal(
      controller: portal,
      visible: portalOpen,
      overlay: (context) => PictureViewer(
        malId: widget.malId,
        pictures: pictures,
        start: _open,
        onClose: closePortal,
      ),
      child: DetailSection(
        title: 'Pictures',
        count: formatCountOf(pictures.length, 'picture'),
        child: PeekRow(
          count: pictures.length,
          minItemWidth: Tokens.gridCardMinWidth,
          arrowTop: (width) =>
              (CoverImage.heightFor(width) - Tokens.controlHeight) / 2,
          itemBuilder: (context, i, width) => Pressable(
            label: 'Open picture ${i + 1} full size',
            onPressed: () => openPortal(() => _open = i),
            builder: (context, state) => Stack(
              children: [
                TitlePicture(
                  malId: widget.malId,
                  url: pictures[i],
                  width: width,
                ),
                if (state.hovered || state.focused)
                  Positioned(
                    top: Tokens.space2,
                    right: Tokens.space2,
                    child: Container(
                      padding: const EdgeInsets.all(Tokens.space1),
                      color: PageDim.color,
                      child: const AppIcon(
                        AppIcons.expand,
                        size: Tokens.iconSize,
                        color: Tokens.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
