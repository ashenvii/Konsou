import 'package:flutter/widgets.dart';

import '../../components/cover_image.dart';
import '../../components/page_frame.dart';
import '../../components/skeleton.dart';
import '../../design/tokens.dart';
import '../../library/library_view.dart';
import 'grid_layout.dart';

class LibrarySkeleton extends StatelessWidget {
  const LibrarySkeleton({super.key, required this.layout});

  final LibraryLayout layout;

  @override
  Widget build(BuildContext context) {
    return layout == LibraryLayout.grid
        ? const _GridSkeleton()
        : const _ListSkeleton();
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.share, required this.height});

  final double share;
  final double height;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: share,
    alignment: Alignment.centerLeft,
    child: Skeleton(height: height),
  );
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = GridLayout.forWidth(
          constraints.maxWidth - PageFrame.content.horizontal,
        );
        return GridView.builder(
          padding: PageFrame.content,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: layout.delegate,
          itemCount: layout.columns * 3,
          itemBuilder: (context, index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(
                width: layout.cardWidth,
                height: CoverImage.heightFor(layout.cardWidth),
              ),
              const SizedBox(height: Tokens.space2),
              const _Line(share: 0.8, height: Tokens.text3),
              const SizedBox(height: Tokens.space1),
              const _Line(share: 0.45, height: Tokens.text2),
            ],
          ),
        );
      },
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: PageFrame.content,
      physics: const NeverScrollableScrollPhysics(),
      itemExtent: Tokens.listRowHeight,
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
        child: Row(
          children: [
            const Skeleton(
              width: Tokens.checkboxSize,
              height: Tokens.checkboxSize,
            ),
            const SizedBox(width: Tokens.space3),
            Skeleton(
              width: Tokens.listCoverWidth,
              height: CoverImage.heightFor(Tokens.listCoverWidth),
            ),
            const SizedBox(width: Tokens.space3),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(share: 0.5, height: Tokens.text3),
                  SizedBox(height: Tokens.space2),
                  _Line(share: 0.25, height: Tokens.text2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
