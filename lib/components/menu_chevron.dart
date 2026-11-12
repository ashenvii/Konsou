import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'motion.dart';

/// The chevron after the label of something that opens a menu. It turns up
/// while the menu is [open].
class MenuChevron extends StatelessWidget {
  const MenuChevron({super.key, required this.color, this.open = false});

  final Color color;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Tokens.space2),
      child: AnimatedRotation(
        turns: open ? 0.5 : 0,
        duration: chooseMotionDuration(context, Tokens.motionQuick),
        curve: Curves.easeInOut,
        child: AppIcon(
          AppIcons.chevronDown,
          size: Tokens.iconSize,
          color: color,
        ),
      ),
    );
  }
}
