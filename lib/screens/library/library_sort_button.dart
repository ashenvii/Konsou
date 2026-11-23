import 'package:flutter/widgets.dart';

import '../../components/app_menu.dart';
import '../../components/menu_switcher.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../library/library_view.dart';

String _sortLabel(LibrarySort sort) => switch (sort) {
  LibrarySort.recent => 'Recent',
  LibrarySort.title => 'A to Z',
};

class LibrarySortButton extends StatelessWidget {
  const LibrarySortButton({
    super.key,
    required this.sort,
    required this.onSort,
  });

  final LibrarySort sort;
  final ValueChanged<LibrarySort> onSort;

  @override
  Widget build(BuildContext context) {
    return MenuSwitcher(
      current: _sortLabel(sort),
      style: AppText.label(Tokens.ink),
      raised: true,
      entries: [
        for (final choice in LibrarySort.values)
          MenuEntry(
            label: _sortLabel(choice),
            selected: choice == sort,
            onPressed: () => onSort(choice),
          ),
      ],
    );
  }
}
