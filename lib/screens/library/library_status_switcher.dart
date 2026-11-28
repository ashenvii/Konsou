import 'package:flutter/widgets.dart';

import '../../components/app_menu.dart';
import '../../components/heading_switcher.dart';
import '../../components/menu_switcher.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../library/count_format.dart';
import '../../library/library_view.dart';

/// A tab's name.
String libraryTabLabel(LibraryTab tab) => switch (tab) {
  LibraryTab.all => 'All',
  LibraryTab.watching => 'Watching',
  LibraryTab.planned => 'Planned',
  LibraryTab.completed => 'Completed',
  LibraryTab.onHold => 'On hold',
  LibraryTab.dropped => 'Dropped',
  LibraryTab.notInterested => 'Not interested',
};

/// The heading that switches the status tab, with counts.
class LibraryStatusSwitcher extends StatelessWidget {
  const LibraryStatusSwitcher({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelect,
    this.compact = false,
  });

  /// The folded top's short title: the status and its count, no "Library",
  /// at label size. Opens the same menu.
  final bool compact;

  final LibraryTab selected;
  final Map<LibraryTab, int>? counts;
  final ValueChanged<LibraryTab> onSelect;

  @override
  Widget build(BuildContext context) {
    String? countOf(LibraryTab tab) {
      final count = counts?[tab];
      return count == null ? null : formatCount(count);
    }

    final entries = [
      for (final tab in LibraryTab.values)
        MenuEntry(
          label: libraryTabLabel(tab),
          selected: tab == selected,
          count: countOf(tab) ?? '0',
          // a hairline after All and before On hold
          dividerAbove: tab == LibraryTab.watching || tab == LibraryTab.onHold,
          onPressed: () => onSelect(tab),
        ),
    ];
    const footnote = 'Alt + 1 to 7 switches without opening';
    if (compact) {
      return MenuSwitcher(
        current: libraryTabLabel(selected),
        count: countOf(selected),
        entries: entries,
        footnote: footnote,
        style: AppText.label(Tokens.ink, bold: true),
      );
    }
    return HeadingSwitcher(
      title: 'Library',
      current: libraryTabLabel(selected),
      count: countOf(selected),
      footnote: footnote,
      entries: entries,
    );
  }
}
