import 'package:flutter/widgets.dart';

import '../../components/app_menu.dart';
import '../../components/heading_switcher.dart';
import '../../library/count_format.dart';
import '../../library/library_view.dart';

String _tabLabel(LibraryTab tab) => switch (tab) {
  LibraryTab.all => 'All',
  LibraryTab.watching => 'Watching',
  LibraryTab.planned => 'Planned',
  LibraryTab.completed => 'Completed',
  LibraryTab.onHold => 'On hold',
  LibraryTab.dropped => 'Dropped',
  LibraryTab.notInterested => 'Not interested',
};

class LibraryStatusSwitcher extends StatelessWidget {
  const LibraryStatusSwitcher({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  final LibraryTab selected;
  final Map<LibraryTab, int>? counts;
  final ValueChanged<LibraryTab> onSelect;

  @override
  Widget build(BuildContext context) {
    String? countOf(LibraryTab tab) {
      final count = counts?[tab];
      return count == null ? null : formatCount(count);
    }

    return HeadingSwitcher(
      title: 'Library',
      current: _tabLabel(selected),
      count: countOf(selected),
      footnote: 'Alt + 1 to 7 switches without opening',
      entries: [
        for (final tab in LibraryTab.values)
          MenuEntry(
            label: _tabLabel(tab),
            selected: tab == selected,
            count: countOf(tab) ?? '0',
            // a hairline after All and before On hold
            dividerAbove:
                tab == LibraryTab.watching || tab == LibraryTab.onHold,
            onPressed: () => onSelect(tab),
          ),
      ],
    );
  }
}
