import 'package:flutter/widgets.dart';

import '../../components/app_tab.dart';
import '../../components/hairline.dart';
import '../../components/page_frame.dart';
import '../../design/tokens.dart';

/// The Detail page's tabs, in a row of their own under the hero with a line
/// above, at the page's edge.
class DetailTabBar extends StatelessWidget {
  const DetailTabBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Hairline(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PageFrame.edge,
            vertical: Tokens.space2,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, label) in labels.indexed)
                  AppTab(
                    label: label,
                    selected: i == selected,
                    onPressed: () => onSelect(i),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
