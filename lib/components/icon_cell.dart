import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/icon_def.dart';

class IconCell extends StatelessWidget {
  const IconCell({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
  });

  final IconDef icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: Tokens.controlHeight,
    child: Center(
      child: AppIcon(icon, size: size, color: color),
    ),
  );
}
