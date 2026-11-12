import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/icon_def.dart';

/// One icon centred in a control-sized square. The shared body of the icon
/// buttons; the button around it brings the press, the fill and the label.
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
