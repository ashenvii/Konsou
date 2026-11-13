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
              const SkeletonLines(title: 0.8, line: 0.45, gap: Tokens.space1),
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
            const Expanded(child: SkeletonLines(title: 0.5, line: 0.25)),
          ],
        ),
      ),
    );
  }
}
