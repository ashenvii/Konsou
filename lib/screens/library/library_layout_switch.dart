import 'package:flutter/widgets.dart';

import '../../components/icon_square_button.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';
import '../../library/library_view.dart';

/// The grid and list switch.
class LibraryLayoutSwitch extends StatelessWidget {
  const LibraryLayoutSwitch({
    super.key,
    required this.layout,
    required this.onLayout,
  });

  final LibraryLayout layout;
  final ValueChanged<LibraryLayout> onLayout;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconSquareButton(
          icon: AppIcons.grid,
          label: 'Grid view',
          selected: layout == LibraryLayout.grid,
          onPressed: () => onLayout(LibraryLayout.grid),
        ),
        const SizedBox(width: Tokens.space1),
        IconSquareButton(
          icon: AppIcons.list,
          label: 'List view',
          selected: layout == LibraryLayout.list,
          onPressed: () => onLayout(LibraryLayout.list),
        ),
      ],
    );
  }
}
