import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';

/// The small chevron after the label of a button or tab that opens a menu.
class MenuChevron extends StatelessWidget {
  const MenuChevron({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Tokens.space2),
      child: AppIcon(AppIcons.chevronDown, size: Tokens.iconSize, color: color),
    );
  }
}
