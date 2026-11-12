import 'package:flutter/widgets.dart';

import '../icons/app_icons.dart';
import 'quiet_icon_button.dart';

/// The three dots at the end of a row. It only draws and reports a press; the
/// screen puts a popover around it.
class MoreButton extends StatelessWidget {
  const MoreButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      QuietIconButton(icon: AppIcons.more, label: 'More', onPressed: onPressed);
}
