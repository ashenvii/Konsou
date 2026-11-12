import 'package:flutter/widgets.dart';

import '../icons/app_icons.dart';
import 'icon_square_button.dart';

class MoreButton extends StatelessWidget {
  const MoreButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconSquareButton(
    icon: AppIcons.more,
    label: 'More',
    onPressed: onPressed,
  );
}
